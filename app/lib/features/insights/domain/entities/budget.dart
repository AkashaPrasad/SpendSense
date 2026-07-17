import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../expenses/domain/entities/expense_category.dart';

class Budget extends Equatable {
  const Budget({
    this.id,
    required this.category,
    required this.monthlyLimit,
    required this.month,
    required this.year,
  });

  final String? id;
  final ExpenseCategory category;
  final Decimal monthlyLimit;
  final int month;
  final int year;

  @override
  List<Object?> get props => [id, category, monthlyLimit, month, year];
}
