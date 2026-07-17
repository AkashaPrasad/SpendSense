import { Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { ExpenseCategory, TransactionType } from '../types/expense';
import { ChartSpec, QueryIntent, QueryResult } from '../types/query';
import { sumByBucket } from '../utils/dateBuckets';
import { formatCategory, formatDateRange, formatMoney } from '../utils/format';

function startOfDay(iso: string): Date {
  const d = new Date(iso);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 0, 0, 0));
}

function endOfDay(iso: string): Date {
  const d = new Date(iso);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 23, 59, 59, 999));
}

async function sumForRange(
  userId: string,
  opts: { start: Date; end: Date; type?: TransactionType; categories?: ExpenseCategory[] },
): Promise<number> {
  const where: Prisma.ExpenseWhereInput = {
    userId,
    date: { gte: opts.start, lte: opts.end },
    ...(opts.type ? { type: opts.type } : {}),
    ...(opts.categories?.length ? { category: { in: opts.categories } } : {}),
  };
  const agg = await prisma.expense.aggregate({ where, _sum: { amount: true } });
  return Number(agg._sum.amount ?? 0);
}

/**
 * Maps a validated, LLM-produced QueryIntent onto parametrized Prisma
 * queries and computes the answer deterministically in code — arithmetic is
 * never delegated back to the model, which keeps numbers correct and this
 * function fully unit-testable without any network call.
 */
export async function runQuery(userId: string, intent: QueryIntent): Promise<QueryResult> {
  const start = startOfDay(intent.startDate);
  const end = endOfDay(intent.endDate);
  const range = formatDateRange(start, end);
  const categories = (intent.categories ?? []) as ExpenseCategory[];

  switch (intent.intent) {
    case 'CATEGORY_TOTAL': {
      if (categories.length === 0) {
        return {
          answer: "I couldn't tell which category you meant — try naming one, like \"food\" or \"transport\".",
          chart: null,
          intent,
        };
      }
      const perCategory = await Promise.all(
        categories.map(async (category) => ({
          category,
          total: await sumForRange(userId, { start, end, categories: [category] }),
        })),
      );
      const grandTotal = perCategory.reduce((s, c) => s + c.total, 0);
      const names = categories.map(formatCategory).join(', ');
      const chart: ChartSpec = {
        type: perCategory.length > 1 ? 'bar' : 'pie',
        labels: perCategory.map((c) => formatCategory(c.category)),
        series: [{ label: 'Spent', values: perCategory.map((c) => c.total) }],
      };
      return {
        answer: `You spent ${formatMoney(grandTotal)} on ${names} between ${range}.`,
        chart,
        intent,
      };
    }

    case 'OVERALL_TOTAL': {
      const total = await sumForRange(userId, { start, end, type: 'EXPENSE' });
      return {
        answer: `You spent a total of ${formatMoney(total)} between ${range}.`,
        chart: { type: 'bar', labels: ['Total spend'], series: [{ label: 'Amount', values: [total] }] },
        intent,
      };
    }

    case 'TREND': {
      const granularity = intent.groupBy === 'day' || intent.groupBy === 'week' ? intent.groupBy : 'month';
      const rows = await prisma.expense.findMany({
        where: {
          userId,
          type: 'EXPENSE',
          date: { gte: start, lte: end },
          ...(categories.length ? { category: { in: categories } } : {}),
        },
        select: { date: true, amount: true },
        orderBy: { date: 'asc' },
      });
      const buckets = sumByBucket(
        rows.map((r) => ({ date: r.date, amount: Number(r.amount) })),
        granularity,
      );
      const total = buckets.reduce((s, b) => s + b.total, 0);
      return {
        answer:
          buckets.length === 0
            ? `No spending recorded between ${range}.`
            : `Your spending trend from ${range} totals ${formatMoney(total)} across ${buckets.length} ${granularity}${buckets.length === 1 ? '' : 's'}.`,
        chart: {
          type: 'line',
          labels: buckets.map((b) => b.label),
          series: [{ label: 'Spend', values: buckets.map((b) => b.total) }],
        },
        intent,
      };
    }

    case 'COMPARE_CATEGORIES': {
      let cats = categories;
      if (cats.length === 0) {
        const grouped = await prisma.expense.groupBy({
          by: ['category'],
          where: { userId, type: 'EXPENSE', date: { gte: start, lte: end } },
          _sum: { amount: true },
          orderBy: { _sum: { amount: 'desc' } },
          take: 5,
        });
        cats = grouped.map((g) => g.category);
      }
      const perCategory = await Promise.all(
        cats.map(async (category) => ({
          category,
          total: await sumForRange(userId, { start, end, categories: [category] }),
        })),
      );
      return {
        answer:
          perCategory.length === 0
            ? `No spending recorded between ${range}.`
            : `Here's how your spending breaks down across ${perCategory.map((c) => formatCategory(c.category)).join(', ')} for ${range}.`,
        chart: {
          type: 'bar',
          labels: perCategory.map((c) => formatCategory(c.category)),
          series: [{ label: 'Spent', values: perCategory.map((c) => c.total) }],
        },
        intent,
      };
    }

    case 'SPEND_VS_INCOME': {
      const expenseTotal = await sumForRange(userId, {
        start,
        end,
        type: 'EXPENSE',
        categories: categories.length ? categories : undefined,
      });
      const incomeTotal = await sumForRange(userId, { start, end, type: 'INCOME' });
      const label = categories.length ? categories.map(formatCategory).join(', ') : 'spending';
      const pctOfIncome = incomeTotal > 0 ? Math.round((expenseTotal / incomeTotal) * 100) : null;
      const comparison = pctOfIncome !== null ? ` That's ${pctOfIncome}% of your income.` : '';
      return {
        answer: `You spent ${formatMoney(expenseTotal)} on ${label} versus ${formatMoney(incomeTotal)} in income between ${range}.${comparison}`,
        chart: {
          type: 'bar',
          labels: [`${categories.length ? formatCategory(categories[0]) : 'Spending'}`, 'Income'],
          series: [{ label: 'Amount', values: [expenseTotal, incomeTotal] }],
        },
        intent,
      };
    }

    case 'BUDGET_VS_ACTUAL': {
      const month = start.getUTCMonth() + 1;
      const year = start.getUTCFullYear();
      const budgets = await prisma.budget.findMany({
        where: {
          userId,
          month,
          year,
          ...(categories.length ? { category: { in: categories } } : {}),
        },
      });
      if (budgets.length === 0) {
        return {
          answer: `You haven't set a budget for ${range} yet.`,
          chart: null,
          intent,
        };
      }
      const rows = await Promise.all(
        budgets.map(async (b) => ({
          category: b.category,
          budget: Number(b.monthlyLimit),
          actual: await sumForRange(userId, { start, end, type: 'EXPENSE', categories: [b.category] }),
        })),
      );
      const overBudget = rows.filter((r) => r.actual > r.budget);
      const summary =
        overBudget.length === 0
          ? `You're within budget across ${rows.length} categor${rows.length === 1 ? 'y' : 'ies'} for ${range}.`
          : `You're over budget on ${overBudget.map((r) => formatCategory(r.category)).join(', ')} for ${range}.`;
      return {
        answer: summary,
        chart: {
          type: 'bar',
          labels: rows.map((r) => formatCategory(r.category)),
          series: [
            { label: 'Budget', values: rows.map((r) => r.budget) },
            { label: 'Actual', values: rows.map((r) => r.actual) },
          ],
        },
        intent,
      };
    }

    default: {
      const _exhaustive: never = intent.intent;
      throw new Error(`Unhandled query intent: ${_exhaustive}`);
    }
  }
}
