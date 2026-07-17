import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  /// Emits the signed-in user, or null when signed out. Emits immediately
  /// with the current state on subscription.
  Stream<AppUser?> watchAuthState();

  AppUser? get currentUser;

  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signInWithGoogle();

  Future<Result<void>> signOut();
}
