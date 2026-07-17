import 'package:dio/dio.dart';

class InsightsApi {
  InsightsApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> categorySummary(int month, int year) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/insights/category-summary',
      queryParameters: {'month': month, 'year': year},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> trend(int months) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/insights/trend',
      queryParameters: {'months': months},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> budgetVsActual(int month, int year) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/insights/budget-vs-actual',
      queryParameters: {'month': month, 'year': year},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> incomeVsExpense(int month, int year) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/insights/income-vs-expense',
      queryParameters: {'month': month, 'year': year},
    );
    return response.data!;
  }

  /// POST /api/query — the natural-language question bar. The backend runs
  /// Gemini function-calling to extract intent, then computes the answer
  /// deterministically. This call is rate-limited server-side.
  Future<Map<String, dynamic>> askQuery(String question) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/query',
      data: {'question': question},
    );
    return response.data!;
  }
}
