import { Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { HttpError } from '../middleware/errorHandler';
import { CreateExpenseInput, ListExpensesQuery, UpdateExpenseInput } from '../types/expense';

function toWriteData(input: CreateExpenseInput) {
  return {
    type: input.type,
    merchant: input.merchant,
    amount: input.amount,
    currency: input.currency,
    category: input.category,
    date: new Date(input.date),
    notes: input.notes,
    source: input.source,
    receiptImageUrl: input.receiptImageUrl,
    lineItems: input.lineItems as Prisma.InputJsonValue | undefined,
  };
}

/**
 * Creates an expense. When a clientId is present (offline-created rows being
 * synced from the Drift cache), this upserts by clientId so re-sending the
 * same local row — after an edit, or a retried request — never creates a
 * duplicate.
 */
export async function createExpense(userId: string, input: CreateExpenseInput) {
  const data = toWriteData(input);

  if (input.clientId) {
    const existing = await prisma.expense.findUnique({ where: { clientId: input.clientId } });
    if (existing && existing.userId !== userId) {
      throw new HttpError(403, 'This record belongs to another user');
    }
    return prisma.expense.upsert({
      where: { clientId: input.clientId },
      create: { ...data, userId, clientId: input.clientId },
      update: data,
    });
  }

  return prisma.expense.create({ data: { ...data, userId } });
}

export async function listExpenses(userId: string, query: ListExpensesQuery) {
  const where: Prisma.ExpenseWhereInput = {
    userId,
    ...(query.category ? { category: query.category } : {}),
    ...(query.type ? { type: query.type } : {}),
    ...(query.from || query.to
      ? {
          date: {
            ...(query.from ? { gte: new Date(query.from) } : {}),
            ...(query.to ? { lte: new Date(query.to) } : {}),
          },
        }
      : {}),
    ...(query.updatedSince ? { updatedAt: { gt: new Date(query.updatedSince) } } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.expense.findMany({
      where,
      orderBy: { date: 'desc' },
      skip: (query.page - 1) * query.limit,
      take: query.limit,
    }),
    prisma.expense.count({ where }),
  ]);

  return { items, total, page: query.page, limit: query.limit };
}

export async function getExpenseById(userId: string, id: string) {
  const expense = await prisma.expense.findUnique({ where: { id } });
  if (!expense || expense.userId !== userId) {
    throw new HttpError(404, 'Expense not found');
  }
  return expense;
}

export async function updateExpense(userId: string, id: string, input: UpdateExpenseInput) {
  await getExpenseById(userId, id);
  return prisma.expense.update({
    where: { id },
    data: {
      ...(input.type !== undefined ? { type: input.type } : {}),
      ...(input.merchant !== undefined ? { merchant: input.merchant } : {}),
      ...(input.amount !== undefined ? { amount: input.amount } : {}),
      ...(input.currency !== undefined ? { currency: input.currency } : {}),
      ...(input.category !== undefined ? { category: input.category } : {}),
      ...(input.date !== undefined ? { date: new Date(input.date) } : {}),
      ...(input.notes !== undefined ? { notes: input.notes } : {}),
      ...(input.source !== undefined ? { source: input.source } : {}),
      ...(input.receiptImageUrl !== undefined ? { receiptImageUrl: input.receiptImageUrl } : {}),
      ...(input.lineItems !== undefined ? { lineItems: input.lineItems as Prisma.InputJsonValue } : {}),
    },
  });
}

export async function deleteExpense(userId: string, id: string) {
  await getExpenseById(userId, id);
  await prisma.expense.delete({ where: { id } });
}

export async function syncExpenses(userId: string, expenses: (CreateExpenseInput & { clientId: string })[]) {
  const results = [];
  for (const expense of expenses) {
    const saved = await createExpense(userId, expense);
    results.push({ clientId: expense.clientId, id: saved.id, updatedAt: saved.updatedAt });
  }
  return results;
}
