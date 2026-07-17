import { prisma } from '../lib/prisma';
import { sumByBucket } from '../utils/dateBuckets';

function monthRange(month: number, year: number) {
  const start = new Date(Date.UTC(year, month - 1, 1));
  const end = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));
  return { start, end };
}

/** Category breakdown for one month — powers the dashboard's category pie/bar chart. */
export async function categorySummary(userId: string, month: number, year: number) {
  const { start, end } = monthRange(month, year);
  const grouped = await prisma.expense.groupBy({
    by: ['category'],
    where: { userId, type: 'EXPENSE', date: { gte: start, lte: end } },
    _sum: { amount: true },
    orderBy: { _sum: { amount: 'desc' } },
  });
  return grouped.map((g) => ({ category: g.category, total: Number(g._sum.amount ?? 0) }));
}

/** Monthly total spend over the trailing N months — powers the dashboard trend line. */
export async function spendTrend(userId: string, months: number) {
  const now = new Date();
  const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - (months - 1), 1));
  const rows = await prisma.expense.findMany({
    where: { userId, type: 'EXPENSE', date: { gte: start } },
    select: { date: true, amount: true },
  });
  return sumByBucket(
    rows.map((r) => ({ date: r.date, amount: Number(r.amount) })),
    'month',
  );
}

/** Budget vs actual per category for one month. */
export async function budgetVsActual(userId: string, month: number, year: number) {
  const { start, end } = monthRange(month, year);
  const budgets = await prisma.budget.findMany({ where: { userId, month, year } });

  return Promise.all(
    budgets.map(async (b) => {
      const actual = await prisma.expense.aggregate({
        where: { userId, type: 'EXPENSE', category: b.category, date: { gte: start, lte: end } },
        _sum: { amount: true },
      });
      return {
        category: b.category,
        budget: Number(b.monthlyLimit),
        actual: Number(actual._sum.amount ?? 0),
      };
    }),
  );
}

/** Income vs expense totals for one month. */
export async function incomeVsExpense(userId: string, month: number, year: number) {
  const { start, end } = monthRange(month, year);
  const [expense, income] = await Promise.all([
    prisma.expense.aggregate({
      where: { userId, type: 'EXPENSE', date: { gte: start, lte: end } },
      _sum: { amount: true },
    }),
    prisma.expense.aggregate({
      where: { userId, type: 'INCOME', date: { gte: start, lte: end } },
      _sum: { amount: true },
    }),
  ]);
  return { expense: Number(expense._sum.amount ?? 0), income: Number(income._sum.amount ?? 0) };
}
