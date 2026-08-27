import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:quiz_moi_app/features/quiz_generation/domain/quiz_generation_gateway.dart';
import 'package:quiz_moi_app/features/quiz_generation/presentation/state/quiz_generation_provider.dart';
import 'package:quiz_moi_app/features/quiz_generation/domain/quiz_generation_models.dart';

import '../../support/fake_quiz_generation_gateway.dart';

void main() {
  test('rejects short text without calling the backend', () {
    final gateway = FakeQuizGenerationGateway();
    final provider = QuizGenerationProvider(gateway: gateway);

    expect(provider.prepareSource(text: 'Bonjour', cefrLevel: 'B1'), isFalse);
    expect(provider.state, QuizGenerationState.failure);
    expect(provider.errorCode, 'invalid_source');
    expect(gateway.callCount, 0);
  });

  test('maps generated output to a source-linked editable quiz', () async {
    final now = DateTime.utc(2026, 8, 17, 19);
    final gateway = FakeQuizGenerationGateway();
    final provider = QuizGenerationProvider(gateway: gateway, now: () => now);
    final sourceText = List.filled(
      12,
      'Marie prend le train chaque matin pour aller à son travail.',
    ).join(' ');

    expect(provider.prepareSource(text: sourceText, cefrLevel: 'B1'), isTrue);
    expect(provider.state, QuizGenerationState.previewing);
    expect(await provider.generate(), isTrue);

    expect(gateway.callCount, 1);
    expect(provider.state, QuizGenerationState.reviewing);
    expect(provider.sourceDocument!.content, sourceText);
    expect(provider.draftQuiz!.questions, hasLength(10));
    expect(provider.draftQuiz!.sourceDocumentId, provider.sourceDocument!.id);
    expect(
      provider.draftQuiz!.questions.first.explanation!.sourceExcerpt,
      'Marie prend le train chaque matin',
    );
  });

  test('keeps the request available after a recoverable failure', () async {
    final gateway = FakeQuizGenerationGateway(
      error: const QuizGenerationException(
        'backend_unavailable',
        'Start the local server.',
      ),
    );
    final provider = QuizGenerationProvider(gateway: gateway);
    final sourceText = List.filled(20, 'Une phrase française utile.').join(' ');

    provider.prepareSource(text: sourceText, cefrLevel: 'A2');
    expect(await provider.generate(), isFalse);

    expect(provider.state, QuizGenerationState.failure);
    expect(provider.canRetry, isTrue);
    expect(provider.request!.sourceText, sourceText);
  });

  test('reuses the same request id when recovering a lost response', () async {
    final gateway = _FailOnceGateway();
    final provider = QuizGenerationProvider(gateway: gateway);
    final sourceText = List.filled(20, 'Une phrase française utile.').join(' ');

    provider.prepareSource(text: sourceText, cefrLevel: 'A2');
    expect(await provider.generate(), isFalse);
    expect(provider.errorCode, 'response_interrupted');
    expect(await provider.generate(), isTrue);

    expect(gateway.requestIds, hasLength(2));
    expect(gateway.requestIds.toSet(), hasLength(1));
  });

  test('maps a generated PDF quiz to PDF source metadata', () async {
    final gateway = FakeQuizGenerationGateway();
    final provider = QuizGenerationProvider(gateway: gateway);

    expect(
      provider.preparePdf(
        sourceTitle: 'Une leçon française',
        fileName: 'lecon.pdf',
        pdfBytes: Uint8List.fromList('%PDF-1.4\ntest'.codeUnits),
        cefrLevel: 'B1',
      ),
      isTrue,
    );
    expect(await provider.generate(), isTrue);

    expect(provider.sourceDocument!.type, SourceType.pdf);
    expect(provider.sourceDocument!.title, 'Une leçon française');
    expect(provider.sourceDocument!.content, 'PDF source: lecon.pdf');
    expect(provider.draftQuiz!.questions, hasLength(10));
  });

  test('retrieves and maps a web article with its source URL', () async {
    final gateway = FakeQuizGenerationGateway();
    final provider = QuizGenerationProvider(gateway: gateway);

    expect(
      await provider.prepareWebArticle(
        url: 'https://example.com/fr/bibliotheque',
        cefrLevel: 'B1',
      ),
      isTrue,
    );
    expect(provider.state, QuizGenerationState.previewing);
    expect(gateway.previewCallCount, 1);
    expect(await provider.generate(), isTrue);

    expect(provider.sourceDocument!.type, SourceType.webArticle);
    expect(
      provider.sourceDocument!.sourceUri,
      'https://example.com/fr/bibliotheque',
    );
    expect(provider.sourceDocument!.content, contains('bibliothèque'));
    expect(provider.draftQuiz!.questions, hasLength(10));
  });

  test(
    'rejects an incomplete web article URL before calling backend',
    () async {
      final gateway = FakeQuizGenerationGateway();
      final provider = QuizGenerationProvider(gateway: gateway);

      expect(
        await provider.prepareWebArticle(url: 'example.com', cefrLevel: 'B1'),
        isFalse,
      );

      expect(provider.errorCode, 'invalid_url');
      expect(gateway.previewCallCount, 0);
    },
  );
}

class _FailOnceGateway implements QuizGenerationGateway {
  final List<String> requestIds = [];
  bool _failed = false;

  @override
  Future<WebArticleSourcePreview> previewWebArticle(String url) {
    throw UnimplementedError();
  }

  @override
  Future<GeneratedQuizDraft> generate(QuizGenerationRequest request) async {
    requestIds.add(request.requestId);
    if (!_failed) {
      _failed = true;
      throw const QuizGenerationException(
        'response_interrupted',
        'Recover the existing result.',
      );
    }
    return generatedDraft(questionCount: request.questionCount);
  }

  @override
  Future<GeneratedQuizDraft> generatePdf(
    PdfQuizGenerationRequest request,
  ) async {
    throw UnimplementedError();
  }
}
