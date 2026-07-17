import 'package:dio/dio.dart';
import '../local/daos/expenses_dao.dart';
import '../local/local_expense_mapper.dart';
import '../remote/dto/expense_mapper.dart';
import '../remote/expense_api.dart';

/// Pushes local offline changes to the backend, then pulls remote changes
/// back down — call after reconnecting, on a timer, or on-demand from the
/// UI. Safe to call repeatedly; every step is idempotent (upsert-by-id).
class SyncService {
  SyncService(this._dao, this._api);

  final ExpensesDao _dao;
  final ExpenseApi _api;

  Future<void> sync() async {
    await _pushDeletes();
    await _pushUpserts();
    await _pullRemote();
  }

  Future<void> _pushDeletes() async {
    final pending = await _dao.getPendingDeletes();
    for (final row in pending) {
      if (row.serverId != null) {
        try {
          await _api.deleteExpense(row.serverId!);
        } on DioException catch (e) {
          if (e.response?.statusCode != 404) rethrow;
        }
      }
      await _dao.hardDelete(row.clientId);
    }
  }

  Future<void> _pushUpserts() async {
    final unsynced = await _dao.getUnsyncedUpserts();
    if (unsynced.isEmpty) return;

    final body = unsynced
        .map((row) => expenseToCreateJson(expenseFromRow(row)))
        .toList();
    final synced = await _api.syncBatch(body);

    for (final item in synced) {
      await _dao.markSynced(
        item['clientId'] as String,
        serverId: item['id'] as String,
        updatedAt: DateTime.parse(item['updatedAt'] as String),
      );
    }
  }

  Future<void> _pullRemote() async {
    final since = await _dao.getLatestUpdatedAt();
    final remoteRows = await _api.listExpenses(
      updatedSince: since?.toUtc().toIso8601String(),
    );

    for (final json in remoteRows) {
      final fallbackClientId = json['id'] as String;
      final expense = expenseFromRemoteJson(
        json,
        fallbackClientId: fallbackClientId,
      );
      await _dao.upsertRow(expenseToCompanion(expense));
    }
  }
}
