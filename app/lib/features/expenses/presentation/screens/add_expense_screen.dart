import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_source.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/expense_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.expense});

  final Expense? expense;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  static const _uuid = Uuid();

  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late TransactionType _type;
  late ExpenseCategory _category;
  late DateTime _date;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _merchantController = TextEditingController(text: e?.merchant ?? '');
    _amountController = TextEditingController(
      text: e != null ? e.amount.toString() : '',
    );
    _notesController = TextEditingController(text: e?.notes ?? '');
    _type = e?.type ?? TransactionType.expense;
    _category = e?.category ?? ExpenseCategory.food;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<ExpenseCategory> get _categoryOptions => _type == TransactionType.income
      ? ExpenseCategory.incomeCategories
      : ExpenseCategory.expenseCategories;

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      final options = type == TransactionType.income
          ? ExpenseCategory.incomeCategories
          : ExpenseCategory.expenseCategories;
      if (!options.contains(_category)) {
        _category = options.first;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = Decimal.tryParse(_amountController.text.trim());
    if (_merchantController.text.trim().isEmpty ||
        amount == null ||
        amount <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a merchant name and a valid amount.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final expense = Expense(
      clientId: widget.expense?.clientId ?? _uuid.v4(),
      id: widget.expense?.id,
      type: _type,
      merchant: _merchantController.text.trim(),
      amount: amount,
      currency: widget.expense?.currency ?? 'USD',
      category: _category,
      date: _date,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      source: widget.expense?.source ?? ExpenseSource.manual,
      receiptImageUrl: widget.expense?.receiptImageUrl,
      lineItems: widget.expense?.lineItems ?? const [],
      createdAt: widget.expense?.createdAt ?? now,
      updatedAt: now,
    );

    final controller = ref.read(expenseControllerProvider.notifier);
    final ok = _isEditing
        ? await controller.updateExpense(expense)
        : await controller.createExpense(expense);

    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Couldn\'t save that expense.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(expenseControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit expense' : 'Add expense')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => _onTypeChanged(s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _merchantController,
              decoration: InputDecoration(
                labelText: _type == TransactionType.income
                    ? 'Source'
                    : 'Merchant',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categoryOptions
                  .map(
                    (c) =>
                        DropdownMenuItem(value: c, child: Text(c.displayName)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: Text(DateFormat.yMMMd().format(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
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
                  : Text(_isEditing ? 'Save changes' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
