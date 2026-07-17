import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/result.dart';
import '../../data/local/daos/expenses_dao.dart';
import '../../data/remote/expense_api.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/sync/sync_service.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/receipt_draft.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/capture_receipt.dart';
import '../../domain/usecases/confirm_receipt_expense.dart';
import '../../domain/usecases/create_expense.dart';
import '../../domain/usecases/delete_expense.dart';
import '../../domain/usecases/update_expense.dart';
import '../../domain/usecases/watch_expenses.dart';

part 'expense_providers.g.dart';

@Riverpod(keepAlive: true)
ExpensesDao expensesDao(Ref ref) => ref.watch(appDatabaseProvider).expensesDao;

@Riverpod(keepAlive: true)
ExpenseApi expenseApi(Ref ref) => ExpenseApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) =>
    SyncService(ref.watch(expensesDaoProvider), ref.watch(expenseApiProvider));

@Riverpod(keepAlive: true)
ExpenseRepository expenseRepository(Ref ref) => ExpenseRepositoryImpl(
  dao: ref.watch(expensesDaoProvider),
  api: ref.watch(expenseApiProvider),
  syncService: ref.watch(syncServiceProvider),
);

@riverpod
Stream<List<Expense>> watchExpenses(Ref ref, ExpenseFilter filter) {
  return WatchExpenses(ref.watch(expenseRepositoryProvider))(filter);
}

/// Kicks a sync attempt whenever connectivity flips from offline to online.
/// Read once (e.g. `ref.watch(connectivitySyncTriggerProvider)`) near the
/// app root to activate it.
@Riverpod(keepAlive: true)
class ConnectivitySyncTrigger extends _$ConnectivitySyncTrigger {
  @override
  void build() {
    var wasOnline = true;
    ref.listen(isOnlineProvider, (previous, next) {
      final online = next.valueOrNull ?? true;
      if (online && !wasOnline) {
        ref.read(expenseRepositoryProvider).syncPendingExpenses();
      }
      wasOnline = online;
    });
  }
}

@riverpod
class ExpenseController extends _$ExpenseController {
  @override
  FutureOr<void> build() {}

  Future<bool> createExpense(Expense expense) async {
    state = const AsyncLoading();
    final result = await CreateExpense(ref.read(expenseRepositoryProvider))(
      expense,
    );
    return _settle(result);
  }

  Future<bool> updateExpense(Expense expense) async {
    state = const AsyncLoading();
    final result = await UpdateExpense(ref.read(expenseRepositoryProvider))(
      expense,
    );
    return _settle(result);
  }

  Future<bool> deleteExpense(String clientId) async {
    state = const AsyncLoading();
    final result = await DeleteExpense(ref.read(expenseRepositoryProvider))(
      clientId,
    );
    return _settle(result);
  }

  Future<ReceiptDraft?> captureReceipt({
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    state = const AsyncLoading();
    final result = await CaptureReceipt(ref.read(expenseRepositoryProvider))(
      imageBytes: imageBytes,
      mimeType: mimeType,
    );
    return result.fold(
      (draft) {
        state = const AsyncData(null);
        return draft;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return null;
      },
    );
  }

  Future<bool> confirmReceipt({
    required ReceiptDraft draft,
    String? merchantOverride,
    ExpenseCategory? categoryOverride,
    String? notes,
  }) async {
    state = const AsyncLoading();
    final createExpense = CreateExpense(ref.read(expenseRepositoryProvider));
    final result = await ConfirmReceiptExpense(createExpense)(
      draft: draft,
      merchantOverride: merchantOverride,
      categoryOverride: categoryOverride,
      notes: notes,
    );
    return _settle(result);
  }

  bool _settle<T>(Result<T> result) {
    return result.fold(
      (_) {
        state = const AsyncData(null);
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
