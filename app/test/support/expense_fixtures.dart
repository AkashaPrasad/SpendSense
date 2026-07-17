import 'package:decimal/decimal.dart';
import 'package:spendsense/features/expenses/domain/entities/expense.dart';
import 'package:spendsense/features/expenses/domain/entities/expense_category.dart';
import 'package:spendsense/features/expenses/domain/entities/transaction_type.dart';

Expense buildExpense({
  String clientId = 'client-1',
  String? id,
  TransactionType type = TransactionType.expense,
  String merchant = 'Coffee Shop',
  String amount = '4.50',
  ExpenseCategory category = ExpenseCategory.food,
  DateTime? date,
}) {
  final now = date ?? DateTime(2026, 6, 15);
  return Expense(
    clientId: clientId,
    id: id,
    type: type,
    merchant: merchant,
    amount: Decimal.parse(amount),
    category: category,
    date: now,
    createdAt: now,
    updatedAt: now,
  );
}
