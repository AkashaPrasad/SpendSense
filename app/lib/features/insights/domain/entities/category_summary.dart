import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../expenses/domain/entities/expense_category.dart';

class CategorySummary extends Equatable {
  const CategorySummary({required this.category, required this.total});

  final ExpenseCategory category;
  final Decimal total;

  @override
  List<Object?> get props => [category, total];
}
