import '../../../../core/utils/result.dart';
import '../repositories/expense_repository.dart';

class SyncPendingExpenses {
  const SyncPendingExpenses(this._repository);

  final ExpenseRepository _repository;

  Future<Result<void>> call() => _repository.syncPendingExpenses();
}
