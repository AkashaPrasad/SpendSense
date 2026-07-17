enum ExpenseSource {
  manual('MANUAL'),
  receipt('RECEIPT');

  const ExpenseSource(this.apiValue);

  final String apiValue;

  static ExpenseSource fromApi(String value) {
    return ExpenseSource.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => ExpenseSource.manual,
    );
  }
}
