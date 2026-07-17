import { z } from 'zod';
import { EXPENSE_CATEGORIES, lineItemSchema } from './expense';

export const receiptDraftSchema = z.object({
  merchant: z.string().min(1),
  date: z.string().refine((v) => !Number.isNaN(Date.parse(v))),
  currency: z.string().length(3).default('USD'),
  total: z.number().nonnegative(),
  suggestedCategory: z.enum(EXPENSE_CATEGORIES),
  lineItems: z.array(lineItemSchema).default([]),
  confidence: z.number().min(0).max(1).default(0.75),
});

export type ReceiptDraft = z.infer<typeof receiptDraftSchema>;
