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

class _ActiveTestingScreenState extends State<ActiveTestingScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _allowPop = false;
  bool _openingResults = false;

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
      message: 'Your answers in this session will be cleared.',
      confirmLabel: 'Leave quiz',
    );
    if (!confirmed || !mounted) return;

    await provider.abandonQuiz();
    if (!mounted) return;
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

    await provider.restartCurrentQuiz();
  }

  Future<void> _submitQuiz(QuizProvider provider) async {
    final confirmed = await _confirmAction(
      title: 'Submit this quiz?',
      message:
          'You answered ${provider.currentQuiz!.answeredCount} of ${provider.currentQuiz!.totalQuestions} questions. Unanswered questions will be marked incorrect and answers cannot be changed after submission.',
      confirmLabel: 'Submit quiz',
    );
    if (!confirmed || !mounted) return;

    if (!provider.completeQuiz()) return;
    await provider.persistSession();
    await _openResults();
  }

  Future<void> _pauseQuiz(QuizProvider provider) async {
    await provider.pauseQuiz();
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  Future<void> _openResults() async {
    if (!mounted || _openingResults) return;
    _openingResults = true;
    setState(() => _allowPop = true);
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ResultsFeedbackScreen()),
    );
  }

  Future<void> _showAnswerReview(QuizProvider provider) async {
    final quiz = provider.currentQuiz!;
    final selectedIndex = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review answers'),
        content: SizedBox(
          width: 420,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: quiz.questions.length,
            itemBuilder: (context, index) {
              final question = quiz.questions[index];
              return ListTile(
                leading: Icon(
                  question.isAnswered
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                ),
                title: Text('Question ${index + 1}'),
                subtitle: Text(question.isAnswered ? 'Answered' : 'Skipped'),
                onTap: () => Navigator.pop(dialogContext, index),
              );
            },
          ),
        ),
      ),
    );
    if (selectedIndex != null) provider.goToQuestion(selectedIndex);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final provider = Provider.of<QuizProvider>(context, listen: false);
      if (!provider.quizCompleted) {
        final expired = provider.incrementTimer();
        if (expired) {
          await provider.persistSession();
          await _openResults();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(
        Provider.of<QuizProvider>(
          context,
          listen: false,
        ).persistSession().catchError((_) {}),
      );
    }
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isVeryNarrow = constraints.maxWidth < 360;
                        return Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pauseQuiz(provider),
                              icon: const Icon(Icons.pause, size: 17),
                              label: Text(
                                isVeryNarrow ? 'Pause' : 'Pause & Exit',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isVeryNarrow ? 10 : 14,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Semantics(
                              label: provider.remainingSeconds == null
                                  ? 'Elapsed time ${provider.formattedTime}'
                                  : '${provider.remainingSeconds!} seconds left',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  if (!isVeryNarrow) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      provider.remainingSeconds == null
                                          ? provider.formattedTime
                                          : '${provider.remainingSeconds! ~/ 60}m ${(provider.remainingSeconds! % 60).toString().padLeft(2, '0')}s',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Quiz actions',
                              onSelected: (action) {
                                if (action == 'restart') {
                                  _restartQuiz(provider);
                                } else if (action == 'discard') {
                                  _exitQuiz(provider);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'restart',
                                  child: ListTile(
                                    leading: Icon(Icons.refresh),
                                    title: Text('Restart Quiz'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'discard',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline),
                                    title: Text('Discard Attempt'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
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
                                        currentQuestion.isTypedAnswer
                                            ? 'TYPED ANSWER'
                                            : 'MULTIPLE CHOICE',
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

                                if (currentQuestion.isTypedAnswer)
                                  TextFormField(
                                    key: ValueKey(
                                      'typed-answer-${currentQuestion.number}',
                                    ),
                                    initialValue:
                                        currentQuestion.selectedOptionId,
                                    minLines: 1,
                                    maxLines: 3,
                                    autocorrect: false,
                                    decoration: const InputDecoration(
                                      labelText: 'Type your answer in French',
                                      helperText:
                                          'Case and trailing punctuation are ignored; accents remain significant.',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: provider.enterTypedAnswer,
                                  )
                                else
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
                        OutlinedButton.icon(
                          onPressed: () => _showAnswerReview(provider),
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Review Answers'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                          ),
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 350;
                            final previous = OutlinedButton.icon(
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
                            );
                            final skip = TextButton(
                              onPressed: provider.skipQuestion,
                              child: const Text('Skip'),
                            );
                            final next = ElevatedButton.icon(
                              onPressed: isLastQuestion
                                  ? () => _submitQuiz(provider)
                                  : provider.canAdvance
                                  ? provider.nextQuestion
                                  : null,
                              icon: Text(isLastQuestion ? 'Submit' : 'Next'),
                              label: const Icon(Icons.arrow_forward, size: 16),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                elevation: 0,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            );
                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: previous),
                                      const SizedBox(width: 8),
                                      Expanded(child: next),
                                    ],
                                  ),
                                  if (!isLastQuestion) skip,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: previous),
                                const SizedBox(width: 12),
                                if (!isLastQuestion) ...[
                                  Expanded(child: skip),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(child: next),
                              ],
                            );
                          },
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
