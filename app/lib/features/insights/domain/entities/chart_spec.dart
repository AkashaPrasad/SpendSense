import 'package:equatable/equatable.dart';

enum ChartType { bar, line, pie }

class ChartSeries extends Equatable {
  const ChartSeries({required this.label, required this.values});

  final String label;
  final List<double> values;

  @override
  List<Object?> get props => [label, values];
}

class ChartSpec extends Equatable {
  const ChartSpec({
    required this.type,
    required this.labels,
    required this.series,
  });

  final ChartType type;
  final List<String> labels;
  final List<ChartSeries> series;

  @override
  List<Object?> get props => [type, labels, series];
}
