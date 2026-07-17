import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/app_failure.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
FirebaseAuthDatasource firebaseAuthDatasource(Ref ref) =>
    FirebaseAuthDatasource();

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(firebaseAuthDatasourceProvider));

/// Emits the signed-in user (or null) — drives the router's redirect logic.
@Riverpod(keepAlive: true)
Stream<AppUser?> authState(Ref ref) =>
    ref.watch(authRepositoryProvider).watchAuthState();

/// Imperative sign-in/up/out actions with loading + error state for forms.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final useCase = SignInWithEmail(ref.read(authRepositoryProvider));
    final result = await useCase(email: email, password: password);
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

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final useCase = SignUpWithEmail(ref.read(authRepositoryProvider));
    final result = await useCase(email: email, password: password);
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

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    final useCase = SignInWithGoogle(ref.read(authRepositoryProvider));
    final result = await useCase();
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

  Future<void> signOut() async {
    final useCase = SignOut(ref.read(authRepositoryProvider));
    await useCase();
  }

  /// Reads the current AppFailure message out of an AsyncError state, if any.
  String? get errorMessage {
    final error = state.error;
    return error is AppFailure ? error.message : null;
  }
}
