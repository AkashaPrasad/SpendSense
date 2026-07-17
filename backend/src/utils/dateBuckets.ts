export type Granularity = 'day' | 'week' | 'month';

/** ISO week number, e.g. 2026-W03. */
function isoWeekKey(d: Date): string {
  const date = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  const dayNum = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const weekNo = Math.ceil(((date.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
  return `${date.getUTCFullYear()}-W${String(weekNo).padStart(2, '0')}`;
}

export function bucketKey(date: Date, granularity: Granularity): string {
  if (granularity === 'day') return date.toISOString().slice(0, 10);
  if (granularity === 'week') return isoWeekKey(date);
  return date.toISOString().slice(0, 7); // month: YYYY-MM
}

export function bucketLabel(key: string, granularity: Granularity): string {
  if (granularity === 'week') return key; // "2026-W03" is already readable
  if (granularity === 'month') {
    const [y, m] = key.split('-').map(Number);
    return new Date(Date.UTC(y, m - 1, 1)).toLocaleDateString('en-US', {
      month: 'short',
      year: 'numeric',
      timeZone: 'UTC',
    });
  }
  return new Date(key).toLocaleDateString('en-US', { month: 'short', day: 'numeric', timeZone: 'UTC' });
}

/** Buckets ordered chronologically, keyed by bucketKey. */
export function sumByBucket(
  rows: { date: Date; amount: number }[],
  granularity: Granularity,
): { key: string; label: string; total: number }[] {
  const totals = new Map<string, number>();
  for (const row of rows) {
    const key = bucketKey(row.date, granularity);
    totals.set(key, (totals.get(key) ?? 0) + row.amount);
  }
  return [...totals.entries()]
    .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
    .map(([key, total]) => ({ key, label: bucketLabel(key, granularity), total }));
}
