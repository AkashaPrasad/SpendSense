import '../../../../core/utils/result.dart';
import '../repositories/budget_repository.dart';

class DeleteBudget {
  const DeleteBudget(this._repository);

  final BudgetRepository _repository;

  Future<Result<void>> call(String id) => _repository.deleteBudget(id);
}
