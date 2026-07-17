import { FunctionCallingMode, FunctionDeclaration, GoogleGenerativeAI, SchemaType } from '@google/generative-ai';
import { env } from '../config/env';
import { HttpError } from '../middleware/errorHandler';
import { EXPENSE_CATEGORIES } from '../types/expense';
import { QUERY_INTENTS, QueryIntent, queryIntentSchema } from '../types/query';
import { ReceiptDraft, receiptDraftSchema } from '../types/receipt';

/**
 * The ONLY module in this codebase allowed to talk to Gemini. The API key
 * lives exclusively in this backend's environment — it is never sent to,
 * nor readable by, the Flutter client.
 */
const genAI = new GoogleGenerativeAI(env.GEMINI_API_KEY);

const extractQueryIntentDeclaration: FunctionDeclaration = {
  name: 'extract_query_intent',
  description:
    'Extract a structured intent from a natural-language question about the user\'s personal finances. ' +
    'Never invent numbers — only classify what the user is asking for and the date range involved.',
  parameters: {
    type: SchemaType.OBJECT,
    properties: {
      intent: {
        type: SchemaType.STRING,
        format: 'enum',
        enum: [...QUERY_INTENTS],
        description:
          'CATEGORY_TOTAL: total for one/more categories. OVERALL_TOTAL: total spend regardless of category. ' +
          'TREND: spend over time. COMPARE_CATEGORIES: compare multiple categories. ' +
          'SPEND_VS_INCOME: expense total vs income/salary total. BUDGET_VS_ACTUAL: budget vs actual spend.',
      },
      categories: {
        type: SchemaType.ARRAY,
        items: { type: SchemaType.STRING, format: 'enum', enum: [...EXPENSE_CATEGORIES] },
        description: 'Relevant categories, if the question names any (e.g. "food" -> FOOD).',
      },
      startDate: { type: SchemaType.STRING, description: 'Start of the primary date range, ISO YYYY-MM-DD.' },
      endDate: { type: SchemaType.STRING, description: 'End of the primary date range, ISO YYYY-MM-DD.' },
      compareStartDate: {
        type: SchemaType.STRING,
        description: 'Start of a comparison period, only if the question compares two periods.',
      },
      compareEndDate: { type: SchemaType.STRING, description: 'End of a comparison period.' },
      groupBy: {
        type: SchemaType.STRING,
        format: 'enum',
        enum: ['day', 'week', 'month', 'category'],
        description: 'How to bucket results, if relevant.',
      },
    },
    required: ['intent', 'startDate', 'endDate'],
  },
};

const extractReceiptDataDeclaration: FunctionDeclaration = {
  name: 'extract_receipt_data',
  description: 'Extract structured purchase data from a photo of a retail/restaurant receipt.',
  parameters: {
    type: SchemaType.OBJECT,
    properties: {
      merchant: { type: SchemaType.STRING, description: 'Store or business name.' },
      date: { type: SchemaType.STRING, description: 'Purchase date in ISO YYYY-MM-DD, as printed on the receipt.' },
      currency: { type: SchemaType.STRING, description: '3-letter ISO currency code, e.g. USD.' },
      total: { type: SchemaType.NUMBER, description: 'Final total amount charged.' },
      suggestedCategory: {
        type: SchemaType.STRING,
        format: 'enum',
        enum: [...EXPENSE_CATEGORIES],
        description: 'Best-guess spending category for this receipt.',
      },
      lineItems: {
        type: SchemaType.ARRAY,
        items: {
          type: SchemaType.OBJECT,
          properties: {
            name: { type: SchemaType.STRING },
            amount: { type: SchemaType.NUMBER },
            qty: { type: SchemaType.NUMBER },
          },
          required: ['name', 'amount'],
        },
      },
      confidence: { type: SchemaType.NUMBER, description: 'Your confidence in this extraction, 0 to 1.' },
    },
    required: ['merchant', 'date', 'total', 'suggestedCategory'],
  },
};

function buildFunctionModel(declaration: FunctionDeclaration, functionName: string) {
  return genAI.getGenerativeModel({
    model: env.GEMINI_MODEL,
    tools: [{ functionDeclarations: [declaration] }],
    toolConfig: {
      functionCallingConfig: {
        mode: FunctionCallingMode.ANY,
        allowedFunctionNames: [functionName],
      },
    },
  });
}

const queryIntentModel = buildFunctionModel(extractQueryIntentDeclaration, 'extract_query_intent');
const receiptModel = buildFunctionModel(extractReceiptDataDeclaration, 'extract_receipt_data');

/**
 * Turns a free-form question ("how much did I spend on food last month vs my
 * salary?") into a validated, structured QueryIntent. The model NEVER sees
 * the user's actual financial data and NEVER returns SQL — only intent
 * classification. All arithmetic happens later in nlQuery.service against
 * Postgres, where it's fast, correct, and auditable.
 */
export async function extractQueryIntent(question: string, referenceDate: Date): Promise<QueryIntent> {
  const prompt =
    `Today's date is ${referenceDate.toISOString().slice(0, 10)}. ` +
    `Resolve relative dates ("last month", "this week") against that. ` +
    `User question: "${question}"`;

  const result = await queryIntentModel.generateContent(prompt);
  const call = result.response.functionCalls()?.[0];

  if (!call || call.name !== 'extract_query_intent') {
    throw new HttpError(502, 'Could not understand that question — try rephrasing it.');
  }

  const parsed = queryIntentSchema.safeParse(call.args);
  if (!parsed.success) {
    throw new HttpError(502, 'Gemini returned an incomplete query intent', parsed.error.flatten());
  }
  return parsed.data;
}

/**
 * Runs Gemini Vision on a receipt photo and returns a structured draft the
 * user must confirm before it's saved as an expense.
 */
export async function extractReceiptData(imageBuffer: Buffer, mimeType: string): Promise<ReceiptDraft> {
  const result = await receiptModel.generateContent([
    { inlineData: { data: imageBuffer.toString('base64'), mimeType } },
    { text: 'Extract this receipt into structured data via the extract_receipt_data function.' },
  ]);
  const call = result.response.functionCalls()?.[0];

  if (!call || call.name !== 'extract_receipt_data') {
    throw new HttpError(422, 'Could not read that receipt — try a clearer photo or enter it manually.');
  }

  const parsed = receiptDraftSchema.safeParse(call.args);
  if (!parsed.success) {
    throw new HttpError(422, 'Receipt extraction was incomplete — please verify the fields.', parsed.error.flatten());
  }
  return parsed.data;
}
