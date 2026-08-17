import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quiz_moi_app/features/learning/data/repositories/memory_learner_settings_repository.dart';
import 'package:quiz_moi_app/features/learning/presentation/screens/learner_settings_screen.dart';
import 'package:quiz_moi_app/features/learning/presentation/state/learner_settings_provider.dart';

void main() {
  test('persists defaults and subsequent preference changes', () async {
    final repository = MemoryLearnerSettingsRepository();
    final provider = LearnerSettingsProvider(repository);

    await provider.load();

    expect(provider.settings.cefrLevel, 'B1');
    expect((await repository.get())!.dailyQuestionGoal, 20);

    expect(
      await provider.update(
        cefrLevel: 'B2',
        dailyQuestionGoal: 30,
        remindersEnabled: true,
      ),
      isTrue,
    );
    expect((await repository.get())!.toJson(), provider.settings.toJson());
  });

  testWidgets('settings screen changes the stored French level', (
    tester,
  ) async {
    final repository = MemoryLearnerSettingsRepository();
    final provider = LearnerSettingsProvider(repository);
    await provider.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: LearnerSettingsScreen()),
      ),
    );

    await tester.tap(find.text('B1 — Intermediate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B2 — Upper intermediate').last);
    await tester.pumpAndSettle();

    expect(provider.settings.cefrLevel, 'B2');
    expect((await repository.get())!.cefrLevel, 'B2');
  });
}
