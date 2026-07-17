import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/result.dart';
import '../entities/expense.dart';
import '../entities/expense_category.dart';
import '../entities/expense_source.dart';
import '../entities/receipt_draft.dart';
import '../entities/transaction_type.dart';
import 'create_expense.dart';

/// Turns a Gemini-extracted [ReceiptDraft] into a saved [Expense], after the
/// user has reviewed it — applying any corrections they made along the way.
/// This is the "user confirms before saving" step from the product spec.
class ConfirmReceiptExpense {
  ConfirmReceiptExpense(this._createExpense, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final CreateExpense _createExpense;
  final Uuid _uuid;

  Future<Result<Expense>> call({
    required ReceiptDraft draft,
    String? merchantOverride,
    Decimal? amountOverride,
    ExpenseCategory? categoryOverride,
    DateTime? dateOverride,
    String? notes,
    String? receiptImageUrl,
  }) {
    final now = DateTime.now();
    final expense = Expense(
      clientId: _uuid.v4(),
      type: TransactionType.expense,
      merchant: merchantOverride ?? draft.merchant,
      amount: amountOverride ?? draft.total,
      currency: draft.currency,
      category: categoryOverride ?? draft.suggestedCategory,
      date: dateOverride ?? draft.date,
      notes: notes,
      source: ExpenseSource.receipt,
      receiptImageUrl: receiptImageUrl,
      lineItems: draft.lineItems,
      createdAt: now,
      updatedAt: now,
    );
    return _createExpense(expense);
  }
}
