import '../../../../core/utils/result.dart';
import '../entities/budget.dart';
import '../repositories/budget_repository.dart';

class ListBudgets {
  const ListBudgets(this._repository);

  final BudgetRepository _repository;

  Future<Result<List<Budget>>> call({int? month, int? year}) {
    return _repository.getBudgets(month: month, year: year);
  }
}
