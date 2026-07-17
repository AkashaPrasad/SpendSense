jest.mock('../../src/lib/prisma', () => ({
  prisma: {
    expense: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
      create: jest.fn(),
    },
  },
}));

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { prisma } = require('../../src/lib/prisma');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { createExpense } = require('../../src/services/expense.service');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { HttpError } = require('../../src/middleware/errorHandler');

const USER_ID = 'user-1';
const validInput = {
  type: 'EXPENSE' as const,
  merchant: 'Coffee Shop',
  amount: 4.5,
  currency: 'USD',
  category: 'FOOD' as const,
  date: '2026-07-10',
  source: 'MANUAL' as const,
};

describe('expense.service createExpense — offline-sync idempotency', () => {
  it('creates a plain expense with no clientId directly', async () => {
    prisma.expense.create.mockResolvedValue({ id: 'srv-1', ...validInput });

    await createExpense(USER_ID, validInput);

    expect(prisma.expense.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ userId: USER_ID, merchant: 'Coffee Shop' }) }),
    );
    expect(prisma.expense.upsert).not.toHaveBeenCalled();
  });

  it('upserts by clientId so re-syncing the same offline row never duplicates it', async () => {
    prisma.expense.findUnique.mockResolvedValue(null);
    prisma.expense.upsert.mockResolvedValue({ id: 'srv-2', ...validInput, clientId: 'local-abc' });

    await createExpense(USER_ID, { ...validInput, clientId: 'local-abc' });

    expect(prisma.expense.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { clientId: 'local-abc' } }),
    );
  });

  it('rejects syncing a clientId that already belongs to a different user', async () => {
    prisma.expense.findUnique.mockResolvedValue({ id: 'srv-3', userId: 'someone-else', clientId: 'local-abc' });

    await expect(createExpense(USER_ID, { ...validInput, clientId: 'local-abc' })).rejects.toThrow(HttpError);
    expect(prisma.expense.upsert).not.toHaveBeenCalled();
  });
});
