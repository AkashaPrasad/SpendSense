import 'package:decimal/decimal.dart';
import '../../../../expenses/domain/entities/expense_category.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/budget_vs_actual.dart';
import '../../../domain/entities/category_summary.dart';
import '../../../domain/entities/chart_spec.dart';
import '../../../domain/entities/query_result.dart';
import '../../../domain/entities/trend_point.dart';

CategorySummary categorySummaryFromJson(Map<String, dynamic> json) =>
    CategorySummary(
      category: ExpenseCategory.fromApi(json['category'] as String),
      total: Decimal.parse(json['total'].toString()),
    );

TrendPoint trendPointFromJson(Map<String, dynamic> json) => TrendPoint(
  label: json['label'] as String,
  total: Decimal.parse(json['total'].toString()),
);

BudgetVsActual budgetVsActualFromJson(Map<String, dynamic> json) =>
    BudgetVsActual(
      category: ExpenseCategory.fromApi(json['category'] as String),
      budget: Decimal.parse(json['budget'].toString()),
      actual: Decimal.parse(json['actual'].toString()),
    );

Budget budgetFromJson(Map<String, dynamic> json) => Budget(
  id: json['id'] as String?,
  category: ExpenseCategory.fromApi(json['category'] as String),
  monthlyLimit: Decimal.parse(json['monthlyLimit'].toString()),
  month: json['month'] as int,
  year: json['year'] as int,
);

Map<String, dynamic> budgetToJson(Budget budget) => {
  'category': budget.category.apiValue,
  'monthlyLimit': budget.monthlyLimit.toDouble(),
  'month': budget.month,
  'year': budget.year,
};

ChartType _chartTypeFromApi(String value) => switch (value) {
  'line' => ChartType.line,
  'pie' => ChartType.pie,
  _ => ChartType.bar,
};

ChartSpec? chartSpecFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return ChartSpec(
    type: _chartTypeFromApi(json['type'] as String),
    labels: (json['labels'] as List).cast<String>(),
    series: (json['series'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (s) => ChartSeries(
            label: s['label'] as String,
            values: (s['values'] as List)
                .map((v) => (v as num).toDouble())
                .toList(),
          ),
        )
        .toList(),
  );
}

QueryResult queryResultFromJson(Map<String, dynamic> json) => QueryResult(
  answer: json['answer'] as String,
  chart: chartSpecFromJson(json['chart'] as Map<String, dynamic>?),
);
