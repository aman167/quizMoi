import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/learning_entities.dart';
import '../state/saved_quiz_provider.dart';
import '../state/source_document_provider.dart';

class SourceDocumentLibrary extends StatelessWidget {
  const SourceDocumentLibrary({super.key});

  Future<void> _delete(BuildContext context, SourceDocument source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this source?'),
        content: Text(
          '“${source.title}” will be removed from this device. Its saved quizzes and attempts will remain available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete source'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await context.read<SourceDocumentProvider>().delete(
      source.id,
    );
    if (deleted && context.mounted) {
      await context.read<SavedQuizProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceDocumentProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.source_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Saved Sources',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (provider.errorMessage != null)
          ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(provider.errorMessage!),
            trailing: TextButton(
              onPressed: provider.load,
              child: const Text('Retry'),
            ),
          )
        else if (provider.sources.isEmpty)
          const Text('No imported sources yet.')
        else
          ...provider.sources.map(
            (source) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(_iconFor(source.type)),
                title: Text(source.title),
                subtitle: Text(
                  '${_labelFor(source.type)} • ${source.content.length} stored characters${source.sourceUri == null ? '' : '\n${source.sourceUri}'}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: 'Delete source',
                  onPressed: () => _delete(context, source),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static IconData _iconFor(SourceType type) => switch (type) {
    SourceType.pdf => Icons.picture_as_pdf_outlined,
    SourceType.image => Icons.photo_camera_outlined,
    SourceType.webArticle => Icons.language,
    SourceType.pastedText => Icons.text_snippet_outlined,
    SourceType.manual => Icons.edit_note,
  };

  static String _labelFor(SourceType type) => switch (type) {
    SourceType.pdf => 'PDF',
    SourceType.image => 'Camera image',
    SourceType.webArticle => 'Web article',
    SourceType.pastedText => 'Pasted text',
    SourceType.manual => 'Manual',
  };
}
