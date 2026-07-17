import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

class TrendPoint extends Equatable {
  const TrendPoint({required this.label, required this.total});

  final String label;
  final Decimal total;

  @override
  List<Object?> get props => [label, total];
}
