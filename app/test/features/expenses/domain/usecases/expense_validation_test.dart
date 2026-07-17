import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsense/features/expenses/domain/usecases/expense_validation.dart';

void main() {
  group('validateExpense', () {
    test('rejects an empty merchant name', () {
      final error = validateExpense(
        merchant: '  ',
        amount: Decimal.fromInt(10),
        date: DateTime.now(),
      );
      expect(error, isNotNull);
    });

    test('rejects a zero amount', () {
      final error = validateExpense(
        merchant: 'Coffee Shop',
        amount: Decimal.zero,
        date: DateTime.now(),
      );
      expect(error, isNotNull);
    });

    test('rejects a negative amount', () {
      final error = validateExpense(
        merchant: 'Coffee Shop',
        amount: Decimal.parse('-5'),
        date: DateTime.now(),
      );
      expect(error, isNotNull);
    });

    test('rejects a date more than one day in the future', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final error = validateExpense(
        merchant: 'Coffee Shop',
        amount: Decimal.fromInt(10),
        date: future,
      );
      expect(error, isNotNull);
    });

    test('accepts a valid expense', () {
      final error = validateExpense(
        merchant: 'Coffee Shop',
        amount: Decimal.parse('4.50'),
        date: DateTime.now(),
      );
      expect(error, isNull);
    });
  });
}
