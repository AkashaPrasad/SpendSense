import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final FirebaseAuthDatasource _datasource;

  AppUser? _toAppUser(fb.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  @override
  Stream<AppUser?> watchAuthState() =>
      _datasource.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_datasource.currentUser);

  @override
  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _run(() => _datasource.signInWithEmail(email, password));
  }

  @override
  Future<Result<AppUser>> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _run(() => _datasource.signUpWithEmail(email, password));
  }

  @override
  Future<Result<AppUser>> signInWithGoogle() {
    return _run(() => _datasource.signInWithGoogle());
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _datasource.signOut();
      return const Result.ok(null);
    } catch (e) {
      return Result.err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<AppUser>> _run(Future<fb.User> Function() action) async {
    try {
      final user = await action();
      return Result.ok(_toAppUser(user)!);
    } on fb.FirebaseAuthException catch (e) {
      return Result.err(_mapAuthException(e));
    } catch (e) {
      return Result.err(UnknownFailure(e.toString()));
    }
  }

  AppFailure _mapAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const ValidationFailure('Incorrect email or password.');
      case 'email-already-in-use':
        return const ValidationFailure(
          'An account already exists with that email.',
        );
      case 'weak-password':
        return const ValidationFailure(
          'Choose a stronger password (at least 6 characters).',
        );
      case 'invalid-email':
        return const ValidationFailure('Enter a valid email address.');
      case 'network-request-failed':
        return const NetworkFailure();
      case 'too-many-requests':
        return const RateLimitedFailure(
          'Too many attempts. Please wait and try again.',
        );
      case 'cancelled':
        return const UnknownFailure('Sign-in was cancelled.');
      default:
        return UnknownFailure(e.message ?? 'Authentication failed.');
    }
  }
}
