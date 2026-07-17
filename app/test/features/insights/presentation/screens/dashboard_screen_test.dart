import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsense/features/expenses/domain/entities/expense_category.dart';
import 'package:spendsense/features/insights/domain/entities/category_summary.dart';
import 'package:spendsense/features/insights/domain/entities/dashboard_summary.dart';
import 'package:spendsense/features/insights/presentation/providers/insights_providers.dart';
import 'package:spendsense/features/insights/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('renders income/spent/net summary and category legend', (
    tester,
  ) async {
    final now = DateTime.now();
    final summary = DashboardSummary(
      categorySummary: [
        CategorySummary(
          category: ExpenseCategory.food,
          total: Decimal.parse('120.00'),
        ),
        CategorySummary(
          category: ExpenseCategory.transport,
          total: Decimal.parse('80.00'),
        ),
      ],
      trend: const [],
      budgetVsActual: const [],
      totalExpense: Decimal.parse('200.00'),
      totalIncome: Decimal.parse('3000.00'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider(
            month: now.month,
            year: now.year,
          ).overrideWith((ref) async => summary),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
    expect(find.text('Net'), findsOneWidget);
    expect(find.text('\$3,000.00'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Transport'), findsWidgets);
  });

  testWidgets('shows the natural-language query bar', (tester) async {
    final now = DateTime.now();
    final summary = DashboardSummary(
      categorySummary: const [],
      trend: const [],
      budgetVsActual: const [],
      totalExpense: Decimal.zero,
      totalIncome: Decimal.zero,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider(
            month: now.month,
            year: now.year,
          ).overrideWith((ref) async => summary),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Ask about your spending…'), findsOneWidget);
  });
}
