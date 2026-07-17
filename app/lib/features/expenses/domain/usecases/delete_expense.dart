import '../../../../core/utils/result.dart';
import '../repositories/expense_repository.dart';

class DeleteExpense {
  const DeleteExpense(this._repository);

  final ExpenseRepository _repository;

  Future<Result<void>> call(String clientId) =>
      _repository.deleteExpense(clientId);
}
