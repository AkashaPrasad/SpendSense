import { formatCategory, formatMoney } from '../../src/utils/format';

describe('format utils', () => {
  it('formats money as USD currency', () => {
    expect(formatMoney(1234.5)).toBe('$1,234.50');
  });

  it('formats category enum values into title case', () => {
    expect(formatCategory('BILLS_UTILITIES')).toBe('Bills Utilities');
    expect(formatCategory('FOOD')).toBe('Food');
  });
});
