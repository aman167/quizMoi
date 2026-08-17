enum SourceType { pastedText, pdf, webArticle, manual }

enum QuestionType { multipleChoice, typedAnswer }

enum AttemptStatus { inProgress, completed }

T _enumByName<T extends Enum>(Iterable<T> values, String name) {
  return values.firstWhere(
    (value) => value.name == name,
    orElse: () => throw FormatException('Unknown enum value: $name'),
  );
}

class SourceDocument {
  final String id;
  final String title;
  final SourceType type;
  final String content;
  final DateTime createdAt;

  const SourceDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SourceDocument.fromJson(Map<String, Object?> json) => SourceDocument(
    id: json['id']! as String,
    title: json['title']! as String,
    type: _enumByName(SourceType.values, json['type']! as String),
    content: json['content']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
  );
}

class KnowledgeBaseRecord {
  final String id;
  final String title;
  final List<String> sourceDocumentIds;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  KnowledgeBaseRecord({
    required this.id,
    required this.title,
    required List<String> sourceDocumentIds,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  }) : sourceDocumentIds = List.unmodifiable(sourceDocumentIds);

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'sourceDocumentIds': sourceDocumentIds,
    'isArchived': isArchived,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory KnowledgeBaseRecord.fromJson(Map<String, Object?> json) {
    return KnowledgeBaseRecord(
      id: json['id']! as String,
      title: json['title']! as String,
      sourceDocumentIds: (json['sourceDocumentIds']! as List<Object?>)
          .cast<String>(),
      isArchived: json['isArchived']! as bool,
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
    );
  }
}

class Concept {
  final String id;
  final String name;
  final String category;

  const Concept({required this.id, required this.name, required this.category});

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category,
  };

  factory Concept.fromJson(Map<String, Object?> json) => Concept(
    id: json['id']! as String,
    name: json['name']! as String,
    category: json['category']! as String,
  );
}

class LearnerSettings {
  final String id;
  final String cefrLevel;
  final int dailyQuestionGoal;
  final bool remindersEnabled;

  const LearnerSettings({
    this.id = 'local-learner',
    required this.cefrLevel,
    required this.dailyQuestionGoal,
    required this.remindersEnabled,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'cefrLevel': cefrLevel,
    'dailyQuestionGoal': dailyQuestionGoal,
    'remindersEnabled': remindersEnabled,
  };

  factory LearnerSettings.fromJson(Map<String, Object?> json) {
    return LearnerSettings(
      id: json['id']! as String,
      cefrLevel: json['cefrLevel']! as String,
      dailyQuestionGoal: json['dailyQuestionGoal']! as int,
      remindersEnabled: json['remindersEnabled']! as bool,
    );
  }
}

class AnswerOption {
  final String id;
  final String text;

  const AnswerOption({required this.id, required this.text});

  Map<String, Object?> toJson() => {'id': id, 'text': text};

  factory AnswerOption.fromJson(Map<String, Object?> json) =>
      AnswerOption(id: json['id']! as String, text: json['text']! as String);
}

class QuestionExplanation {
  final String text;
  final String? sourceExcerpt;

  const QuestionExplanation({required this.text, this.sourceExcerpt});

  Map<String, Object?> toJson() => {
    'text': text,
    'sourceExcerpt': sourceExcerpt,
  };

  factory QuestionExplanation.fromJson(Map<String, Object?> json) {
    return QuestionExplanation(
      text: json['text']! as String,
      sourceExcerpt: json['sourceExcerpt'] as String?,
    );
  }
}

class QuestionDefinition {
  final String id;
  final String prompt;
  final QuestionType type;
  final List<AnswerOption> options;
  final String correctAnswer;
  final QuestionExplanation? explanation;
  final List<Concept> concepts;

  QuestionDefinition({
    required this.id,
    required this.prompt,
    required this.type,
    required List<AnswerOption> options,
    required this.correctAnswer,
    this.explanation,
    List<Concept> concepts = const [],
  }) : options = List.unmodifiable(options),
       concepts = List.unmodifiable(concepts) {
    if (prompt.trim().isEmpty) {
      throw ArgumentError.value(prompt, 'prompt', 'Prompt cannot be empty.');
    }
    if (type == QuestionType.multipleChoice) {
      if (options.length < 2) {
        throw ArgumentError(
          'Multiple-choice questions need at least two options.',
        );
      }
      if (!options.any((option) => option.id == correctAnswer)) {
        throw ArgumentError(
          'The correct answer must match one of the option ids.',
        );
      }
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'prompt': prompt,
    'type': type.name,
    'options': options.map((option) => option.toJson()).toList(),
    'correctAnswer': correctAnswer,
    'explanation': explanation?.toJson(),
    'concepts': concepts.map((concept) => concept.toJson()).toList(),
  };

  factory QuestionDefinition.fromJson(Map<String, Object?> json) {
    final explanation = json['explanation'];
    return QuestionDefinition(
      id: json['id']! as String,
      prompt: json['prompt']! as String,
      type: _enumByName(QuestionType.values, json['type']! as String),
      options: (json['options']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(AnswerOption.fromJson)
          .toList(),
      correctAnswer: json['correctAnswer']! as String,
      explanation: explanation == null
          ? null
          : QuestionExplanation.fromJson(explanation as Map<String, Object?>),
      concepts: (json['concepts']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(Concept.fromJson)
          .toList(),
    );
  }
}

class QuizDefinition {
  final String id;
  final String? knowledgeBaseId;
  final String title;
  final List<QuestionDefinition> questions;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuizDefinition({
    required this.id,
    this.knowledgeBaseId,
    required this.title,
    required List<QuestionDefinition> questions,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  }) : questions = List.unmodifiable(questions) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'Title cannot be empty.');
    }
    if (questions.isEmpty) {
      throw ArgumentError('A quiz must contain at least one question.');
    }
  }

  QuizDefinition copyWith({
    String? id,
    String? knowledgeBaseId,
    String? title,
    List<QuestionDefinition>? questions,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizDefinition(
      id: id ?? this.id,
      knowledgeBaseId: knowledgeBaseId ?? this.knowledgeBaseId,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'knowledgeBaseId': knowledgeBaseId,
    'title': title,
    'questions': questions.map((question) => question.toJson()).toList(),
    'isArchived': isArchived,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory QuizDefinition.fromJson(Map<String, Object?> json) => QuizDefinition(
    id: json['id']! as String,
    knowledgeBaseId: json['knowledgeBaseId'] as String?,
    title: json['title']! as String,
    questions: (json['questions']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(QuestionDefinition.fromJson)
        .toList(),
    isArchived: json['isArchived']! as bool,
    createdAt: DateTime.parse(json['createdAt']! as String),
    updatedAt: DateTime.parse(json['updatedAt']! as String),
  );
}

class QuestionAnswer {
  final String questionId;
  final String value;
  final DateTime answeredAt;

  const QuestionAnswer({
    required this.questionId,
    required this.value,
    required this.answeredAt,
  });

  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'value': value,
    'answeredAt': answeredAt.toIso8601String(),
  };

  factory QuestionAnswer.fromJson(Map<String, Object?> json) => QuestionAnswer(
    questionId: json['questionId']! as String,
    value: json['value']! as String,
    answeredAt: DateTime.parse(json['answeredAt']! as String),
  );
}

class QuizAttempt {
  final String id;
  final String quizId;
  final AttemptStatus status;
  final List<QuestionAnswer> answers;
  final int currentQuestionIndex;
  final int elapsedSeconds;
  final DateTime startedAt;
  final DateTime? completedAt;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.status,
    required List<QuestionAnswer> answers,
    required this.currentQuestionIndex,
    required this.elapsedSeconds,
    required this.startedAt,
    this.completedAt,
  }) : answers = List.unmodifiable(answers);

  Map<String, Object?> toJson() => {
    'id': id,
    'quizId': quizId,
    'status': status.name,
    'answers': answers.map((answer) => answer.toJson()).toList(),
    'currentQuestionIndex': currentQuestionIndex,
    'elapsedSeconds': elapsedSeconds,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory QuizAttempt.fromJson(Map<String, Object?> json) => QuizAttempt(
    id: json['id']! as String,
    quizId: json['quizId']! as String,
    status: _enumByName(AttemptStatus.values, json['status']! as String),
    answers: (json['answers']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(QuestionAnswer.fromJson)
        .toList(),
    currentQuestionIndex: json['currentQuestionIndex']! as int,
    elapsedSeconds: json['elapsedSeconds']! as int,
    startedAt: DateTime.parse(json['startedAt']! as String),
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt']! as String),
  );
}
