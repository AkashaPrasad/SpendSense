enum TransactionType {
  expense('EXPENSE'),
  income('INCOME');

  const TransactionType(this.apiValue);

  final String apiValue;

  static TransactionType fromApi(String value) {
    return TransactionType.values.firstWhere(
      (t) => t.apiValue == value,
      orElse: () => TransactionType.expense,
    );
  }
}
