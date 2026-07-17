import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendsense/core/utils/app_failure.dart';
import 'package:spendsense/core/utils/result.dart';
import 'package:spendsense/features/expenses/domain/repositories/expense_repository.dart';
import 'package:spendsense/features/expenses/domain/usecases/create_expense.dart';

import '../../../../support/expense_fixtures.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late _MockExpenseRepository repository;
  late CreateExpense useCase;

  setUpAll(() {
    registerFallbackValue(buildExpense());
  });

  setUp(() {
    repository = _MockExpenseRepository();
    useCase = CreateExpense(repository);
  });

  test('rejects an invalid expense without calling the repository', () async {
    final invalid = buildExpense(amount: '0');

    final result = await useCase(invalid);

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => repository.createExpense(any()));
  });

  test('saves a valid expense via the repository', () async {
    final expense = buildExpense();
    when(
      () => repository.createExpense(expense),
    ).thenAnswer((_) async => Result.ok(expense));

    final result = await useCase(expense);

    expect(result.isOk, isTrue);
    expect(result.valueOrNull?.amount, Decimal.parse('4.50'));
    verify(() => repository.createExpense(expense)).called(1);
  });
}
