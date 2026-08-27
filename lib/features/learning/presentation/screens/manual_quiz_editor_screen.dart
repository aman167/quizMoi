import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/source_document_repository.dart';
import '../state/knowledge_base_provider.dart';
import '../state/saved_quiz_provider.dart';
import '../state/source_document_provider.dart';
import '../../../quiz_generation/presentation/state/quiz_generation_provider.dart';

enum QuizEditorAction { regenerate }

class ManualQuizEditorScreen extends StatefulWidget {
  final QuizDefinition? existingQuiz;
  final QuizDefinition? draftQuiz;
  final SourceDocument? sourceDocument;

  const ManualQuizEditorScreen({
    super.key,
    this.existingQuiz,
    this.draftQuiz,
    this.sourceDocument,
  }) : assert(existingQuiz == null || draftQuiz == null);

  @override
  State<ManualQuizEditorScreen> createState() => _ManualQuizEditorScreenState();
}

class _ManualQuizEditorScreenState extends State<ManualQuizEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final List<_QuestionDraft> _questions = [];
  String? _knowledgeBaseId;
  bool _isSaving = false;
  int? _regeneratingQuestionIndex;

  bool get _isEditing => widget.existingQuiz != null;
  bool get _isGeneratedDraft => widget.draftQuiz != null;
  QuizDefinition? get _initialQuiz => widget.existingQuiz ?? widget.draftQuiz;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _initialQuiz?.title);
    _knowledgeBaseId = _initialQuiz?.knowledgeBaseId;
    final existingQuestions = _initialQuiz?.questions;
    if (existingQuestions == null || existingQuestions.isEmpty) {
      _questions.add(_QuestionDraft.empty());
    } else {
      _questions.addAll(existingQuestions.map(_QuestionDraft.fromQuestion));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionDraft.empty()));
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) return;
    setState(() {
      _questions.removeAt(index).dispose();
    });
  }

  void _moveQuestion(int from, int offset) {
    final to = from + offset;
    if (to < 0 || to >= _questions.length) return;
    setState(() {
      final question = _questions.removeAt(from);
      _questions.insert(to, question);
    });
  }

  Future<void> _regenerateQuestion(int index) async {
    setState(() => _regeneratingQuestionIndex = index);
    final generation = context.read<QuizGenerationProvider>();
    final regenerated = await generation.regenerateQuestion(index);
    if (!mounted) return;
    if (regenerated) {
      final replacement = generation.draftQuiz!.questions[index];
      setState(() {
        _questions[index].dispose();
        _questions[index] = _QuestionDraft.fromQuestion(replacement);
        _regeneratingQuestionIndex = null;
      });
    } else {
      setState(() => _regeneratingQuestionIndex = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            generation.errorMessage ?? 'The question could not be regenerated.',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final savedQuizProvider = context.read<SavedQuizProvider>();
    final sourceDocumentRepository = context.read<SourceDocumentRepository>();
    final knowledgeBaseProvider = context.read<KnowledgeBaseProvider>();
    final now = DateTime.now();
    final existing = _initialQuiz;
    var sourceDocumentId = existing?.sourceDocumentId;
    final source = widget.sourceDocument;
    if (source != null) {
      try {
        final duplicate = await sourceDocumentRepository.findDuplicate(source);
        final effectiveSource = duplicate ?? source;
        sourceDocumentId = effectiveSource.id;
        if (duplicate == null) {
          await sourceDocumentRepository.save(source);
        }
        final knowledgeBaseId = _knowledgeBaseId;
        if (knowledgeBaseId != null) {
          final attached = await knowledgeBaseProvider.attachSource(
            knowledgeBaseId,
            effectiveSource.id,
          );
          if (!attached) {
            throw StateError('Knowledge-base attachment failed.');
          }
        }
      } catch (_) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The source could not be saved.')),
        );
        return;
      }
      if (!mounted) return;
      await context.read<SourceDocumentProvider>().load();
    }
    final quiz = QuizDefinition(
      id: existing?.id ?? savedQuizProvider.newId('quiz'),
      knowledgeBaseId: _knowledgeBaseId,
      sourceDocumentId: sourceDocumentId,
      title: _titleController.text.trim(),
      questions: _questions
          .map(
            (draft) => draft.toQuestion(
              draft.id ?? savedQuizProvider.newId('question'),
            ),
          )
          .toList(),
      isArchived: existing?.isArchived ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      timeLimitMinutes: existing?.timeLimitMinutes,
    );

    final saved = await savedQuizProvider.save(quiz);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) {
      Navigator.pop(context, quiz);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedQuizProvider.errorMessage ?? 'The quiz could not be saved.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final knowledgeBaseProvider = context.watch<KnowledgeBaseProvider>();
    final availableKnowledgeBases = [
      ...knowledgeBaseProvider.activeKnowledgeBases,
      if (_knowledgeBaseId != null &&
          knowledgeBaseProvider.findById(_knowledgeBaseId)?.isArchived == true)
        knowledgeBaseProvider.findById(_knowledgeBaseId)!,
    ];
    final selectedKnowledgeBaseExists = availableKnowledgeBases.any(
      (knowledgeBase) => knowledgeBase.id == _knowledgeBaseId,
    );
    final dropdownValue = selectedKnowledgeBaseExists ? _knowledgeBaseId! : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isGeneratedDraft
              ? 'Review Generated Quiz'
              : _isEditing
              ? 'Edit Quiz'
              : 'Create Quiz Manually',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _isGeneratedDraft
                        ? Icons.fact_check_outlined
                        : Icons.save_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isGeneratedDraft
                          ? 'Check the AI questions carefully. You can edit, remove, and reorder them before saving privately on this device.'
                          : 'This quiz will be stored privately on this device. Add at least one question and four answer choices.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Quiz title',
                hintText: 'Example: French travel vocabulary',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredText,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(
                '$dropdownValue-${availableKnowledgeBases.map((item) => item.id).join(',')}',
              ),
              initialValue: dropdownValue,
              decoration: const InputDecoration(
                labelText: 'Knowledge base',
                helperText: 'Optional study folder for this quiz',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('Unfiled')),
                ...availableKnowledgeBases.map(
                  (knowledgeBase) => DropdownMenuItem(
                    value: knowledgeBase.id,
                    child: Text(
                      '${knowledgeBase.title}${knowledgeBase.isArchived ? ' (Archived)' : ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _knowledgeBaseId = value == null || value.isEmpty
                            ? null
                            : value;
                      });
                    },
            ),
            const SizedBox(height: 20),
            ..._questions.indexed.map((entry) {
              final (index, draft) = entry;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _QuestionEditorCard(
                  number: index + 1,
                  draft: draft,
                  canRemove: _questions.length > 1,
                  onRemove: () => _removeQuestion(index),
                  canMoveUp: index > 0,
                  canMoveDown: index < _questions.length - 1,
                  onMoveUp: () => _moveQuestion(index, -1),
                  onMoveDown: () => _moveQuestion(index, 1),
                  canRegenerate: _isGeneratedDraft,
                  isRegenerating: _regeneratingQuestionIndex == index,
                  onRegenerate: () => _regenerateQuestion(index),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Add another question'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Material(
          color: AppColors.surface,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isGeneratedDraft) ...[
                  OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.pop(
                            context,
                            QuizEditorAction.regenerate,
                          ),
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Regenerate All Questions'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isEditing ? 'Save Changes' : 'Save Quiz'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _requiredText(String? value) {
  if (value == null || value.trim().isEmpty) return 'This field is required.';
  return null;
}

class _QuestionEditorCard extends StatefulWidget {
  final int number;
  final _QuestionDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final bool canRegenerate;
  final bool isRegenerating;
  final VoidCallback onRegenerate;

  const _QuestionEditorCard({
    required this.number,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.canRegenerate,
    required this.isRegenerating,
    required this.onRegenerate,
  });

  @override
  State<_QuestionEditorCard> createState() => _QuestionEditorCardState();
}

class _QuestionEditorCardState extends State<_QuestionEditorCard> {
  static const optionIds = ['a', 'b', 'c', 'd'];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Question ${widget.number}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.canMoveUp ? widget.onMoveUp : null,
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: 'Move question ${widget.number} up',
                ),
                IconButton(
                  onPressed: widget.canMoveDown ? widget.onMoveDown : null,
                  icon: const Icon(Icons.arrow_downward),
                  tooltip: 'Move question ${widget.number} down',
                ),
                IconButton(
                  onPressed: widget.canRemove ? widget.onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove question ${widget.number}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.draft.promptController,
              decoration: const InputDecoration(
                labelText: 'Question prompt',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: _requiredText,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<QuestionType>(
              initialValue: widget.draft.type,
              decoration: const InputDecoration(
                labelText: 'Question type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: QuestionType.multipleChoice,
                  child: Text('Multiple choice'),
                ),
                DropdownMenuItem(
                  value: QuestionType.typedAnswer,
                  child: Text('Typed answer'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => widget.draft.type = value);
              },
            ),
            const SizedBox(height: 12),
            if (widget.draft.type == QuestionType.multipleChoice) ...[
              ...widget.draft.optionControllers.indexed.map((entry) {
                final (index, controller) = entry;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Option ${optionIds[index].toUpperCase()}',
                      border: const OutlineInputBorder(),
                    ),
                    validator: _requiredText,
                  ),
                );
              }),
              DropdownButtonFormField<int>(
                initialValue: widget.draft.correctOptionIndex,
                decoration: const InputDecoration(
                  labelText: 'Correct answer',
                  border: OutlineInputBorder(),
                ),
                items: optionIds.indexed
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.$1,
                        child: Text('Option ${entry.$2.toUpperCase()}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) widget.draft.correctOptionIndex = value;
                },
              ),
            ] else ...[
              TextFormField(
                controller: widget.draft.correctAnswerController,
                decoration: const InputDecoration(
                  labelText: 'Correct typed answer',
                  helperText: 'French accents are significant during scoring.',
                  border: OutlineInputBorder(),
                ),
                validator: _requiredText,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: widget.draft.acceptedAnswersController,
                decoration: const InputDecoration(
                  labelText: 'Accepted alternatives',
                  helperText:
                      'Optional; separate equivalent answers with semicolons.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (widget.canRegenerate) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.isRegenerating ? null : widget.onRegenerate,
                icon: widget.isRegenerating
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: const Text('Regenerate this question'),
              ),
            ],
            if (widget.draft.explanation != null) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('AI explanation and source evidence'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(widget.draft.explanation!.text),
                  ),
                  if (widget.draft.explanation!.sourceExcerpt != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Source: “${widget.draft.explanation!.sourceExcerpt}”',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionDraft {
  final String? id;
  final TextEditingController promptController;
  final List<TextEditingController> optionControllers;
  int correctOptionIndex;
  QuestionType type;
  final TextEditingController correctAnswerController;
  final TextEditingController acceptedAnswersController;
  final QuestionExplanation? explanation;
  final List<Concept> concepts;

  _QuestionDraft({
    this.id,
    required this.promptController,
    required this.optionControllers,
    required this.correctOptionIndex,
    required this.type,
    required this.correctAnswerController,
    required this.acceptedAnswersController,
    this.explanation,
    this.concepts = const [],
  });

  factory _QuestionDraft.empty() => _QuestionDraft(
    promptController: TextEditingController(),
    optionControllers: List.generate(4, (_) => TextEditingController()),
    correctOptionIndex: 0,
    type: QuestionType.multipleChoice,
    correctAnswerController: TextEditingController(),
    acceptedAnswersController: TextEditingController(),
  );

  factory _QuestionDraft.fromQuestion(QuestionDefinition question) {
    final options = List.generate(
      4,
      (index) => TextEditingController(
        text: index < question.options.length
            ? question.options[index].text
            : '',
      ),
    );
    final correctIndex = question.options.indexWhere(
      (option) => option.id == question.correctAnswer,
    );
    return _QuestionDraft(
      id: question.id,
      promptController: TextEditingController(text: question.prompt),
      optionControllers: options,
      correctOptionIndex: correctIndex < 0 ? 0 : correctIndex,
      type: question.type,
      correctAnswerController: TextEditingController(
        text: question.type == QuestionType.typedAnswer
            ? question.correctAnswer
            : '',
      ),
      acceptedAnswersController: TextEditingController(
        text: question.acceptedAnswers.join('; '),
      ),
      explanation: question.explanation,
      concepts: question.concepts,
    );
  }

  QuestionDefinition toQuestion(String questionId) {
    const optionIds = ['a', 'b', 'c', 'd'];
    final typed = type == QuestionType.typedAnswer;
    return QuestionDefinition(
      id: questionId,
      prompt: promptController.text.trim(),
      type: type,
      options: typed
          ? const []
          : optionControllers.indexed
                .map(
                  (entry) => AnswerOption(
                    id: optionIds[entry.$1],
                    text: entry.$2.text.trim(),
                  ),
                )
                .toList(),
      correctAnswer: typed
          ? correctAnswerController.text.trim()
          : optionIds[correctOptionIndex],
      acceptedAnswers: typed
          ? acceptedAnswersController.text
                .split(';')
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList()
          : const [],
      explanation: explanation,
      concepts: concepts,
    );
  }

  void dispose() {
    promptController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
    correctAnswerController.dispose();
    acceptedAnswersController.dispose();
  }
}
