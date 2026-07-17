import { z } from 'zod';

export const EXPENSE_CATEGORIES = [
  'FOOD',
  'GROCERIES',
  'TRANSPORT',
  'SHOPPING',
  'ENTERTAINMENT',
  'BILLS_UTILITIES',
  'HEALTH',
  'TRAVEL',
  'EDUCATION',
  'RENT_HOUSING',
  'SALARY',
  'OTHER_INCOME',
  'OTHER',
] as const;

export const TRANSACTION_TYPES = ['EXPENSE', 'INCOME'] as const;

const isoDate = z.string().refine((v) => !Number.isNaN(Date.parse(v)), {
  message: 'Must be a valid ISO date string',
});

export const lineItemSchema = z.object({
  name: z.string().min(1).max(200),
  amount: z.number(),
  qty: z.number().positive().optional(),
});

export const createExpenseSchema = z.object({
  type: z.enum(TRANSACTION_TYPES).default('EXPENSE'),
  merchant: z.string().min(1).max(200),
  amount: z.number().positive(),
  currency: z.string().length(3).default('USD'),
  category: z.enum(EXPENSE_CATEGORIES),
  date: isoDate,
  notes: z.string().max(1000).optional(),
  source: z.enum(['MANUAL', 'RECEIPT']).default('MANUAL'),
  receiptImageUrl: z.string().url().optional(),
  lineItems: z.array(lineItemSchema).optional(),
  clientId: z.string().min(1).max(100).optional(),
});

export const updateExpenseSchema = createExpenseSchema.partial();

export const syncExpensesSchema = z.object({
  expenses: z.array(createExpenseSchema.extend({ clientId: z.string().min(1).max(100) })),
});

export const listExpensesQuerySchema = z.object({
  from: isoDate.optional(),
  to: isoDate.optional(),
  category: z.enum(EXPENSE_CATEGORIES).optional(),
  type: z.enum(TRANSACTION_TYPES).optional(),
  updatedSince: isoDate.optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(200).default(50),
});

export type CreateExpenseInput = z.infer<typeof createExpenseSchema>;
export type UpdateExpenseInput = z.infer<typeof updateExpenseSchema>;
export type ListExpensesQuery = z.infer<typeof listExpensesQuerySchema>;
export type ExpenseCategory = (typeof EXPENSE_CATEGORIES)[number];
export type TransactionType = (typeof TRANSACTION_TYPES)[number];
