import 'package:dio/dio.dart';
import '../utils/app_failure.dart';

/// Translates transport-layer errors (Dio) into domain-level AppFailures so
/// nothing above the data layer needs to know Dio exists.
AppFailure mapDioException(Object error) {
  if (error is! DioException) {
    return UnknownFailure(error.toString());
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badCertificate:
      return const NetworkFailure(
        'A secure connection could not be established.',
      );
    case DioExceptionType.cancel:
      return const UnknownFailure('The request was cancelled.');
    case DioExceptionType.badResponse:
      return _mapStatusCode(error);
    case DioExceptionType.unknown:
    default:
      return const NetworkFailure();
  }
}

AppFailure _mapStatusCode(DioException error) {
  final status = error.response?.statusCode;
  final serverMessage = _extractServerMessage(error.response?.data);

  switch (status) {
    case 400:
      return ValidationFailure(
        serverMessage ?? 'Please check the details you entered.',
      );
    case 401:
      return const UnauthorizedFailure();
    case 403:
      return UnauthorizedFailure(
        serverMessage ?? 'You don\'t have access to do that.',
      );
    case 404:
      return const NotFoundFailure();
    case 429:
      return const RateLimitedFailure();
    default:
      if (status != null && status >= 500) {
        return const ServerFailure();
      }
      return UnknownFailure(serverMessage ?? 'An unexpected error occurred.');
  }
}

String? _extractServerMessage(dynamic data) {
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }
  return null;
}
