import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'daos/expenses_dao.dart';
import 'tables/expenses_table.dart';

part 'app_database.g.dart';

/// The offline-first local cache. Uses `drift_flutter`'s cross-platform
/// opener: native SQLite (via dart:ffi) on Android/iOS/macOS/Windows/Linux,
/// and SQLite compiled to WebAssembly (via `web/sqlite3.wasm` +
/// `web/drift_worker.js`) on the web target.
@DriftDatabase(tables: [ExpensesTable], daos: [ExpensesDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'spendsense',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
