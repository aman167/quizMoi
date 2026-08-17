import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../screens/active_testing_screen.dart';
import '../../../../state/quiz_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/learning_entities.dart';
import '../screens/manual_quiz_editor_screen.dart';
import '../state/knowledge_base_provider.dart';
import '../state/saved_quiz_provider.dart';

enum _QuizAction { edit, duplicate, archive, delete }

class SavedQuizLibrary extends StatelessWidget {
  const SavedQuizLibrary({super.key});

  Future<void> _deleteQuiz(BuildContext context, QuizDefinition quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this quiz?'),
        content: Text(
          '“${quiz.title}” will be permanently removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete quiz'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<SavedQuizProvider>().deleteQuiz(quiz.id);
  }

  Future<void> _handleAction(
    BuildContext context,
    QuizDefinition quiz,
    _QuizAction action,
  ) async {
    final provider = context.read<SavedQuizProvider>();
    switch (action) {
      case _QuizAction.edit:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManualQuizEditorScreen(existingQuiz: quiz),
          ),
        );
      case _QuizAction.duplicate:
        await provider.duplicate(quiz);
      case _QuizAction.archive:
        await provider.setArchived(quiz, !quiz.isArchived);
      case _QuizAction.delete:
        if (context.mounted) await _deleteQuiz(context, quiz);
    }
  }

  void _startQuiz(BuildContext context, QuizDefinition quiz) {
    context.read<QuizProvider>().startSavedQuiz(quiz);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActiveTestingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final knowledgeBaseProvider = context.watch<KnowledgeBaseProvider>();
    return Consumer<SavedQuizProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.save, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saved Quizzes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FilterChip(
                  label: const Text('Show archived'),
                  selected: provider.showArchived,
                  onSelected: provider.setShowArchived,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.loadState == SavedQuizLoadState.error)
              _ErrorState(
                message:
                    provider.errorMessage ??
                    'Saved quizzes could not be loaded.',
                onRetry: provider.load,
              )
            else if (provider.quizzes.isEmpty)
              const _EmptyState()
            else
              ...provider.quizzes.map(
                (quiz) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SavedQuizCard(
                    quiz: quiz,
                    knowledgeBaseTitle: knowledgeBaseProvider
                        .findById(quiz.knowledgeBaseId)
                        ?.title,
                    onTest: () => _startQuiz(context, quiz),
                    onAction: (action) => _handleAction(context, quiz, action),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Column(
        children: [
          Icon(Icons.quiz_outlined, size: 36),
          SizedBox(height: 8),
          Text(
            'No saved quizzes yet',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Use Add Content, then Create Manually to build your first private quiz.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.error_outline, color: AppColors.error),
      title: Text(message),
      trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
    );
  }
}

class _SavedQuizCard extends StatelessWidget {
  final QuizDefinition quiz;
  final String? knowledgeBaseTitle;
  final VoidCallback onTest;
  final ValueChanged<_QuizAction> onAction;

  const _SavedQuizCard({
    required this.quiz,
    required this.knowledgeBaseTitle,
    required this.onTest,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(child: Icon(Icons.quiz)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${quiz.questions.length} ${quiz.questions.length == 1 ? 'question' : 'questions'}${quiz.isArchived ? ' • Archived' : ''}',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Knowledge base: ${knowledgeBaseTitle ?? 'Unfiled'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_QuizAction>(
                  tooltip: 'Quiz actions',
                  onSelected: onAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _QuizAction.edit,
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: _QuizAction.duplicate,
                      child: Text('Duplicate'),
                    ),
                    PopupMenuItem(
                      value: _QuizAction.archive,
                      child: Text(quiz.isArchived ? 'Restore' : 'Archive'),
                    ),
                    const PopupMenuItem(
                      value: _QuizAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: quiz.isArchived ? null : onTest,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test Me'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
