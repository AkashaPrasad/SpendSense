import 'package:drift/drift.dart';

/// Local offline-first cache of expenses. [clientId] is the stable primary
/// key (generated on-device); [serverId] is null until the row has synced
/// at least once. Amounts are stored as text to avoid floating-point
/// rounding on money — parsed back into [Decimal] in the repository.
class ExpensesTable extends Table {
  TextColumn get clientId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get merchant => text()();
  TextColumn get amount => text()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('MANUAL'))();
  TextColumn get receiptImageUrl => text().nullable()();

  /// JSON-encoded List<Map> of line items.
  TextColumn get lineItemsJson => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// True once this exact version of the row has been pushed to the server.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// True when deleted locally while offline — hidden from queries, and
  /// only actually removed from the server (and this table) once synced.
  BoolColumn get pendingDelete =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {clientId};
}
