import '../../../../core/network/network_exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../remote/budget_api.dart';
import '../remote/dto/insights_mapper.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._api);

  final BudgetApi _api;

  @override
  Future<Result<List<Budget>>> getBudgets({int? month, int? year}) async {
    try {
      final items = await _api.listBudgets(month: month, year: year);
      return Result.ok(items.map(budgetFromJson).toList());
    } catch (e) {
      return Result.err(mapDioException(e));
    }
  }

  @override
  Future<Result<Budget>> setBudget(Budget budget) async {
    try {
      final json = await _api.upsertBudget(budgetToJson(budget));
      return Result.ok(budgetFromJson(json));
    } catch (e) {
      return Result.err(mapDioException(e));
    }
  }

  @override
  Future<Result<void>> deleteBudget(String id) async {
    try {
      await _api.deleteBudget(id);
      return const Result.ok(null);
    } catch (e) {
      return Result.err(mapDioException(e));
    }
  }
}
