import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'expense_category.dart';
import 'expense_source.dart';
import 'line_item.dart';
import 'transaction_type.dart';

/// A single financial transaction (expense or income).
///
/// [clientId] is generated locally the moment a row is created (offline or
/// online) and never changes — it's the offline-sync idempotency key. [id]
/// is the server's id and is null until the row has synced at least once.
class Expense extends Equatable {
  const Expense({
    required this.clientId,
    this.id,
    required this.type,
    required this.merchant,
    required this.amount,
    this.currency = 'USD',
    required this.category,
    required this.date,
    this.notes,
    this.source = ExpenseSource.manual,
    this.receiptImageUrl,
    this.lineItems = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  final String clientId;
  final String? id;
  final TransactionType type;
  final String merchant;
  final Decimal amount;
  final String currency;
  final ExpenseCategory category;
  final DateTime date;
  final String? notes;
  final ExpenseSource source;
  final String? receiptImageUrl;
  final List<LineItem> lineItems;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Expense copyWith({
    String? id,
    TransactionType? type,
    String? merchant,
    Decimal? amount,
    String? currency,
    ExpenseCategory? category,
    DateTime? date,
    String? notes,
    ExpenseSource? source,
    String? receiptImageUrl,
    List<LineItem>? lineItems,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Expense(
      clientId: clientId,
      id: id ?? this.id,
      type: type ?? this.type,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      lineItems: lineItems ?? this.lineItems,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
    clientId,
    id,
    type,
    merchant,
    amount,
    currency,
    category,
    date,
    notes,
    source,
    receiptImageUrl,
    lineItems,
    createdAt,
    updatedAt,
    isSynced,
  ];
}
