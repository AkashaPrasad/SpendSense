import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/expenses/data/local/app_database.dart';
import '../network/dio_client.dart';

part 'core_providers.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) => buildDio();

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
Connectivity connectivity(Ref ref) => Connectivity();

/// Emits true/false as connectivity changes, for the offline banner and to
/// trigger a sync attempt on reconnect.
@Riverpod(keepAlive: true)
Stream<bool> isOnline(Ref ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  );
}
