import { z } from 'zod';
import { EXPENSE_CATEGORIES } from './expense';

export const createBudgetSchema = z.object({
  category: z.enum(EXPENSE_CATEGORIES),
  monthlyLimit: z.number().positive(),
  month: z.number().int().min(1).max(12),
  year: z.number().int().min(2000).max(2100),
});

export type CreateBudgetInput = z.infer<typeof createBudgetSchema>;
