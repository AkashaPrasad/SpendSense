const mockGenerateContent = jest.fn();
const mockGetGenerativeModel = jest.fn().mockReturnValue({ generateContent: mockGenerateContent });

jest.mock('@google/generative-ai', () => ({
  GoogleGenerativeAI: jest.fn().mockImplementation(() => ({
    getGenerativeModel: mockGetGenerativeModel,
  })),
  SchemaType: { OBJECT: 'OBJECT', STRING: 'STRING', ARRAY: 'ARRAY', NUMBER: 'NUMBER' },
  FunctionCallingMode: { ANY: 'ANY' },
}));

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { extractQueryIntent, extractReceiptData } = require('../../src/services/gemini.service');

function respondWithFunctionCall(name: string, args: unknown) {
  mockGenerateContent.mockResolvedValueOnce({
    response: { functionCalls: () => [{ name, args }] },
  });
}

describe('gemini.service — the only module allowed to call the LLM', () => {
  describe('extractQueryIntent', () => {
    it('parses a well-formed function call into a validated QueryIntent', async () => {
      respondWithFunctionCall('extract_query_intent', {
        intent: 'CATEGORY_TOTAL',
        categories: ['FOOD'],
        startDate: '2026-06-01',
        endDate: '2026-06-30',
      });

      const intent = await extractQueryIntent('how much on food last month?', new Date('2026-07-01'));

      expect(intent).toEqual({
        intent: 'CATEGORY_TOTAL',
        categories: ['FOOD'],
        startDate: '2026-06-01',
        endDate: '2026-06-30',
      });
    });

    it('rejects a function call with an invalid enum value instead of passing it through', async () => {
      respondWithFunctionCall('extract_query_intent', {
        intent: 'NOT_A_REAL_INTENT',
        startDate: '2026-06-01',
        endDate: '2026-06-30',
      });

      await expect(extractQueryIntent('nonsense', new Date())).rejects.toThrow(/incomplete query intent/i);
    });

    it('throws when the model returns no function call at all', async () => {
      mockGenerateContent.mockResolvedValueOnce({ response: { functionCalls: () => undefined } });

      await expect(extractQueryIntent('??', new Date())).rejects.toThrow(/could not understand/i);
    });
  });

  describe('extractReceiptData', () => {
    it('parses a well-formed receipt extraction call', async () => {
      respondWithFunctionCall('extract_receipt_data', {
        merchant: 'Trader Joes',
        date: '2026-07-10',
        currency: 'USD',
        total: 42.15,
        suggestedCategory: 'GROCERIES',
        lineItems: [{ name: 'Bananas', amount: 2.5, qty: 1 }],
      });

      const draft = await extractReceiptData(Buffer.from('fake-image'), 'image/jpeg');

      expect(draft.merchant).toBe('Trader Joes');
      expect(draft.total).toBe(42.15);
      expect(draft.suggestedCategory).toBe('GROCERIES');
    });

    it('throws a client-friendly error when extraction is incomplete', async () => {
      respondWithFunctionCall('extract_receipt_data', { merchant: 'Unknown' });

      await expect(extractReceiptData(Buffer.from('x'), 'image/png')).rejects.toThrow(/verify the fields/i);
    });
  });
});
