import { bucketKey, sumByBucket } from '../../src/utils/dateBuckets';

describe('dateBuckets', () => {
  it('buckets by month and sums correctly, sorted chronologically', () => {
    const rows = [
      { date: new Date('2026-05-20'), amount: 10 },
      { date: new Date('2026-04-01'), amount: 5 },
      { date: new Date('2026-05-01'), amount: 20 },
    ];

    const buckets = sumByBucket(rows, 'month');

    expect(buckets.map((b) => b.key)).toEqual(['2026-04', '2026-05']);
    expect(buckets.map((b) => b.total)).toEqual([5, 30]);
  });

  it('buckets by day using the ISO date', () => {
    expect(bucketKey(new Date('2026-07-04T15:30:00Z'), 'day')).toBe('2026-07-04');
  });

  it('returns an empty array for no rows', () => {
    expect(sumByBucket([], 'month')).toEqual([]);
  });
});
