import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendsense/features/expenses/domain/repositories/expense_repository.dart';
import 'package:spendsense/features/expenses/domain/usecases/watch_expenses.dart';

import '../../../../support/expense_fixtures.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ExpenseFilter());
  });

  test('sorts expenses newest-first regardless of repository order', () async {
    final repository = _MockExpenseRepository();
    final oldest = buildExpense(clientId: 'a', date: DateTime(2026, 1, 1));
    final newest = buildExpense(clientId: 'b', date: DateTime(2026, 6, 1));
    final middle = buildExpense(clientId: 'c', date: DateTime(2026, 3, 1));

    when(
      () => repository.watchExpenses(any()),
    ).thenAnswer((_) => Stream.value([oldest, newest, middle]));

    final useCase = WatchExpenses(repository);
    final result = await useCase().first;

    expect(result.map((e) => e.clientId).toList(), ['b', 'c', 'a']);
  });
}
