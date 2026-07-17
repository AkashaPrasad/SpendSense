import 'package:decimal/decimal.dart';
import '../../../../core/network/network_exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/query_result.dart';
import '../../domain/repositories/insights_repository.dart';
import '../remote/dto/insights_mapper.dart';
import '../remote/insights_api.dart';

class InsightsRepositoryImpl implements InsightsRepository {
  InsightsRepositoryImpl(this._api);

  final InsightsApi _api;

  @override
  Future<Result<DashboardSummary>> getDashboardSummary({
    required int month,
    required int year,
    int trendMonths = 6,
  }) async {
    try {
      final results = await Future.wait([
        _api.categorySummary(month, year),
        _api.trend(trendMonths),
        _api.budgetVsActual(month, year),
        _api.incomeVsExpense(month, year),
      ]);

      final categorySummary = (results[0]['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(categorySummaryFromJson)
          .toList();
      final trend = (results[1]['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(trendPointFromJson)
          .toList();
      final budgetVsActual = (results[2]['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(budgetVsActualFromJson)
          .toList();
      final incomeExpense = results[3];

      return Result.ok(
        DashboardSummary(
          categorySummary: categorySummary,
          trend: trend,
          budgetVsActual: budgetVsActual,
          totalExpense: Decimal.parse(incomeExpense['expense'].toString()),
          totalIncome: Decimal.parse(incomeExpense['income'].toString()),
        ),
      );
    } catch (e) {
      return Result.err(mapDioException(e));
    }
  }

  @override
  Future<Result<QueryResult>> askQuestion(String question) async {
    try {
      final json = await _api.askQuery(question);
      return Result.ok(queryResultFromJson(json));
    } catch (e) {
      return Result.err(mapDioException(e));
    }
  }
}
