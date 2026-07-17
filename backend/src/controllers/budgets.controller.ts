import { Response } from 'express';
import { AuthedRequest } from '../middleware/authMiddleware';
import * as budgetService from '../services/budget.service';
import { createBudgetSchema } from '../types/budget';

export async function list(req: AuthedRequest, res: Response) {
  const month = req.query.month ? Number(req.query.month) : undefined;
  const year = req.query.year ? Number(req.query.year) : undefined;
  const budgets = await budgetService.listBudgets(req.userId, month, year);
  res.json({ items: budgets });
}

export async function upsert(req: AuthedRequest, res: Response) {
  const input = createBudgetSchema.parse(req.body);
  const budget = await budgetService.upsertBudget(req.userId, input);
  res.status(201).json(budget);
}

export async function remove(req: AuthedRequest, res: Response) {
  await budgetService.deleteBudget(req.userId, req.params.id);
  res.status(204).send();
}
