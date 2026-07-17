import { prisma } from '../lib/prisma';
import { HttpError } from '../middleware/errorHandler';
import { CreateBudgetInput } from '../types/budget';

export async function upsertBudget(userId: string, input: CreateBudgetInput) {
  return prisma.budget.upsert({
    where: {
      userId_category_month_year: {
        userId,
        category: input.category,
        month: input.month,
        year: input.year,
      },
    },
    create: {
      userId,
      category: input.category,
      monthlyLimit: input.monthlyLimit,
      month: input.month,
      year: input.year,
    },
    update: { monthlyLimit: input.monthlyLimit },
  });
}

export async function listBudgets(userId: string, month?: number, year?: number) {
  return prisma.budget.findMany({
    where: {
      userId,
      ...(month ? { month } : {}),
      ...(year ? { year } : {}),
    },
    orderBy: [{ year: 'desc' }, { month: 'desc' }],
  });
}

export async function deleteBudget(userId: string, id: string) {
  const budget = await prisma.budget.findUnique({ where: { id } });
  if (!budget || budget.userId !== userId) {
    throw new HttpError(404, 'Budget not found');
  }
  await prisma.budget.delete({ where: { id } });
}
