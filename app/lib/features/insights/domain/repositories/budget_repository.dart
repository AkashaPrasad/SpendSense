import '../../../../core/utils/result.dart';
import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<Result<List<Budget>>> getBudgets({int? month, int? year});

  Future<Result<Budget>> setBudget(Budget budget);

  Future<Result<void>> deleteBudget(String id);
}
