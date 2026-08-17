import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_knowledge_base_repository.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_quiz_repository.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/knowledge_base_provider.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/saved_quiz_provider.dart';
import 'package:quiz_moi_app/features/learning/presentation/widgets/knowledge_base_library.dart';

void main() {
  test('creates, renames, archives, restores, and deletes folders', () async {
    final now = DateTime.utc(2026, 8, 17, 16);
    final provider = KnowledgeBaseProvider(
      MemoryKnowledgeBaseRepository(),
      now: () => now,
    );
    await provider.load();

    expect(await provider.create('Travel Lessons'), isTrue);
    expect(provider.knowledgeBases.single.title, 'Travel Lessons');
    expect(await provider.create('travel lessons'), isFalse);

    final created = provider.knowledgeBases.single;
    expect(await provider.rename(created, 'French Travel'), isTrue);
    final renamed = provider.knowledgeBases.single;
    expect(renamed.title, 'French Travel');

    expect(await provider.setArchived(renamed, true), isTrue);
    expect(provider.knowledgeBases, isEmpty);
    provider.setShowArchived(true);
    expect(provider.knowledgeBases.single.isArchived, isTrue);

    expect(
      await provider.setArchived(provider.knowledgeBases.single, false),
      isTrue,
    );
    expect(provider.knowledgeBases.single.isArchived, isFalse);
    expect(await provider.delete(provider.knowledgeBases.single.id), isTrue);
    expect(provider.knowledgeBases, isEmpty);
  });

  testWidgets('creates a knowledge base from the empty Dashboard section', (
    tester,
  ) async {
    final knowledgeBaseProvider = KnowledgeBaseProvider(
      MemoryKnowledgeBaseRepository(),
    );
    final savedQuizProvider = SavedQuizProvider(MemoryQuizRepository());
    await knowledgeBaseProvider.load();
    await savedQuizProvider.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: knowledgeBaseProvider),
          ChangeNotifierProvider.value(value: savedQuizProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: KnowledgeBaseLibrary()),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Create Knowledge Base'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Grammar Practice');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Grammar Practice'), findsOneWidget);
    expect(knowledgeBaseProvider.knowledgeBases, hasLength(1));
  });
}
