import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quiz_moi_app/features/quiz_generation/data/http_quiz_generation_gateway.dart';
import 'package:quiz_moi_app/features/quiz_generation/domain/quiz_generation_models.dart';

void main() {
  final request = QuizGenerationRequest(
    sourceTitle: 'French text',
    sourceText: List.filled(20, 'Marie prend le train chaque matin.').join(' '),
    cefrLevel: 'B1',
    questionCount: 5,
  );

  test('parses a valid generated quiz contract', () async {
    final client = MockClient((http.Request received) async {
      expect(received.url.path, '/v1/quizzes/generate');
      expect(jsonDecode(received.body)['questionCount'], 5);
      return http.Response(jsonEncode(_responseBody()), 200);
    });
    final gateway = HttpQuizGenerationGateway(
      baseUrl: 'http://localhost:8000',
      client: client,
    );

    final result = await gateway.generate(request);

    expect(result.requestId, 'request-1');
    expect(result.questions, hasLength(5));
    expect(result.questions.first.correctOptionId, 'a');
  });

  test('preserves stable backend error code and message', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'detail': {
            'code': 'backend_not_configured',
            'message': 'Configure OPENAI_API_KEY.',
          },
        }),
        503,
      ),
    );
    final gateway = HttpQuizGenerationGateway(
      baseUrl: 'http://localhost:8000',
      client: client,
    );

    expect(
      () => gateway.generate(request),
      throwsA(
        isA<QuizGenerationException>()
            .having((error) => error.code, 'code', 'backend_not_configured')
            .having(
              (error) => error.message,
              'message',
              'Configure OPENAI_API_KEY.',
            ),
      ),
    );
  });
}

Map<String, Object?> _responseBody() => {
  'schemaVersion': 1,
  'requestId': 'request-1',
  'title': 'Le trajet de Marie',
  'questions': List.generate(
    5,
    (index) => {
      'prompt': 'Question ${index + 1}',
      'options': const [
        {'id': 'a', 'text': 'En train'},
        {'id': 'b', 'text': 'En avion'},
        {'id': 'c', 'text': 'À vélo'},
        {'id': 'd', 'text': 'À pied'},
      ],
      'correctOptionId': 'a',
      'explanation': 'Le texte donne la réponse.',
      'sourceExcerpt': 'Marie prend le train chaque matin.',
      'concepts': const [
        {'name': 'Les transports', 'category': 'vocabulary'},
      ],
    },
  ),
};
