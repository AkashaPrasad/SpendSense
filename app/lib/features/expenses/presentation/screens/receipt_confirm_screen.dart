import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/receipt_draft.dart';
import '../providers/expense_providers.dart';

class ReceiptConfirmArgs {
  const ReceiptConfirmArgs({required this.draft, required this.imageBytes});

  final ReceiptDraft draft;
  final Uint8List imageBytes;
}

/// The mandatory "user confirms before saving" step — nothing Gemini
/// extracts from a receipt is written to the database until this screen's
/// Confirm button is pressed.
class ReceiptConfirmScreen extends ConsumerStatefulWidget {
  const ReceiptConfirmScreen({super.key, required this.args});

  final ReceiptConfirmArgs args;

  @override
  ConsumerState<ReceiptConfirmScreen> createState() =>
      _ReceiptConfirmScreenState();
}

class _ReceiptConfirmScreenState extends ConsumerState<ReceiptConfirmScreen> {
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late ExpenseCategory _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final draft = widget.args.draft;
    _merchantController = TextEditingController(text: draft.merchant);
    _amountController = TextEditingController(text: draft.total.toString());
    _category = draft.suggestedCategory;
    _date = draft.date;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
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

  Future<void> _confirm() async {
    final amount = Decimal.tryParse(_amountController.text.trim());
    if (_merchantController.text.trim().isEmpty ||
        amount == null ||
        amount <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a merchant name and a valid total.'),
        ),
      );
      return;
    }

    final draft = widget.args.draft;
    final adjustedDraft = ReceiptDraft(
      merchant: _merchantController.text.trim(),
      date: _date,
      currency: draft.currency,
      total: amount,
      suggestedCategory: _category,
      lineItems: draft.lineItems,
      confidence: draft.confidence,
    );

    final controller = ref.read(expenseControllerProvider.notifier);
    final ok = await controller.confirmReceipt(draft: adjustedDraft);

    if (!mounted) return;
    if (ok) {
      context.go('/expenses');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Couldn\'t save that receipt.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.args.draft;
    final isSaving = ref.watch(expenseControllerProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm receipt')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                widget.args.imageBytes,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Extracted automatically — review before saving',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _merchantController,
              decoration: const InputDecoration(labelText: 'Merchant'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Total',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ExpenseCategory.expenseCategories
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
            if (draft.lineItems.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Line items', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: draft.lineItems
                        .map(
                          (item) => ListTile(
                            dense: true,
                            title: Text(item.name),
                            trailing: Text(
                              formatMoney(
                                item.amount,
                                currency: draft.currency,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSaving ? null : _confirm,
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirm & save'),
            ),
          ],
        ),
      ),
    );
  }
}
