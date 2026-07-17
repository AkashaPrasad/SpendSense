import 'package:decimal/decimal.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_category.dart';
import '../../../domain/entities/expense_source.dart';
import '../../../domain/entities/line_item.dart';
import '../../../domain/entities/receipt_draft.dart';
import '../../../domain/entities/transaction_type.dart';

/// JSON <-> domain-entity mapping for the /api/expenses wire format. Kept
/// as free functions (not a Freezed/json_serializable DTO class) since the
/// shape is small and this keeps codegen surface area down.
Map<String, dynamic> expenseToCreateJson(Expense expense) {
  return {
    'clientId': expense.clientId,
    'type': expense.type.apiValue,
    'merchant': expense.merchant,
    'amount': expense.amount.toDouble(),
    'currency': expense.currency,
    'category': expense.category.apiValue,
    'date': expense.date.toUtc().toIso8601String(),
    if (expense.notes != null) 'notes': expense.notes,
    'source': expense.source.apiValue,
    if (expense.receiptImageUrl != null)
      'receiptImageUrl': expense.receiptImageUrl,
    if (expense.lineItems.isNotEmpty)
      'lineItems': expense.lineItems
          .map(
            (li) => {
              'name': li.name,
              'amount': li.amount.toDouble(),
              if (li.qty != null) 'qty': li.qty,
            },
          )
          .toList(),
  };
}

Expense expenseFromRemoteJson(
  Map<String, dynamic> json, {
  required String fallbackClientId,
}) {
  final lineItemsJson = json['lineItems'] as List<dynamic>?;
  return Expense(
    clientId: (json['clientId'] as String?) ?? fallbackClientId,
    id: json['id'] as String?,
    type: TransactionType.fromApi(json['type'] as String),
    merchant: json['merchant'] as String,
    amount: Decimal.parse(json['amount'].toString()),
    currency: json['currency'] as String? ?? 'USD',
    category: ExpenseCategory.fromApi(json['category'] as String),
    date: DateTime.parse(json['date'] as String),
    notes: json['notes'] as String?,
    source: ExpenseSource.fromApi(json['source'] as String? ?? 'MANUAL'),
    receiptImageUrl: json['receiptImageUrl'] as String?,
    lineItems: lineItemsJson == null
        ? const []
        : lineItemsJson
              .cast<Map<String, dynamic>>()
              .map(
                (li) => LineItem(
                  name: li['name'] as String,
                  amount: Decimal.parse(li['amount'].toString()),
                  qty: (li['qty'] as num?)?.toDouble(),
                ),
              )
              .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isSynced: true,
  );
}

ReceiptDraft receiptDraftFromJson(Map<String, dynamic> json) {
  final lineItemsJson = json['lineItems'] as List<dynamic>?;
  return ReceiptDraft(
    merchant: json['merchant'] as String,
    date: DateTime.parse(json['date'] as String),
    currency: json['currency'] as String? ?? 'USD',
    total: Decimal.parse(json['total'].toString()),
    suggestedCategory: ExpenseCategory.fromApi(
      json['suggestedCategory'] as String,
    ),
    lineItems: lineItemsJson == null
        ? const []
        : lineItemsJson
              .cast<Map<String, dynamic>>()
              .map(
                (li) => LineItem(
                  name: li['name'] as String,
                  amount: Decimal.parse(li['amount'].toString()),
                  qty: (li['qty'] as num?)?.toDouble(),
                ),
              )
              .toList(),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0.75,
  );
}
