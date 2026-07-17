import '../../../../core/utils/result.dart';
import '../entities/dashboard_summary.dart';
import '../repositories/insights_repository.dart';

class GetDashboardSummary {
  const GetDashboardSummary(this._repository);

  final InsightsRepository _repository;

  /// Defaults to the current calendar month when [month]/[year] are omitted.
  Future<Result<DashboardSummary>> call({
    int? month,
    int? year,
    int trendMonths = 6,
  }) {
    final now = DateTime.now();
    return _repository.getDashboardSummary(
      month: month ?? now.month,
      year: year ?? now.year,
      trendMonths: trendMonths,
    );
  }
}
