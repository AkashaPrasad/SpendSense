import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'daos/expenses_dao.dart';
import 'tables/expenses_table.dart';

part 'app_database.g.dart';

/// The offline-first local cache. Requires a platform with native SQLite
/// (Android/iOS/macOS/Linux/Windows via dart:ffi) — see README's "Known
/// limitations" for why web isn't a supported target for this database.
@DriftDatabase(tables: [ExpensesTable], daos: [ExpensesDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'spendsense.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
