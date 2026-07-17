// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import '../../../../core/network/network_exception_mapper.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/receipt_draft.dart';
import '../../domain/repositories/expense_repository.dart';
import '../local/daos/expenses_dao.dart';
import '../local/local_expense_mapper.dart';
import '../remote/dto/expense_mapper.dart';
import '../remote/expense_api.dart';
import '../sync/sync_service.dart';

/// Offline-first: every write lands in the local Drift cache immediately
/// (works with no network, feels instant), then a background sync attempt
/// pushes it to the backend. Reads always come from the local cache, kept
/// fresh by that same sync.
class ExpenseRepositoryImpl implements ExpenseRepository {
  // Named params stay public (dao/api/syncService) while backing fields stay
  // private, so `this._x` initializing formals don't apply here.
  ExpenseRepositoryImpl({
    required ExpensesDao dao,
    required ExpenseApi api,
    required SyncService syncService,
  }) : _dao = dao,
       _api = api,
       _syncService = syncService;

  final ExpensesDao _dao;
  final ExpenseApi _api;
  final SyncService _syncService;

  @override
  Stream<List<Expense>> watchExpenses(ExpenseFilter filter) {
    return _dao
        .watchAll(
          from: filter.from,
          to: filter.to,
          category: filter.category?.apiValue,
          type: filter.type?.apiValue,
        )
        .map((rows) => rows.map(expenseFromRow).toList());
  }

  @override
  Future<Result<Expense>> createExpense(Expense expense) async {
    try {
      await _dao.upsertRow(expenseToCompanion(expense));
      unawaited(_trySyncSilently());
      return Result.ok(expense);
    } catch (e) {
      return Result.err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Expense>> updateExpense(Expense expense) async {
    try {
      final updated = expense.copyWith(
        isSynced: false,
        updatedAt: DateTime.now(),
      );
      await _dao.upsertRow(expenseToCompanion(updated));
      unawaited(_trySyncSilently());
      return Result.ok(updated);
    } catch (e) {
      return Result.err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteExpense(String clientId) async {
    try {
      await _dao.softDelete(clientId);
      unawaited(_trySyncSilently());
      return const Result.ok(null);
    } catch (e) {
      return Result.err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<ReceiptDraft>> captureReceipt({
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    try {
      final extension = mimeType.split('/').last;
      final json = await _api.extractReceipt(
        bytes: imageBytes,
        mimeType: mimeType,
        filename: 'receipt.$extension',
      );
      return Result.ok(receiptDraftFromJson(json));
    } catch (e) {
      return Result.err(mapDioException(e));
    }
  }

  @override
  Future<Result<void>> syncPendingExpenses() async {
    try {
      await _syncService.sync();
      return const Result.ok(null);
    } catch (e) {
      return Result.err(mapDioException(e));
    }
  }

  Future<void> _trySyncSilently() async {
    try {
      await _syncService.sync();
    } catch (_) {
      // Offline or transient failure — the row stays marked unsynced and
      // will be retried on the next explicit or connectivity-triggered sync.
    }
  }
}
