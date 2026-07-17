import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class WatchExpenses {
  const WatchExpenses(this._repository);

  final ExpenseRepository _repository;

  /// Streams expenses for [filter], newest first — sorting is a business
  /// rule the UI shouldn't have to re-implement.
  Stream<List<Expense>> call([ExpenseFilter filter = const ExpenseFilter()]) {
    return _repository.watchExpenses(filter).map((expenses) {
      final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    });
  }
}
