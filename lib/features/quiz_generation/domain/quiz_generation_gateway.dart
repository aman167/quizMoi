import 'quiz_generation_models.dart';

abstract interface class QuizGenerationGateway {
  Future<WebArticleSourcePreview> previewWebArticle(String url);

  Future<GeneratedQuizDraft> generate(QuizGenerationRequest request);

  Future<GeneratedQuizDraft> generatePdf(PdfQuizGenerationRequest request);
}
