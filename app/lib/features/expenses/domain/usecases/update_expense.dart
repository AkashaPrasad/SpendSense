import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';
import 'expense_validation.dart';

class UpdateExpense {
  const UpdateExpense(this._repository);

  final ExpenseRepository _repository;

  Future<Result<Expense>> call(Expense expense) {
    final validationError = validateExpense(
      merchant: expense.merchant,
      amount: expense.amount,
      date: expense.date,
    );
    if (validationError != null) {
      return Future.value(Result.err(ValidationFailure(validationError)));
    }
    return _repository.updateExpense(expense);
  }
}
