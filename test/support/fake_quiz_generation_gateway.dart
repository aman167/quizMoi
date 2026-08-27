import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:quiz_moi_app/features/quiz_generation/domain/quiz_generation_gateway.dart';
import 'package:quiz_moi_app/features/quiz_generation/domain/quiz_generation_models.dart';

class FakeQuizGenerationGateway implements QuizGenerationGateway {
  final GeneratedQuizDraft? result;
  final QuizGenerationException? error;
  final WebArticleSourcePreview? articlePreview;
  final QuizGenerationException? articleError;
  int callCount = 0;
  int previewCallCount = 0;
  String? previewedUrl;

  FakeQuizGenerationGateway({
    this.result,
    this.error,
    this.articlePreview,
    this.articleError,
  });

  @override
  Future<WebArticleSourcePreview> previewWebArticle(String url) async {
    previewCallCount++;
    previewedUrl = url;
    if (articleError != null) throw articleError!;
    return articlePreview ??
        WebArticleSourcePreview(
          schemaVersion: 1,
          url: url,
          title: 'La bibliothèque du quartier',
          text: List.filled(
            12,
            'La bibliothèque accueille les habitants du quartier.',
          ).join(' '),
          characterCount: List.filled(
            12,
            'La bibliothèque accueille les habitants du quartier.',
          ).join(' ').length,
          wasTruncated: false,
        );
  }

  @override
  Future<GeneratedQuizDraft> generate(QuizGenerationRequest request) async {
    callCount++;
    if (error != null) throw error!;
    return result ?? generatedDraft(questionCount: request.questionCount);
  }

  @override
  Future<GeneratedQuizDraft> generatePdf(
    PdfQuizGenerationRequest request,
  ) async {
    callCount++;
    if (error != null) throw error!;
    return result ?? generatedDraft(questionCount: request.questionCount);
  }
}

GeneratedQuizDraft generatedDraft({int questionCount = 10}) {
  return GeneratedQuizDraft(
    schemaVersion: 1,
    requestId: 'request-1',
    title: 'Le trajet de Marie',
    questions: List.generate(
      questionCount,
      (index) => GeneratedQuestionDraft(
        prompt: 'Question ${index + 1}: comment Marie voyage-t-elle ?',
        options: const [
          AnswerOption(id: 'a', text: 'En train'),
          AnswerOption(id: 'b', text: 'En avion'),
          AnswerOption(id: 'c', text: 'À vélo'),
          AnswerOption(id: 'd', text: 'À pied'),
        ],
        correctOptionId: 'a',
        explanation: const QuestionExplanation(
          text: 'Le texte dit que Marie prend le train.',
          sourceExcerpt: 'Marie prend le train chaque matin',
        ),
        concepts: [
          Concept(
            id: 'transport-$index',
            name: 'Les transports',
            category: 'vocabulary',
          ),
        ],
      ),
    ),
  );
}
