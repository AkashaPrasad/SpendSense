import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../expenses/domain/entities/expense_category.dart';
import '../../domain/entities/budget.dart';
import '../providers/insights_providers.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  Future<void> _openBudgetSheet({Budget? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BudgetSheet(month: _month, existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(
      budgetsListProvider(month: _month.month, year: _month.year),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBudgetSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Set budget'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  ),
                ),
                Text(
                  DateFormat.yMMMM().format(_month),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month + 1),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueWidget(
              value: budgetsAsync,
              onRetry: () => ref.invalidate(budgetsListProvider),
              data: (budgets) {
                if (budgets.isEmpty) {
                  return EmptyState(
                    icon: Icons.pie_chart_outline,
                    title: 'No budgets for ${DateFormat.MMMM().format(_month)}',
                    message:
                        'Set a monthly limit per category to track overspending.',
                    actionLabel: 'Set budget',
                    onAction: () => _openBudgetSheet(),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: budgets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    return Card(
                      child: ListTile(
                        title: Text(budget.category.displayName),
                        subtitle: Text(
                          '${formatMoney(budget.monthlyLimit)} / month',
                        ),
                        onTap: () => _openBudgetSheet(existing: budget),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (budget.id == null) return;
                            await ref
                                .read(budgetControllerProvider.notifier)
                                .deleteBudget(budget.id!);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet({required this.month, this.existing});

  final DateTime month;
  final Budget? existing;

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  late ExpenseCategory _category;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _category =
        widget.existing?.category ?? ExpenseCategory.expenseCategories.first;
    _amountController = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.monthlyLimit.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = Decimal.tryParse(_amountController.text.trim());
    if (amount == null || amount <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid monthly limit.')),
      );
      return;
    }
    final budget = Budget(
      id: widget.existing?.id,
      category: _category,
      monthlyLimit: amount,
      month: widget.month.month,
      year: widget.month.year,
    );
    final controller = ref.read(budgetControllerProvider.notifier);
    final ok = await controller.setBudget(budget);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Couldn\'t save that budget.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(budgetControllerProvider).isLoading;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing != null ? 'Edit budget' : 'Set a budget',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ExpenseCategory.expenseCategories
                .map(
                  (c) => DropdownMenuItem(value: c, child: Text(c.displayName)),
                )
                .toList(),
            onChanged: widget.existing != null
                ? null
                : (value) => setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Monthly limit',
              prefixText: '\$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
