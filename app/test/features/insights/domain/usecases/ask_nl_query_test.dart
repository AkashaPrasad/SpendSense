import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendsense/core/utils/app_failure.dart';
import 'package:spendsense/core/utils/result.dart';
import 'package:spendsense/features/insights/domain/entities/query_result.dart';
import 'package:spendsense/features/insights/domain/repositories/insights_repository.dart';
import 'package:spendsense/features/insights/domain/usecases/ask_nl_query.dart';

class _MockInsightsRepository extends Mock implements InsightsRepository {}

/// This is the client-side half of the NL-query pipeline: input validation
/// before ever hitting the network. The actual "parsing" (Gemini
/// function-calling -> structured intent -> deterministic aggregation) is
/// backend logic, unit tested separately in backend/test with the LLM call
/// mocked out (see nlQuery.service.test.ts).
void main() {
  late _MockInsightsRepository repository;
  late AskNlQuery useCase;

  setUp(() {
    repository = _MockInsightsRepository();
    useCase = AskNlQuery(repository);
  });

  test(
    'rejects a question that is too short without calling the backend',
    () async {
      final result = await useCase('hi');

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(() => repository.askQuestion(any()));
    },
  );

  test('rejects a question over 500 characters', () async {
    final tooLong = 'a' * 501;

    final result = await useCase(tooLong);

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('trims the question and forwards it to the repository', () async {
    const answer = QueryResult(answer: 'You spent \$142 on food last month.');
    when(
      () => repository.askQuestion('how much on food last month?'),
    ).thenAnswer((_) async => const Result.ok(answer));

    final result = await useCase('  how much on food last month?  ');

    expect(result.valueOrNull, answer);
    verify(
      () => repository.askQuestion('how much on food last month?'),
    ).called(1);
  });
}
