import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendsense/core/utils/app_failure.dart';
import 'package:spendsense/core/utils/result.dart';
import 'package:spendsense/features/expenses/domain/entities/expense_category.dart';
import 'package:spendsense/features/expenses/domain/entities/receipt_draft.dart';
import 'package:spendsense/features/expenses/domain/repositories/expense_repository.dart';
import 'package:spendsense/features/expenses/domain/usecases/capture_receipt.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late _MockExpenseRepository repository;
  late CaptureReceipt useCase;

  setUp(() {
    repository = _MockExpenseRepository();
    useCase = CaptureReceipt(repository);
  });

  test('rejects an empty image without calling the backend', () async {
    final result = await useCase(imageBytes: const [], mimeType: 'image/jpeg');

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(
      () => repository.captureReceipt(
        imageBytes: any(named: 'imageBytes'),
        mimeType: any(named: 'mimeType'),
      ),
    );
  });

  test('rejects an oversized image', () async {
    final bytes = List<int>.filled(9 * 1024 * 1024, 0);
    final result = await useCase(imageBytes: bytes, mimeType: 'image/jpeg');

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('rejects a non-image mime type', () async {
    final result = await useCase(
      imageBytes: [1, 2, 3],
      mimeType: 'application/pdf',
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('delegates a valid image to the repository', () async {
    final draft = ReceiptDraft(
      merchant: 'Trader Joes',
      date: DateTime(2026, 6, 1),
      total: Decimal.parse('12.34'),
      suggestedCategory: ExpenseCategory.groceries,
    );
    when(
      () => repository.captureReceipt(
        imageBytes: [1, 2, 3],
        mimeType: 'image/jpeg',
      ),
    ).thenAnswer((_) async => Result.ok(draft));

    final result = await useCase(imageBytes: [1, 2, 3], mimeType: 'image/jpeg');

    expect(result.valueOrNull, draft);
  });
}
