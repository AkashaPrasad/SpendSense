import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'expense_category.dart';
import 'line_item.dart';

/// What Gemini Vision extracted from a receipt photo — never saved as an
/// expense directly. The user must review and confirm it first.
class ReceiptDraft extends Equatable {
  const ReceiptDraft({
    required this.merchant,
    required this.date,
    this.currency = 'USD',
    required this.total,
    required this.suggestedCategory,
    this.lineItems = const [],
    this.confidence = 0.75,
  });

  final String merchant;
  final DateTime date;
  final String currency;
  final Decimal total;
  final ExpenseCategory suggestedCategory;
  final List<LineItem> lineItems;
  final double confidence;

  @override
  List<Object?> get props => [
    merchant,
    date,
    currency,
    total,
    suggestedCategory,
    lineItems,
    confidence,
  ];
}
