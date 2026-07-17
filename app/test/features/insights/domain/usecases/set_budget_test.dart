import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendsense/core/utils/app_failure.dart';
import 'package:spendsense/core/utils/result.dart';
import 'package:spendsense/features/expenses/domain/entities/expense_category.dart';
import 'package:spendsense/features/insights/domain/entities/budget.dart';
import 'package:spendsense/features/insights/domain/repositories/budget_repository.dart';
import 'package:spendsense/features/insights/domain/usecases/set_budget.dart';

class _MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late _MockBudgetRepository repository;
  late SetBudget useCase;

  setUpAll(() {
    registerFallbackValue(
      Budget(
        category: ExpenseCategory.other,
        monthlyLimit: Decimal.one,
        month: 1,
        year: 2000,
      ),
    );
  });

  setUp(() {
    repository = _MockBudgetRepository();
    useCase = SetBudget(repository);
  });

  test('rejects a zero or negative limit', () async {
    final budget = Budget(
      category: ExpenseCategory.food,
      monthlyLimit: Decimal.zero,
      month: 6,
      year: 2026,
    );

    final result = await useCase(budget);

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => repository.setBudget(any()));
  });

  test('rejects an out-of-range month', () async {
    final budget = Budget(
      category: ExpenseCategory.food,
      monthlyLimit: Decimal.fromInt(100),
      month: 13,
      year: 2026,
    );

    final result = await useCase(budget);

    expect(result.isErr, isTrue);
  });

  test('saves a valid budget', () async {
    final budget = Budget(
      category: ExpenseCategory.food,
      monthlyLimit: Decimal.fromInt(300),
      month: 6,
      year: 2026,
    );
    when(
      () => repository.setBudget(budget),
    ).thenAnswer((_) async => Result.ok(budget));

    final result = await useCase(budget);

    expect(result.isOk, isTrue);
    verify(() => repository.setBudget(budget)).called(1);
  });
}
