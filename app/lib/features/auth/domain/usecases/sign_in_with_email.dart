import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import 'email_validation.dart';

class SignInWithEmail {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String email,
    required String password,
  }) {
    final validationError = validateEmailPassword(
      email: email,
      password: password,
    );
    if (validationError != null) {
      return Future.value(Result.err(ValidationFailure(validationError)));
    }
    return _repository.signInWithEmail(email: email.trim(), password: password);
  }
}
