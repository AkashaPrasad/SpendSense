import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_failure.dart';
import '../../data/remote/budget_api.dart';
import '../../data/remote/insights_api.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/insights_repository_impl.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/query_result.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/insights_repository.dart';
import '../../domain/usecases/ask_nl_query.dart';
import '../../domain/usecases/delete_budget.dart';
import '../../domain/usecases/get_dashboard_summary.dart';
import '../../domain/usecases/list_budgets.dart';
import '../../domain/usecases/set_budget.dart';

part 'insights_providers.g.dart';

@Riverpod(keepAlive: true)
InsightsApi insightsApi(Ref ref) => InsightsApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
BudgetApi budgetApi(Ref ref) => BudgetApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
InsightsRepository insightsRepository(Ref ref) =>
    InsightsRepositoryImpl(ref.watch(insightsApiProvider));

@Riverpod(keepAlive: true)
BudgetRepository budgetRepository(Ref ref) =>
    BudgetRepositoryImpl(ref.watch(budgetApiProvider));

@riverpod
Future<DashboardSummary> dashboardSummary(
  Ref ref, {
  int? month,
  int? year,
}) async {
  final result = await GetDashboardSummary(
    ref.watch(insightsRepositoryProvider),
  )(month: month, year: year);
  return result.fold((summary) => summary, (failure) => throw failure);
}

@riverpod
Future<List<Budget>> budgetsList(Ref ref, {int? month, int? year}) async {
  final result = await ListBudgets(ref.watch(budgetRepositoryProvider))(
    month: month,
    year: year,
  );
  return result.fold((budgets) => budgets, (failure) => throw failure);
}

@riverpod
class BudgetController extends _$BudgetController {
  @override
  FutureOr<void> build() {}

  Future<bool> setBudget(Budget budget) async {
    state = const AsyncLoading();
    final result = await SetBudget(ref.read(budgetRepositoryProvider))(budget);
    return result.fold(
      (_) {
        state = const AsyncData(null);
        ref.invalidate(budgetsListProvider);
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> deleteBudget(String id) async {
    state = const AsyncLoading();
    final result = await DeleteBudget(ref.read(budgetRepositoryProvider))(id);
    return result.fold(
      (_) {
        state = const AsyncData(null);
        ref.invalidate(budgetsListProvider);
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }

  String? get errorMessage {
    final error = state.error;
    return error is AppFailure ? error.message : null;
  }
}

/// Drives the natural-language query bar: submits the question, holds the
/// latest answer + chart (or the in-flight/error state) for the UI.
@riverpod
class NlQueryController extends _$NlQueryController {
  @override
  FutureOr<QueryResult?> build() => null;

  Future<void> ask(String question) async {
    state = const AsyncLoading();
    final result = await AskNlQuery(ref.read(insightsRepositoryProvider))(
      question,
    );
    state = result.fold(
      (queryResult) => AsyncData(queryResult),
      (failure) => AsyncError(failure, StackTrace.current),
    );
  }

  String? get errorMessage {
    final error = state.error;
    return error is AppFailure ? error.message : null;
  }
}
