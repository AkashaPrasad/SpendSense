import 'package:equatable/equatable.dart';
import '../../../../core/utils/result.dart';
import '../entities/expense.dart';
import '../entities/expense_category.dart';
import '../entities/receipt_draft.dart';
import '../entities/transaction_type.dart';

class ExpenseFilter extends Equatable {
  const ExpenseFilter({this.from, this.to, this.category, this.type});

  final DateTime? from;
  final DateTime? to;
  final ExpenseCategory? category;
  final TransactionType? type;

  @override
  List<Object?> get props => [from, to, category, type];
}

abstract class ExpenseRepository {
  /// Always reads from the local Drift cache — instant, works offline.
  Stream<List<Expense>> watchExpenses(ExpenseFilter filter);

  Future<Result<Expense>> createExpense(Expense expense);

  Future<Result<Expense>> updateExpense(Expense expense);

  Future<Result<void>> deleteExpense(String clientId);

  /// Sends a receipt photo to our backend's Gemini Vision proxy.
  Future<Result<ReceiptDraft>> captureReceipt({
    required List<int> imageBytes,
    required String mimeType,
  });

  /// Pushes any locally-created/edited rows to the backend and pulls
  /// remote changes. Safe to call repeatedly (e.g. on connectivity regain).
  Future<Result<void>> syncPendingExpenses();
}
