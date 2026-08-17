import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../state/quiz_provider.dart';
import '../widgets/question_option_tile.dart';
import 'results_feedback_screen.dart';

class ActiveTestingScreen extends StatefulWidget {
  const ActiveTestingScreen({super.key});

  @override
  State<ActiveTestingScreen> createState() => _ActiveTestingScreenState();
}

class _ActiveTestingScreenState extends State<ActiveTestingScreen> {
  Timer? _timer;
  bool _allowPop = false;

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _exitQuiz(QuizProvider provider) async {
    final confirmed = await _confirmAction(
      title: 'Leave this quiz?',
      message: 'Your answers in this demo session will be cleared.',
      confirmLabel: 'Leave quiz',
    );
    if (!confirmed || !mounted) return;

    provider.resetQuiz();
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  Future<void> _restartQuiz(QuizProvider provider) async {
    final confirmed = await _confirmAction(
      title: 'Restart this quiz?',
      message: 'All selected answers and the elapsed time will be reset.',
      confirmLabel: 'Restart',
    );
    if (!confirmed || !mounted) return;

    provider.startQuiz('restart');
  }

  Future<void> _submitQuiz(QuizProvider provider) async {
    final confirmed = await _confirmAction(
      title: 'Submit this quiz?',
      message:
          'You answered all ${provider.currentQuiz!.totalQuestions} questions. Your answers cannot be changed after submission.',
      confirmLabel: 'Submit quiz',
    );
    if (!confirmed || !mounted) return;

    if (!provider.nextQuestion()) return;
    setState(() => _allowPop = true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ResultsFeedbackScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final provider = Provider.of<QuizProvider>(context, listen: false);
      if (!provider.quizCompleted) {
        provider.incrementTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, provider, child) {
        final quiz = provider.currentQuiz;
        final currentQuestion = provider.currentQuestion;

        if (quiz == null || currentQuestion == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isLastQuestion =
            provider.currentQuestionIndex == quiz.questions.length - 1;

        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _exitQuiz(provider);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  // Top Navigation Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => _exitQuiz(provider),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.arrow_back,
                                    size: 16,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Back to Dashboard',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Stats & Timer Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.emoji_events,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Level B1',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      width: 1,
                                      height: 12,
                                      color: AppColors.outlineVariant,
                                    ),
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '1,240 XP',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Timer Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      size: 14,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      provider.formattedTime,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Restart Pill
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 18),
                                onPressed: () => _restartQuiz(provider),
                                tooltip: 'Restart Quiz',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Header info
                          Text(
                            quiz.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Source: ${quiz.source}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Question ${currentQuestion.number} of ${quiz.totalQuestions}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Progress bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${(provider.progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: provider.progress,
                              minHeight: 6,
                              backgroundColor:
                                  AppColors.surfaceContainerHighest,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Quiz Question Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.outlineVariant,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: AppColors.primary,
                                          child: Text(
                                            '${currentQuestion.number}',
                                            style: const TextStyle(
                                              color: AppColors.onPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Question ${currentQuestion.number}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'MULTIPLE CHOICE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryContainer,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Prompt
                                Text(
                                  currentQuestion.prompt,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Options List
                                ...currentQuestion.options.map((opt) {
                                  final isSelected =
                                      currentQuestion.selectedOptionId ==
                                      opt.id;
                                  return QuestionOptionTile(
                                    option: opt,
                                    isSelected: isSelected,
                                    onTap: () {
                                      provider.selectOption(opt.id);
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Controls Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(color: AppColors.outlineVariant),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${quiz.answeredCount} of ${quiz.totalQuestions} answered',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: provider.currentQuestionIndex > 0
                                    ? provider.previousQuestion
                                    : null,
                                icon: const Icon(Icons.arrow_back, size: 16),
                                label: const Text('Previous'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.onSurfaceVariant,
                                  side: BorderSide(
                                    color: AppColors.outlineVariant,
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: provider.canAdvance
                                    ? () {
                                        if (isLastQuestion) {
                                          _submitQuiz(provider);
                                        } else {
                                          provider.nextQuestion();
                                        }
                                      }
                                    : null,
                                icon: Text(isLastQuestion ? 'Submit' : 'Next'),
                                label: const Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
