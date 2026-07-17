import 'package:equatable/equatable.dart';
import 'chart_spec.dart';

/// The answer to a natural-language question, as returned by
/// POST /api/query — plain-English text plus an optional chart to render.
class QueryResult extends Equatable {
  const QueryResult({required this.answer, this.chart});

  final String answer;
  final ChartSpec? chart;

  @override
  List<Object?> get props => [answer, chart];
}
