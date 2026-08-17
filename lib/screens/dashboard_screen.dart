import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../state/quiz_provider.dart';
import '../widgets/bento_stat_card.dart';
import '../widgets/knowledge_base_card.dart';
import 'upload_content_screen.dart';
import 'active_testing_screen.dart';
import '../features/learning/presentation/widgets/saved_quiz_library.dart';
import '../features/learning/presentation/state/attempt_history_provider.dart';
import '../features/learning/presentation/widgets/attempt_history_section.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, provider, child) {
        final stats = provider.userStats;
        final kbs = provider.knowledgeBases;
        final history = context.watch<AttemptHistoryProvider>();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface.withValues(alpha: 0.8),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: AppColors.onSurfaceVariant),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('The app menu is planned for a later phase.'),
                  ),
                );
              },
            ),
            title: const Text(
              'quizMoi',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryContainer,
                  child: const Text(
                    'U',
                    style: TextStyle(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Quiz Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your knowledge base and track progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.science_outlined, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saved quizzes, accuracy, and attempt history are real. Level, daily goal, streak, and knowledge bases are still sample data.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (provider.hasResumableSession) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryFixedDim),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quiz in progress',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimaryFixed,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${provider.currentQuiz!.title} • ${provider.currentQuiz!.answeredCount} of ${provider.currentQuiz!.totalQuestions} answered',
                              style: const TextStyle(
                                color: AppColors.onPrimaryFixedVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ActiveTestingScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Resume Quiz'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Bento Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: BentoStatCard(
                            icon: Icons.school,
                            iconColor: AppColors.primary,
                            label: 'Current Level',
                            value: stats.level,
                            bgColor: AppColors.primaryContainer.withValues(
                              alpha: 0.3,
                            ),
                            borderColor: AppColors.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BentoStatCard(
                            icon: Icons.trending_up,
                            iconColor: AppColors.successMint,
                            label: 'Real Accuracy',
                            value: history.entries.isEmpty
                                ? '—'
                                : '${history.accuracyPercent.toStringAsFixed(1)}%',
                            bgColor: AppColors.successMint.withValues(
                              alpha: 0.1,
                            ),
                            borderColor: AppColors.successMint.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Daily Goal & Streak (Span full width)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondaryContainer.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: AppColors.secondary,
                                size: 24,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${stats.streakDays} Day Streak!',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'DAILY GOAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: stats.dailyGoalPercent,
                              minHeight: 8,
                              backgroundColor: AppColors.surfaceVariant,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${stats.dailyGoalCurrent} / ${stats.dailyGoalTarget} Questions',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const SavedQuizLibrary(),
                    const SizedBox(height: 24),

                    const AttemptHistorySection(),
                    const SizedBox(height: 24),

                    // Section Title
                    Row(
                      children: const [
                        Icon(
                          Icons.folder_copy,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your Knowledge Bases',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Knowledge Bases List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: kbs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final kb = kbs[index];
                        return KnowledgeBaseCard(
                          knowledgeBase: kb,
                          onReview: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reviewing ${kb.title}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          onTestMe: () {
                            provider.startQuiz(kb.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ActiveTestingScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Floating Action Button
              Positioned(
                bottom: 20,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    if (onNavigateTab != null) {
                      onNavigateTab!(0); // navigate to Learn/Upload tab
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadContentScreen(),
                        ),
                      );
                    }
                  },
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.onSecondaryContainer,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  icon: const Icon(Icons.add, size: 24),
                  label: const Text(
                    'Add Content',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
