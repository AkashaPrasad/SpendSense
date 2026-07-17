import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'budget_vs_actual.dart';
import 'category_summary.dart';
import 'trend_point.dart';

class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.categorySummary,
    required this.trend,
    required this.budgetVsActual,
    required this.totalExpense,
    required this.totalIncome,
  });

  final List<CategorySummary> categorySummary;
  final List<TrendPoint> trend;
  final List<BudgetVsActual> budgetVsActual;
  final Decimal totalExpense;
  final Decimal totalIncome;

  @override
  List<Object?> get props => [
    categorySummary,
    trend,
    budgetVsActual,
    totalExpense,
    totalIncome,
  ];
}
