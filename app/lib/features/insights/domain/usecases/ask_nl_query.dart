import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/query_result.dart';
import '../repositories/insights_repository.dart';

/// This is the client-side half of the NL-query pipeline: validate, then
/// hand off to the backend. All the actual "parsing" — Gemini function
/// calling to extract intent, then deterministic aggregation — happens
/// server-side in nlQuery.service (see backend/test for its unit tests).
class AskNlQuery {
  const AskNlQuery(this._repository);

  final InsightsRepository _repository;

  Future<Result<QueryResult>> call(String question) {
    final trimmed = question.trim();
    if (trimmed.length < 3) {
      return Future.value(
        const Result.err(ValidationFailure('Ask a more specific question.')),
      );
    }
    if (trimmed.length > 500) {
      return Future.value(
        const Result.err(ValidationFailure('That question is too long.')),
      );
    }
    return _repository.askQuestion(trimmed);
  }
}
