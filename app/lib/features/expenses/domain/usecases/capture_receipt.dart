import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/receipt_draft.dart';
import '../repositories/expense_repository.dart';

const _maxReceiptBytes = 8 * 1024 * 1024;

class CaptureReceipt {
  const CaptureReceipt(this._repository);

  final ExpenseRepository _repository;

  Future<Result<ReceiptDraft>> call({
    required List<int> imageBytes,
    required String mimeType,
  }) {
    if (imageBytes.isEmpty) {
      return Future.value(
        const Result.err(ValidationFailure('No photo was captured.')),
      );
    }
    if (imageBytes.length > _maxReceiptBytes) {
      return Future.value(
        const Result.err(
          ValidationFailure('Photo is too large — try a smaller image.'),
        ),
      );
    }
    if (!mimeType.startsWith('image/')) {
      return Future.value(
        const Result.err(
          ValidationFailure('That file isn\'t a supported image type.'),
        ),
      );
    }
    return _repository.captureReceipt(
      imageBytes: imageBytes,
      mimeType: mimeType,
    );
  }
}
