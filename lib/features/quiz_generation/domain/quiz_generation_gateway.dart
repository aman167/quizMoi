import 'quiz_generation_models.dart';

abstract interface class QuizGenerationGateway {
  Future<GeneratedQuizDraft> generate(QuizGenerationRequest request);
}
