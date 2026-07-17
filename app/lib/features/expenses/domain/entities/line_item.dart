import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

class LineItem extends Equatable {
  const LineItem({required this.name, required this.amount, this.qty});

  final String name;
  final Decimal amount;
  final double? qty;

  @override
  List<Object?> get props => [name, amount, qty];
}
