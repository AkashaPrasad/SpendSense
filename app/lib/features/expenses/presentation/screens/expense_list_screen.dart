import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/expense_repository.dart';
import '../providers/expense_providers.dart';
import '../widgets/expense_tile.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

enum _TypeFilter { all, expense, income }

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  _TypeFilter _typeFilter = _TypeFilter.all;

  ExpenseFilter get _filter {
    return ExpenseFilter(
      type: switch (_typeFilter) {
        _TypeFilter.all => null,
        _TypeFilter.expense => TransactionType.expense,
        _TypeFilter.income => TransactionType.income,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(watchExpensesProvider(_filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: SegmentedButton<_TypeFilter>(
              segments: const [
                ButtonSegment(value: _TypeFilter.all, label: Text('All')),
                ButtonSegment(
                  value: _TypeFilter.expense,
                  label: Text('Expenses'),
                ),
                ButtonSegment(value: _TypeFilter.income, label: Text('Income')),
              ],
              selected: {_typeFilter},
              onSelectionChanged: (selection) =>
                  setState(() => _typeFilter = selection.first),
            ),
          ),
        ),
      ),
      body: AsyncValueWidget(
        value: expensesAsync,
        data: (expenses) {
          if (expenses.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No expenses yet',
              message:
                  'Tap the + button to add one manually or scan a receipt.',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(expenseRepositoryProvider).syncPendingExpenses(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: expenses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return Dismissible(
                  key: ValueKey(expense.clientId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context),
                  onDismissed: (_) => ref
                      .read(expenseControllerProvider.notifier)
                      .deleteExpense(expense.clientId),
                  child: ExpenseTile(
                    expense: expense,
                    onTap: () => context.push('/add-expense', extra: expense),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
