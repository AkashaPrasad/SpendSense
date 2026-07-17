import { z } from 'zod';
import { EXPENSE_CATEGORIES } from './expense';

/**
 * Structured shape the LLM must fill in via function-calling. We never let
 * the model emit raw SQL — only this constrained, validated intent object,
 * which the backend then maps to parametrized Prisma queries.
 */
export const QUERY_INTENTS = [
  'CATEGORY_TOTAL',
  'OVERALL_TOTAL',
  'TREND',
  'COMPARE_CATEGORIES',
  'SPEND_VS_INCOME',
  'BUDGET_VS_ACTUAL',
] as const;

export const queryIntentSchema = z.object({
  intent: z.enum(QUERY_INTENTS),
  categories: z.array(z.enum(EXPENSE_CATEGORIES)).optional().default([]),
  startDate: z.string().refine((v) => !Number.isNaN(Date.parse(v))),
  endDate: z.string().refine((v) => !Number.isNaN(Date.parse(v))),
  compareStartDate: z
    .string()
    .refine((v) => !Number.isNaN(Date.parse(v)))
    .optional(),
  compareEndDate: z
    .string()
    .refine((v) => !Number.isNaN(Date.parse(v)))
    .optional(),
  groupBy: z.enum(['day', 'week', 'month', 'category']).optional(),
});

export type QueryIntent = z.infer<typeof queryIntentSchema>;

export type ChartType = 'bar' | 'line' | 'pie';

export interface ChartSeries {
  label: string;
  values: number[];
}

export interface ChartSpec {
  type: ChartType;
  labels: string[];
  series: ChartSeries[];
}

export interface QueryResult {
  answer: string;
  chart: ChartSpec | null;
  intent: QueryIntent;
}
