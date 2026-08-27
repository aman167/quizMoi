import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quiz_moi_app/features/quiz_generation/data/http_quiz_generation_gateway.dart';
import 'package:quiz_moi_app/features/quiz_generation/domain/quiz_generation_models.dart';

void main() {
  final request = QuizGenerationRequest(
    requestId: 'generation-text-1',
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

    expect(result.requestId, 'generation-text-1');
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

  test(
    'classifies a dropped response as recoverable when health works',
    () async {
      final client = MockClient((received) async {
        if (received.url.path == '/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        throw http.ClientException('Connection closed while receiving data');
      });
      final gateway = HttpQuizGenerationGateway(
        baseUrl: 'http://localhost:8000',
        client: client,
      );

      expect(
        () => gateway.generate(request),
        throwsA(
          isA<QuizGenerationException>()
              .having((error) => error.code, 'code', 'response_interrupted')
              .having(
                (error) => error.message,
                'message',
                contains('Recover Result'),
              ),
        ),
      );
    },
  );

  test('uploads PDF bytes and settings as multipart data', () async {
    final client = _RecordingClient(
      _responseBody(requestId: 'generation-pdf-1'),
    );
    final gateway = HttpQuizGenerationGateway(
      baseUrl: 'http://localhost:8000',
      client: client,
    );
    final pdfBytes = Uint8List.fromList('%PDF-1.4\ntest'.codeUnits);

    final result = await gateway.generatePdf(
      PdfQuizGenerationRequest(
        requestId: 'generation-pdf-1',
        sourceTitle: 'French PDF',
        fileName: 'lesson.pdf',
        pdfBytes: pdfBytes,
        cefrLevel: 'B1',
        questionCount: 5,
      ),
    );

    final request = client.request!;
    expect(request.url.path, '/v1/quizzes/generate-pdf');
    expect(request.fields['sourceTitle'], 'French PDF');
    expect(request.fields['requestId'], 'generation-pdf-1');
    expect(request.fields['questionCount'], '5');
    expect(request.files.single.filename, 'lesson.pdf');
    expect(request.files.single.length, pdfBytes.length);
    expect(result.requestId, 'generation-pdf-1');
    expect(result.questions, hasLength(5));
  });
}

class _RecordingClient extends http.BaseClient {
  final Map<String, Object?> responseBody;
  http.MultipartRequest? request;

  _RecordingClient(this.responseBody);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request as http.MultipartRequest;
    await request.finalize().drain<void>();
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(responseBody))),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}

Map<String, Object?> _responseBody({String requestId = 'generation-text-1'}) =>
    {
      'schemaVersion': 1,
      'requestId': requestId,
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
