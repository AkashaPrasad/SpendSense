import 'package:decimal/decimal.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/budget.dart';
import '../repositories/budget_repository.dart';

class SetBudget {
  const SetBudget(this._repository);

  final BudgetRepository _repository;

  Future<Result<Budget>> call(Budget budget) {
    if (budget.monthlyLimit <= Decimal.zero) {
      return Future.value(
        const Result.err(
          ValidationFailure('Budget must be greater than zero.'),
        ),
      );
    }
    if (budget.month < 1 || budget.month > 12) {
      return Future.value(
        const Result.err(ValidationFailure('Invalid month.')),
      );
    }
    if (budget.year < 2000 || budget.year > 2100) {
      return Future.value(const Result.err(ValidationFailure('Invalid year.')));
    }
    return _repository.setBudget(budget);
  }
}
