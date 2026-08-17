import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/learning_entities.dart';
import '../state/knowledge_base_provider.dart';
import '../state/saved_quiz_provider.dart';

enum _KnowledgeBaseAction { rename, archive, delete }

class KnowledgeBaseLibrary extends StatelessWidget {
  const KnowledgeBaseLibrary({super.key});

  Future<void> _create(BuildContext context) async {
    final provider = context.read<KnowledgeBaseProvider>();
    final title = await _showNameDialog(
      context,
      title: 'Create knowledge base',
      actionLabel: 'Create',
      provider: provider,
    );
    if (title == null || !context.mounted) return;
    final saved = await provider.create(title);
    if (!saved && context.mounted) {
      _showError(context, provider.errorMessage);
    }
  }

  Future<void> _rename(
    BuildContext context,
    KnowledgeBaseRecord knowledgeBase,
  ) async {
    final provider = context.read<KnowledgeBaseProvider>();
    final title = await _showNameDialog(
      context,
      title: 'Rename knowledge base',
      actionLabel: 'Save',
      initialValue: knowledgeBase.title,
      excludingId: knowledgeBase.id,
      provider: provider,
    );
    if (title == null || !context.mounted) return;
    final saved = await provider.rename(knowledgeBase, title);
    if (!saved && context.mounted) {
      _showError(context, provider.errorMessage);
    }
  }

  Future<void> _delete(
    BuildContext context,
    KnowledgeBaseRecord knowledgeBase,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this knowledge base?'),
        content: Text(
          '“${knowledgeBase.title}” will be removed. Its quizzes will stay saved and move to Unfiled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete knowledge base'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await context.read<KnowledgeBaseProvider>().delete(
      knowledgeBase.id,
    );
    if (!context.mounted) return;
    if (deleted) {
      await context.read<SavedQuizProvider>().load();
    } else if (context.mounted) {
      _showError(context, context.read<KnowledgeBaseProvider>().errorMessage);
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    KnowledgeBaseRecord knowledgeBase,
    _KnowledgeBaseAction action,
  ) async {
    final provider = context.read<KnowledgeBaseProvider>();
    switch (action) {
      case _KnowledgeBaseAction.rename:
        await _rename(context, knowledgeBase);
      case _KnowledgeBaseAction.archive:
        final saved = await provider.setArchived(
          knowledgeBase,
          !knowledgeBase.isArchived,
        );
        if (!saved && context.mounted) {
          _showError(context, provider.errorMessage);
        }
      case _KnowledgeBaseAction.delete:
        if (context.mounted) await _delete(context, knowledgeBase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<KnowledgeBaseProvider, SavedQuizProvider>(
      builder: (context, provider, savedQuizProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.folder_copy,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Your Knowledge Bases',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Create knowledge base',
                  onPressed: provider.isLoading ? null : () => _create(context),
                  icon: const Icon(Icons.create_new_folder_outlined),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FilterChip(
              label: const Text('Show archived'),
              selected: provider.showArchived,
              onSelected: provider.setShowArchived,
            ),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.loadState == KnowledgeBaseLoadState.error)
              _KnowledgeBaseError(
                message:
                    provider.errorMessage ??
                    'Knowledge bases could not be loaded.',
                onRetry: provider.load,
              )
            else if (provider.knowledgeBases.isEmpty)
              _KnowledgeBaseEmpty(onCreate: () => _create(context))
            else
              ...provider.knowledgeBases.map((knowledgeBase) {
                final activeQuizCount = savedQuizProvider.quizzes
                    .where(
                      (quiz) =>
                          !quiz.isArchived &&
                          quiz.knowledgeBaseId == knowledgeBase.id,
                    )
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _KnowledgeBaseCard(
                    knowledgeBase: knowledgeBase,
                    activeQuizCount: activeQuizCount,
                    onAction: (action) =>
                        _handleAction(context, knowledgeBase, action),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Future<String?> _showNameDialog(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required KnowledgeBaseProvider provider,
    String initialValue = '',
    String? excludingId,
  }) async {
    final formKey = GlobalKey<FormState>();
    var enteredValue = initialValue;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: initialValue,
            autofocus: true,
            maxLength: 80,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Knowledge-base name',
              hintText: 'Example: Travel French',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Enter a name.';
              if (provider.titleExists(trimmed, excludingId: excludingId)) {
                return 'This name is already in use.';
              }
              return null;
            },
            onChanged: (value) => enteredValue = value,
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, enteredValue.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, enteredValue.trim());
              }
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return result;
  }

  void _showError(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'The change could not be saved.')),
    );
  }
}

class _KnowledgeBaseCard extends StatelessWidget {
  final KnowledgeBaseRecord knowledgeBase;
  final int activeQuizCount;
  final ValueChanged<_KnowledgeBaseAction> onAction;

  const _KnowledgeBaseCard({
    required this.knowledgeBase,
    required this.activeQuizCount,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              child: const Icon(Icons.folder_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    knowledgeBase.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$activeQuizCount active ${activeQuizCount == 1 ? 'quiz' : 'quizzes'}${knowledgeBase.isArchived ? ' • Archived' : ''}',
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Updated ${_formatDate(knowledgeBase.updatedAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<_KnowledgeBaseAction>(
              tooltip: 'Knowledge-base actions',
              onSelected: onAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _KnowledgeBaseAction.rename,
                  child: Text('Rename'),
                ),
                PopupMenuItem(
                  value: _KnowledgeBaseAction.archive,
                  child: Text(knowledgeBase.isArchived ? 'Restore' : 'Archive'),
                ),
                const PopupMenuItem(
                  value: _KnowledgeBaseAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${_months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class _KnowledgeBaseEmpty extends StatelessWidget {
  final VoidCallback onCreate;

  const _KnowledgeBaseEmpty({required this.onCreate});

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
      child: Column(
        children: [
          const Icon(Icons.create_new_folder_outlined, size: 36),
          const SizedBox(height: 8),
          const Text(
            'No knowledge bases yet',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create a study folder, then assign quizzes to it.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create Knowledge Base'),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeBaseError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _KnowledgeBaseError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.error_outline, color: AppColors.error),
      title: Text(message),
      trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
    );
  }
}
