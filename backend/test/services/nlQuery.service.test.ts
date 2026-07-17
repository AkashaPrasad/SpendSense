import type { QueryIntent } from '../../src/types/query';

jest.mock('../../src/lib/prisma', () => ({
  prisma: {
    expense: {
      aggregate: jest.fn(),
      findMany: jest.fn(),
      groupBy: jest.fn(),
    },
    budget: {
      findMany: jest.fn(),
    },
  },
}));

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { prisma } = require('../../src/lib/prisma');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { runQuery } = require('../../src/services/nlQuery.service');

const USER_ID = 'user-123';

function baseIntent(overrides: Partial<QueryIntent>): QueryIntent {
  return {
    intent: 'OVERALL_TOTAL',
    categories: [],
    startDate: '2026-06-01',
    endDate: '2026-06-30',
    ...overrides,
  };
}

describe('nlQuery.service runQuery — NL query parser logic (LLM call mocked out)', () => {
  it('CATEGORY_TOTAL sums a single category and phrases the answer in dollars', async () => {
    prisma.expense.aggregate.mockResolvedValue({ _sum: { amount: 142.5 } });

    const result = await runQuery(
      USER_ID,
      baseIntent({ intent: 'CATEGORY_TOTAL', categories: ['FOOD'] }),
    );

    expect(prisma.expense.aggregate).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ userId: USER_ID, category: { in: ['FOOD'] } }),
      }),
    );
    expect(result.answer).toContain('$142.50');
    expect(result.answer).toContain('Food');
    expect(result.chart).toEqual({
      type: 'pie',
      labels: ['Food'],
      series: [{ label: 'Spent', values: [142.5] }],
    });
  });

  it('CATEGORY_TOTAL with no category asks the user to clarify instead of guessing', async () => {
    const result = await runQuery(USER_ID, baseIntent({ intent: 'CATEGORY_TOTAL', categories: [] }));

    expect(prisma.expense.aggregate).not.toHaveBeenCalled();
    expect(result.chart).toBeNull();
    expect(result.answer).toMatch(/couldn't tell which category/i);
  });

  it('OVERALL_TOTAL only counts EXPENSE type transactions', async () => {
    prisma.expense.aggregate.mockResolvedValue({ _sum: { amount: 900 } });

    const result = await runQuery(USER_ID, baseIntent({ intent: 'OVERALL_TOTAL' }));

    expect(prisma.expense.aggregate).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ type: 'EXPENSE' }) }),
    );
    expect(result.answer).toContain('$900.00');
  });

  it('SPEND_VS_INCOME compares expense and income totals and computes the percentage', async () => {
    prisma.expense.aggregate
      .mockResolvedValueOnce({ _sum: { amount: 400 } }) // expense (food)
      .mockResolvedValueOnce({ _sum: { amount: 2000 } }); // income

    const result = await runQuery(
      USER_ID,
      baseIntent({ intent: 'SPEND_VS_INCOME', categories: ['FOOD'] }),
    );

    expect(result.answer).toContain('$400.00');
    expect(result.answer).toContain('$2,000.00');
    expect(result.answer).toContain('20%');
    expect(result.chart?.series[0].values).toEqual([400, 2000]);
  });

  it('SPEND_VS_INCOME with zero income omits the percentage instead of dividing by zero', async () => {
    prisma.expense.aggregate
      .mockResolvedValueOnce({ _sum: { amount: 400 } })
      .mockResolvedValueOnce({ _sum: { amount: 0 } });

    const result = await runQuery(USER_ID, baseIntent({ intent: 'SPEND_VS_INCOME' }));

    expect(result.answer).not.toContain('%');
  });

  it('TREND buckets rows by month and totals them', async () => {
    prisma.expense.findMany.mockResolvedValue([
      { date: new Date('2026-04-15'), amount: 100 },
      { date: new Date('2026-04-20'), amount: 50 },
      { date: new Date('2026-05-05'), amount: 75 },
    ]);

    const result = await runQuery(
      USER_ID,
      baseIntent({ intent: 'TREND', startDate: '2026-04-01', endDate: '2026-05-31' }),
    );

    expect(result.chart?.type).toBe('line');
    expect(result.chart?.labels).toHaveLength(2);
    expect(result.chart?.series[0].values).toEqual([150, 75]);
    expect(result.answer).toContain('$225.00');
  });

  it('TREND reports no spending without crashing when there are no rows', async () => {
    prisma.expense.findMany.mockResolvedValue([]);

    const result = await runQuery(USER_ID, baseIntent({ intent: 'TREND' }));

    expect(result.chart?.labels).toEqual([]);
    expect(result.answer).toMatch(/no spending recorded/i);
  });

  it('COMPARE_CATEGORIES falls back to the top 5 categories when none are named', async () => {
    prisma.expense.groupBy.mockResolvedValue([
      { category: 'FOOD', _sum: { amount: 300 } },
      { category: 'TRANSPORT', _sum: { amount: 120 } },
    ]);
    prisma.expense.aggregate
      .mockResolvedValueOnce({ _sum: { amount: 300 } })
      .mockResolvedValueOnce({ _sum: { amount: 120 } });

    const result = await runQuery(USER_ID, baseIntent({ intent: 'COMPARE_CATEGORIES', categories: [] }));

    expect(prisma.expense.groupBy).toHaveBeenCalledWith(
      expect.objectContaining({ take: 5 }),
    );
    expect(result.chart?.labels).toEqual(['Food', 'Transport']);
    expect(result.chart?.series[0].values).toEqual([300, 120]);
  });

  it('BUDGET_VS_ACTUAL reports "no budget set" when the user has none for that month', async () => {
    prisma.budget.findMany.mockResolvedValue([]);

    const result = await runQuery(USER_ID, baseIntent({ intent: 'BUDGET_VS_ACTUAL' }));

    expect(result.chart).toBeNull();
    expect(result.answer).toMatch(/haven't set a budget/i);
  });

  it('BUDGET_VS_ACTUAL flags categories that are over budget', async () => {
    prisma.budget.findMany.mockResolvedValue([
      { category: 'FOOD', monthlyLimit: 200 },
      { category: 'TRANSPORT', monthlyLimit: 100 },
    ]);
    prisma.expense.aggregate
      .mockResolvedValueOnce({ _sum: { amount: 250 } }) // FOOD over
      .mockResolvedValueOnce({ _sum: { amount: 80 } }); // TRANSPORT under

    const result = await runQuery(USER_ID, baseIntent({ intent: 'BUDGET_VS_ACTUAL' }));

    expect(result.answer).toContain('Food');
    expect(result.answer).not.toContain('Transport');
    expect(result.chart?.series).toEqual([
      { label: 'Budget', values: [200, 100] },
      { label: 'Actual', values: [250, 80] },
    ]);
  });
});
