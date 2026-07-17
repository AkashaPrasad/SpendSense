import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendsense/core/utils/result.dart';
import 'package:spendsense/features/insights/domain/entities/dashboard_summary.dart';
import 'package:spendsense/features/insights/domain/repositories/insights_repository.dart';
import 'package:spendsense/features/insights/domain/usecases/get_dashboard_summary.dart';

class _MockInsightsRepository extends Mock implements InsightsRepository {}

void main() {
  test('defaults to the current calendar month/year when omitted', () async {
    final repository = _MockInsightsRepository();
    final summary = DashboardSummary(
      categorySummary: const [],
      trend: const [],
      budgetVsActual: const [],
      totalExpense: Decimal.zero,
      totalIncome: Decimal.zero,
    );
    final now = DateTime.now();
    when(
      () => repository.getDashboardSummary(
        month: now.month,
        year: now.year,
        trendMonths: 6,
      ),
    ).thenAnswer((_) async => Result.ok(summary));

    final result = await GetDashboardSummary(repository)();

    expect(result.isOk, isTrue);
    verify(
      () => repository.getDashboardSummary(
        month: now.month,
        year: now.year,
        trendMonths: 6,
      ),
    ).called(1);
  });

  test('passes through explicit month/year/trendMonths', () async {
    final repository = _MockInsightsRepository();
    final summary = DashboardSummary(
      categorySummary: const [],
      trend: const [],
      budgetVsActual: const [],
      totalExpense: Decimal.zero,
      totalIncome: Decimal.zero,
    );
    when(
      () =>
          repository.getDashboardSummary(month: 3, year: 2025, trendMonths: 12),
    ).thenAnswer((_) async => Result.ok(summary));

    await GetDashboardSummary(repository)(
      month: 3,
      year: 2025,
      trendMonths: 12,
    );

    verify(
      () =>
          repository.getDashboardSummary(month: 3, year: 2025, trendMonths: 12),
    ).called(1);
  });
}
