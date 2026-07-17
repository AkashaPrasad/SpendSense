import 'package:dio/dio.dart';

/// Thin wrapper over /api/expenses and /api/ocr. Returns raw JSON maps —
/// mapping into domain entities happens in the repository, via
/// [expenseFromRemoteJson] / [expenseToCreateJson].
class ExpenseApi {
  ExpenseApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listExpenses({
    String? updatedSince,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/expenses',
      queryParameters: {'updatedSince': ?updatedSince, 'limit': 200},
    );
    return (response.data!['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createOrSyncExpense(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/expenses',
      data: body,
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> updateExpense(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/expenses/$id',
      data: body,
    );
    return response.data!;
  }

  Future<void> deleteExpense(String id) => _dio.delete('/api/expenses/$id');

  Future<List<Map<String, dynamic>>> syncBatch(
    List<Map<String, dynamic>> expenses,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/expenses/sync',
      data: {'expenses': expenses},
    );
    return (response.data!['synced'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> extractReceipt({
    required List<int> bytes,
    required String mimeType,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'receipt': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/ocr',
      data: formData,
    );
    return response.data!['draft'] as Map<String, dynamic>;
  }
}
