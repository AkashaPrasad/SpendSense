import { Response } from 'express';
import { AuthedRequest } from '../middleware/authMiddleware';
import * as expenseService from '../services/expense.service';
import {
  createExpenseSchema,
  listExpensesQuerySchema,
  syncExpensesSchema,
  updateExpenseSchema,
} from '../types/expense';

export async function list(req: AuthedRequest, res: Response) {
  const query = listExpensesQuerySchema.parse(req.query);
  const result = await expenseService.listExpenses(req.userId, query);
  res.json(result);
}

export async function getOne(req: AuthedRequest, res: Response) {
  const expense = await expenseService.getExpenseById(req.userId, req.params.id);
  res.json(expense);
}

export async function create(req: AuthedRequest, res: Response) {
  const input = createExpenseSchema.parse(req.body);
  const expense = await expenseService.createExpense(req.userId, input);
  res.status(201).json(expense);
}

export async function update(req: AuthedRequest, res: Response) {
  const input = updateExpenseSchema.parse(req.body);
  const expense = await expenseService.updateExpense(req.userId, req.params.id, input);
  res.json(expense);
}

export async function remove(req: AuthedRequest, res: Response) {
  await expenseService.deleteExpense(req.userId, req.params.id);
  res.status(204).send();
}

export async function sync(req: AuthedRequest, res: Response) {
  const input = syncExpensesSchema.parse(req.body);
  const result = await expenseService.syncExpenses(req.userId, input.expenses);
  res.json({ synced: result });
}
