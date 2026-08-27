import 'package:quiz_moi_app/features/learning/domain/entities/learning_entities.dart';
import 'package:quiz_moi_app/features/quiz_generation/domain/quiz_generation_gateway.dart';
import 'package:quiz_moi_app/features/quiz_generation/domain/quiz_generation_models.dart';

class FakeQuizGenerationGateway implements QuizGenerationGateway {
  final GeneratedQuizDraft? result;
  final QuizGenerationException? error;
  int callCount = 0;

  FakeQuizGenerationGateway({this.result, this.error});

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
