import { Response } from 'express';
import { HttpError } from '../middleware/errorHandler';
import { AuthedRequest } from '../middleware/authMiddleware';
import * as insightsService from '../services/insights.service';

function currentMonthYear(req: AuthedRequest) {
  const now = new Date();
  const month = req.query.month ? Number(req.query.month) : now.getUTCMonth() + 1;
  const year = req.query.year ? Number(req.query.year) : now.getUTCFullYear();
  if (!Number.isInteger(month) || month < 1 || month > 12) {
    throw new HttpError(400, 'month must be an integer between 1 and 12');
  }
  if (!Number.isInteger(year)) {
    throw new HttpError(400, 'year must be an integer');
  }
  return { month, year };
}

export async function categorySummary(req: AuthedRequest, res: Response) {
  const { month, year } = currentMonthYear(req);
  const items = await insightsService.categorySummary(req.userId, month, year);
  res.json({ month, year, items });
}

export async function trend(req: AuthedRequest, res: Response) {
  const months = req.query.months ? Number(req.query.months) : 6;
  if (!Number.isInteger(months) || months < 1 || months > 24) {
    throw new HttpError(400, 'months must be an integer between 1 and 24');
  }
  const items = await insightsService.spendTrend(req.userId, months);
  res.json({ items });
}

export async function budgetVsActual(req: AuthedRequest, res: Response) {
  const { month, year } = currentMonthYear(req);
  const items = await insightsService.budgetVsActual(req.userId, month, year);
  res.json({ month, year, items });
}

export async function incomeVsExpense(req: AuthedRequest, res: Response) {
  const { month, year } = currentMonthYear(req);
  const result = await insightsService.incomeVsExpense(req.userId, month, year);
  res.json({ month, year, ...result });
}
