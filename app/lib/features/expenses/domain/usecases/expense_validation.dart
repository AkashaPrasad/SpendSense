import 'package:decimal/decimal.dart';

/// Shared client-side validation before an expense ever reaches the local
/// cache or the network — catches mistakes instantly, offline included.
String? validateExpense({
  required String merchant,
  required Decimal amount,
  required DateTime date,
}) {
  if (merchant.trim().isEmpty) {
    return 'Enter a merchant or payee name.';
  }
  if (amount <= Decimal.zero) {
    return 'Amount must be greater than zero.';
  }
  final oneDayFromNow = DateTime.now().add(const Duration(days: 1));
  if (date.isAfter(oneDayFromNow)) {
    return 'Date can\'t be in the future.';
  }
  return null;
}
