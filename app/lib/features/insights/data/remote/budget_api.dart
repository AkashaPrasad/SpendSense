import 'package:dio/dio.dart';

class BudgetApi {
  BudgetApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listBudgets({
    int? month,
    int? year,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/budgets',
      queryParameters: {'month': ?month, 'year': ?year},
    );
    return (response.data!['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> upsertBudget(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/budgets',
      data: body,
    );
    return response.data!;
  }

  Future<void> deleteBudget(String id) => _dio.delete('/api/budgets/$id');
}
