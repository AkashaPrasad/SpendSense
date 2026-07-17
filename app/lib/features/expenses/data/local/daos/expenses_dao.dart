import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/expenses_table.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [ExpensesTable])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Stream<List<ExpensesTableData>> watchAll({
    DateTime? from,
    DateTime? to,
    String? category,
    String? type,
  }) {
    final query = select(expensesTable)
      ..where((t) => t.pendingDelete.equals(false));
    if (from != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(to));
    }
    if (category != null) {
      query.where((t) => t.category.equals(category));
    }
    if (type != null) {
      query.where((t) => t.type.equals(type));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query.watch();
  }

  Future<ExpensesTableData?> findByClientId(String clientId) => (select(
    expensesTable,
  )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();

  Future<void> upsertRow(ExpensesTableCompanion row) =>
      into(expensesTable).insertOnConflictUpdate(row);

  Future<void> markSynced(
    String clientId, {
    required String serverId,
    required DateTime updatedAt,
  }) {
    return (update(
      expensesTable,
    )..where((t) => t.clientId.equals(clientId))).write(
      ExpensesTableCompanion(
        serverId: Value(serverId),
        isSynced: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> softDelete(String clientId) {
    return (update(
      expensesTable,
    )..where((t) => t.clientId.equals(clientId))).write(
      const ExpensesTableCompanion(
        pendingDelete: Value(true),
        isSynced: Value(false),
      ),
    );
  }

  Future<void> hardDelete(String clientId) =>
      (delete(expensesTable)..where((t) => t.clientId.equals(clientId))).go();

  Future<List<ExpensesTableData>> getUnsyncedUpserts() =>
      (select(expensesTable)..where(
            (t) => t.isSynced.equals(false) & t.pendingDelete.equals(false),
          ))
          .get();

  Future<List<ExpensesTableData>> getPendingDeletes() =>
      (select(expensesTable)..where((t) => t.pendingDelete.equals(true))).get();

  Future<DateTime?> getLatestUpdatedAt() async {
    final query = selectOnly(expensesTable)
      ..addColumns([expensesTable.updatedAt.max()]);
    final row = await query.getSingleOrNull();
    return row?.read(expensesTable.updatedAt.max());
  }
}
