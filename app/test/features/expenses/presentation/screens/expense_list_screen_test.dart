import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsense/features/expenses/domain/repositories/expense_repository.dart';
import 'package:spendsense/features/expenses/presentation/providers/expense_providers.dart';
import 'package:spendsense/features/expenses/presentation/screens/expense_list_screen.dart';

import '../../../../support/expense_fixtures.dart';

void main() {
  testWidgets('shows an empty state when there are no expenses', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchExpensesProvider(
            const ExpenseFilter(),
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: ExpenseListScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('No expenses yet'), findsOneWidget);
  });

  testWidgets('renders one tile per expense, newest-looking data intact', (
    tester,
  ) async {
    final expenses = [
      buildExpense(
        clientId: 'a',
        merchant: 'Blue Bottle Coffee',
        amount: '5.75',
      ),
      buildExpense(clientId: 'b', merchant: 'Trader Joes', amount: '42.10'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchExpensesProvider(
            const ExpenseFilter(),
          ).overrideWith((ref) => Stream.value(expenses)),
        ],
        child: const MaterialApp(home: ExpenseListScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Blue Bottle Coffee'), findsOneWidget);
    expect(find.text('Trader Joes'), findsOneWidget);
    expect(find.text('-\$5.75'), findsOneWidget);
    expect(find.text('-\$42.10'), findsOneWidget);
  });

  testWidgets('type filter segmented control is present and switchable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchExpensesProvider(
            const ExpenseFilter(),
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: ExpenseListScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('All'), findsOneWidget);
    // "Expenses" appears twice: the AppBar title and the segment label.
    expect(find.text('Expenses'), findsNWidgets(2));
    expect(find.text('Income'), findsOneWidget);
  });
}
