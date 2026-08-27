import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../screens/active_testing_screen.dart';
import '../../../../state/quiz_provider.dart';
import '../../../../theme/app_colors.dart';
import '../state/attempt_history_provider.dart';
import '../state/saved_quiz_provider.dart';

class ActiveRecallSection extends StatelessWidget {
  const ActiveRecallSection({super.key});

  Future<void> _startReview(
    BuildContext context,
    ReviewRecommendation recommendation,
  ) async {
    final saved = context.read<SavedQuizProvider>();
    final quiz = saved.quizzes
        .where((item) => item.id == recommendation.quizId)
        .firstOrNull;
    if (quiz == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That review quiz is no longer available.'),
        ),
      );
      return;
    }
    context.read<QuizProvider>().startSavedQuiz(quiz);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActiveTestingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AttemptHistoryProvider>();
    final queue = history.dailyReviewQueue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.psychology_alt_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Daily Active Recall',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Mastered means at least 80% accuracy across three or more answers. Lower-scoring concepts stay in your review queue.',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        if (queue.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Complete generated quizzes to build personalized recommendations.',
            ),
          )
        else
          ...queue
              .take(3)
              .map(
                (recommendation) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.mastery.concept.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(recommendation.reason),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              _startReview(context, recommendation),
                          icon: const Icon(Icons.replay),
                          label: Text('Review ${recommendation.quizTitle}'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
