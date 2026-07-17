import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../expenses/domain/entities/expense_category.dart';

class BudgetVsActual extends Equatable {
  const BudgetVsActual({
    required this.category,
    required this.budget,
    required this.actual,
  });

  final ExpenseCategory category;
  final Decimal budget;
  final Decimal actual;

  bool get isOverBudget => actual > budget;

  /// 0.0–1.0+ (can exceed 1.0 when over budget).
  double get percentUsed {
    if (budget == Decimal.zero) return actual > Decimal.zero ? 1.0 : 0.0;
    return (actual.toDouble() / budget.toDouble());
  }

  @override
  List<Object?> get props => [category, budget, actual];
}
