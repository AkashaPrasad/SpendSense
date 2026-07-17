/// Mirrors the backend's `ExpenseCategory` Postgres enum exactly — the
/// string values (not the Dart identifiers) are what cross the wire.
enum ExpenseCategory {
  food('FOOD', 'Food', isIncome: false),
  groceries('GROCERIES', 'Groceries', isIncome: false),
  transport('TRANSPORT', 'Transport', isIncome: false),
  shopping('SHOPPING', 'Shopping', isIncome: false),
  entertainment('ENTERTAINMENT', 'Entertainment', isIncome: false),
  billsUtilities('BILLS_UTILITIES', 'Bills & Utilities', isIncome: false),
  health('HEALTH', 'Health', isIncome: false),
  travel('TRAVEL', 'Travel', isIncome: false),
  education('EDUCATION', 'Education', isIncome: false),
  rentHousing('RENT_HOUSING', 'Rent & Housing', isIncome: false),
  salary('SALARY', 'Salary', isIncome: true),
  otherIncome('OTHER_INCOME', 'Other Income', isIncome: true),
  other('OTHER', 'Other', isIncome: false);

  const ExpenseCategory(
    this.apiValue,
    this.displayName, {
    required this.isIncome,
  });

  final String apiValue;
  final String displayName;
  final bool isIncome;

  static ExpenseCategory fromApi(String value) {
    return ExpenseCategory.values.firstWhere(
      (c) => c.apiValue == value,
      orElse: () => ExpenseCategory.other,
    );
  }

  static List<ExpenseCategory> get expenseCategories =>
      values.where((c) => !c.isIncome).toList(growable: false);

  static List<ExpenseCategory> get incomeCategories =>
      values.where((c) => c.isIncome).toList(growable: false);
}
