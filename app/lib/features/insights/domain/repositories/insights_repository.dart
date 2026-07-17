import '../../../../core/utils/result.dart';
import '../entities/dashboard_summary.dart';
import '../entities/query_result.dart';

abstract class InsightsRepository {
  Future<Result<DashboardSummary>> getDashboardSummary({
    required int month,
    required int year,
    int trendMonths = 6,
  });

  /// Sends a free-form question to POST /api/query — the backend runs the
  /// Gemini function-calling step and the deterministic aggregation, and
  /// returns a plain-English answer plus chart data.
  Future<Result<QueryResult>> askQuestion(String question);
}
