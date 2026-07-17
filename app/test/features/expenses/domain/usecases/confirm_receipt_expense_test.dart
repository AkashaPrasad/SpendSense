import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendsense/core/utils/result.dart';
import 'package:spendsense/features/expenses/domain/entities/expense.dart';
import 'package:spendsense/features/expenses/domain/entities/expense_category.dart';
import 'package:spendsense/features/expenses/domain/entities/expense_source.dart';
import 'package:spendsense/features/expenses/domain/entities/receipt_draft.dart';
import 'package:spendsense/features/expenses/domain/entities/transaction_type.dart';
import 'package:spendsense/features/expenses/domain/repositories/expense_repository.dart';
import 'package:spendsense/features/expenses/domain/usecases/confirm_receipt_expense.dart';
import 'package:spendsense/features/expenses/domain/usecases/create_expense.dart';
import 'package:uuid/uuid.dart';

import '../../../../support/expense_fixtures.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late _MockExpenseRepository repository;
  late ConfirmReceiptExpense useCase;
  late Expense? captured;

  setUpAll(() {
    registerFallbackValue(buildExpense());
  });

  setUp(() {
    repository = _MockExpenseRepository();
    captured = null;
    when(() => repository.createExpense(any())).thenAnswer((invocation) async {
      captured = invocation.positionalArguments.first as Expense;
      return Result.ok(captured!);
    });
    useCase = ConfirmReceiptExpense(
      CreateExpense(repository),
      uuid: const Uuid(),
    );
  });

  final draft = ReceiptDraft(
    merchant: 'Trader Joes',
    date: DateTime(2026, 6, 1),
    total: Decimal.parse('42.15'),
    suggestedCategory: ExpenseCategory.groceries,
  );

  test('saves the draft as-is when there are no overrides', () async {
    final result = await useCase(draft: draft);

    expect(result.isOk, isTrue);
    expect(captured!.merchant, 'Trader Joes');
    expect(captured!.amount, Decimal.parse('42.15'));
    expect(captured!.category, ExpenseCategory.groceries);
    expect(captured!.source, ExpenseSource.receipt);
    expect(captured!.type, TransactionType.expense);
  });

  test('applies user corrections over the extracted draft', () async {
    await useCase(
      draft: draft,
      merchantOverride: 'Whole Foods',
      categoryOverride: ExpenseCategory.food,
      notes: 'Split with roommate',
    );

    expect(captured!.merchant, 'Whole Foods');
    expect(captured!.category, ExpenseCategory.food);
    expect(captured!.notes, 'Split with roommate');
  });
}
