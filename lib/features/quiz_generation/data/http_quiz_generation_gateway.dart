import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../learning/domain/entities/learning_entities.dart';
import '../domain/quiz_generation_gateway.dart';
import '../domain/quiz_generation_models.dart';

class HttpQuizGenerationGateway implements QuizGenerationGateway {
  final Uri baseUri;
  final http.Client _client;
  final Duration timeout;

  HttpQuizGenerationGateway({
    required String baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 50),
  }) : baseUri = Uri.parse(baseUrl),
       _client = client ?? http.Client();

  @override
  Future<GeneratedQuizDraft> generate(QuizGenerationRequest request) async {
    try {
      final response = await _client
          .post(
            baseUri.resolve('/v1/quizzes/generate'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);
      final body = _decodeObject(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _errorFromResponse(response.statusCode, body);
      }
      return _parseDraft(body);
    } on QuizGenerationException {
      rethrow;
    } on TimeoutException {
      throw const QuizGenerationException(
        'generation_timeout',
        'Quiz generation took too long. Your text is still here, so you can retry.',
      );
    } on http.ClientException {
      throw const QuizGenerationException(
        'backend_unavailable',
        'The local quiz server is not reachable. Start it on your computer, then retry.',
      );
    } on FormatException {
      throw const QuizGenerationException(
        'invalid_generation',
        'The server returned quiz data the app could not understand. Please retry.',
      );
    }
  }

  Map<String, Object?> _decodeObject(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Expected a JSON object.');
    }
    return decoded;
  }

  QuizGenerationException _errorFromResponse(
    int statusCode,
    Map<String, Object?> body,
  ) {
    final detail = body['detail'];
    if (detail is Map<String, Object?>) {
      final code = detail['code'];
      final message = detail['message'];
      if (code is String && message is String) {
        return QuizGenerationException(code, message);
      }
    }
    return QuizGenerationException(
      'server_error',
      'The quiz server returned error $statusCode. Please retry.',
    );
  }

  GeneratedQuizDraft _parseDraft(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1 || json['requestId'] is! String) {
      throw const FormatException('Unsupported response version.');
    }
    final title = _requiredString(json, 'title');
    final questionValues = json['questions'];
    if (questionValues is! List<Object?> || questionValues.isEmpty) {
      throw const FormatException('Questions are required.');
    }
    final questions = questionValues.indexed.map((entry) {
      final value = entry.$2;
      if (value is! Map<String, Object?>) {
        throw const FormatException('Invalid question.');
      }
      return _parseQuestion(value, entry.$1);
    }).toList();
    return GeneratedQuizDraft(
      schemaVersion: 1,
      requestId: json['requestId']! as String,
      title: title,
      questions: questions,
    );
  }

  GeneratedQuestionDraft _parseQuestion(
    Map<String, Object?> json,
    int questionIndex,
  ) {
    final optionValues = json['options'];
    if (optionValues is! List<Object?> || optionValues.length != 4) {
      throw const FormatException('Four options are required.');
    }
    final options = optionValues.map((value) {
      if (value is! Map<String, Object?>) {
        throw const FormatException('Invalid option.');
      }
      return AnswerOption(
        id: _requiredString(value, 'id'),
        text: _requiredString(value, 'text'),
      );
    }).toList();
    final optionIds = options.map((option) => option.id).toSet();
    final optionText = options
        .map((option) => option.text.toLowerCase())
        .toSet();
    final correctOptionId = _requiredString(json, 'correctOptionId');
    if (optionIds.length != 4 ||
        optionText.length != 4 ||
        !optionIds.contains(correctOptionId)) {
      throw const FormatException('Invalid answer options.');
    }
    final conceptValues = json['concepts'];
    if (conceptValues is! List<Object?> || conceptValues.isEmpty) {
      throw const FormatException('Concepts are required.');
    }
    final concepts = conceptValues.indexed.map((entry) {
      final value = entry.$2;
      if (value is! Map<String, Object?>) {
        throw const FormatException('Invalid concept.');
      }
      return Concept(
        id: 'generated-concept-$questionIndex-${entry.$1}',
        name: _requiredString(value, 'name'),
        category: _requiredString(value, 'category'),
      );
    }).toList();
    return GeneratedQuestionDraft(
      prompt: _requiredString(json, 'prompt'),
      options: options,
      correctOptionId: correctOptionId,
      explanation: QuestionExplanation(
        text: _requiredString(json, 'explanation'),
        sourceExcerpt: _requiredString(json, 'sourceExcerpt'),
      ),
      concepts: concepts,
    );
  }

  String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key is required.');
    }
    return value.trim();
  }
}
