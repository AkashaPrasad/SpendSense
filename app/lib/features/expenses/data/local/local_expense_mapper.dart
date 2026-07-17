import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_source.dart';
import '../../domain/entities/line_item.dart';
import '../../domain/entities/transaction_type.dart';
import 'app_database.dart';

Expense expenseFromRow(ExpensesTableData row) {
  final lineItemsJson = row.lineItemsJson;
  final lineItems = lineItemsJson == null
      ? const <LineItem>[]
      : (jsonDecode(lineItemsJson) as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(
              (li) => LineItem(
                name: li['name'] as String,
                amount: Decimal.parse(li['amount'].toString()),
                qty: (li['qty'] as num?)?.toDouble(),
              ),
            )
            .toList();

  return Expense(
    clientId: row.clientId,
    id: row.serverId,
    type: TransactionType.fromApi(row.type),
    merchant: row.merchant,
    amount: Decimal.parse(row.amount),
    currency: row.currency,
    category: ExpenseCategory.fromApi(row.category),
    date: row.date,
    notes: row.notes,
    source: ExpenseSource.fromApi(row.source),
    receiptImageUrl: row.receiptImageUrl,
    lineItems: lineItems,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    isSynced: row.isSynced,
  );
}

ExpensesTableCompanion expenseToCompanion(Expense expense) {
  return ExpensesTableCompanion.insert(
    clientId: expense.clientId,
    serverId: Value(expense.id),
    type: expense.type.apiValue,
    merchant: expense.merchant,
    amount: expense.amount.toString(),
    currency: Value(expense.currency),
    category: expense.category.apiValue,
    date: expense.date,
    notes: Value(expense.notes),
    source: Value(expense.source.apiValue),
    receiptImageUrl: Value(expense.receiptImageUrl),
    lineItemsJson: Value(
      expense.lineItems.isEmpty
          ? null
          : jsonEncode(
              expense.lineItems
                  .map(
                    (li) => {
                      'name': li.name,
                      'amount': li.amount.toString(),
                      'qty': li.qty,
                    },
                  )
                  .toList(),
            ),
    ),
    createdAt: expense.createdAt,
    updatedAt: expense.updatedAt,
    isSynced: Value(expense.isSynced),
  );
}
