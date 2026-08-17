import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/learning_entities.dart';
import '../state/knowledge_base_provider.dart';
import '../state/saved_quiz_provider.dart';

class ManualQuizEditorScreen extends StatefulWidget {
  final QuizDefinition? existingQuiz;

  const ManualQuizEditorScreen({super.key, this.existingQuiz});

  @override
  State<ManualQuizEditorScreen> createState() => _ManualQuizEditorScreenState();
}

class _ManualQuizEditorScreenState extends State<ManualQuizEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final List<_QuestionDraft> _questions = [];
  String? _knowledgeBaseId;
  bool _isSaving = false;

  bool get _isEditing => widget.existingQuiz != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingQuiz?.title);
    _knowledgeBaseId = widget.existingQuiz?.knowledgeBaseId;
    final existingQuestions = widget.existingQuiz?.questions;
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

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final savedQuizProvider = context.read<SavedQuizProvider>();
    final now = DateTime.now();
    final existing = widget.existingQuiz;
    final quiz = QuizDefinition(
      id: existing?.id ?? savedQuizProvider.newId('quiz'),
      knowledgeBaseId: _knowledgeBaseId,
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
        title: Text(_isEditing ? 'Edit Quiz' : 'Create Quiz Manually'),
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
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.save_outlined, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This quiz will be stored privately on this device. Add at least one question and four answer choices.',
                      style: TextStyle(fontSize: 12),
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
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Add another question'),
            ),
            const SizedBox(height: 12),
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

  const _QuestionEditorCard({
    required this.number,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
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

  _QuestionDraft({
    this.id,
    required this.promptController,
    required this.optionControllers,
    required this.correctOptionIndex,
  });

  factory _QuestionDraft.empty() => _QuestionDraft(
    promptController: TextEditingController(),
    optionControllers: List.generate(4, (_) => TextEditingController()),
    correctOptionIndex: 0,
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
    );
  }

  QuestionDefinition toQuestion(String questionId) {
    const optionIds = ['a', 'b', 'c', 'd'];
    return QuestionDefinition(
      id: questionId,
      prompt: promptController.text.trim(),
      type: QuestionType.multipleChoice,
      options: optionControllers.indexed
          .map(
            (entry) => AnswerOption(
              id: optionIds[entry.$1],
              text: entry.$2.text.trim(),
            ),
          )
          .toList(),
      correctAnswer: optionIds[correctOptionIndex],
    );
  }

  void dispose() {
    promptController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
  }
}
