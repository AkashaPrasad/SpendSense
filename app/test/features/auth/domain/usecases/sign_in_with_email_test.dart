import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendsense/core/utils/app_failure.dart';
import 'package:spendsense/core/utils/result.dart';
import 'package:spendsense/features/auth/domain/entities/app_user.dart';
import 'package:spendsense/features/auth/domain/repositories/auth_repository.dart';
import 'package:spendsense/features/auth/domain/usecases/sign_in_with_email.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late SignInWithEmail useCase;

  setUp(() {
    repository = _MockAuthRepository();
    useCase = SignInWithEmail(repository);
  });

  test('rejects invalid input before ever touching the repository', () async {
    final result = await useCase(email: 'not-an-email', password: '123');

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(
      () => repository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test(
    'delegates to the repository with a trimmed email on valid input',
    () async {
      const user = AppUser(id: 'u1', email: 'user@example.com');
      when(
        () => repository.signInWithEmail(
          email: 'user@example.com',
          password: 'secret1',
        ),
      ).thenAnswer((_) async => const Result.ok(user));

      final result = await useCase(
        email: '  user@example.com  ',
        password: 'secret1',
      );

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, user);
      verify(
        () => repository.signInWithEmail(
          email: 'user@example.com',
          password: 'secret1',
        ),
      ).called(1);
    },
  );

  test('surfaces a failure from the repository unchanged', () async {
    when(
      () => repository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async =>
          const Result.err(ValidationFailure('Incorrect email or password.')),
    );

    final result = await useCase(
      email: 'user@example.com',
      password: 'wrongpass',
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull?.message, 'Incorrect email or password.');
  });
}
