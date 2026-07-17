import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../env/env.dart';

/// Builds the single Dio instance the app uses to talk to our backend.
/// Attaches the current Firebase ID token on every request — the backend
/// verifies it and derives the user id from it; the token itself is the
/// only piece of "auth" the client ever sends.
Dio buildDio({FirebaseAuth? firebaseAuth}) {
  final auth = firebaseAuth ?? FirebaseAuth.instance;
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.backendBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = auth.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  return dio;
}
