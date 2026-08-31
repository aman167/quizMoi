import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../state/attempt_history_provider.dart';

class AttemptHistorySection extends StatelessWidget {
  const AttemptHistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AttemptHistoryProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Recent Attempts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh attempt history',
              onPressed: history.isLoading ? null : history.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (history.isLoading && history.entries.isEmpty)
          const _HistoryMessage(
            icon: Icons.sync,
            message: 'Loading your completed quizzes…',
            showProgress: true,
          )
        else if (history.state == AttemptHistoryLoadState.error &&
            history.entries.isEmpty)
          _HistoryMessage(
            icon: Icons.error_outline,
            message: 'Attempt history could not be loaded.',
            action: OutlinedButton.icon(
              onPressed: history.load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          )
        else if (history.entries.isEmpty)
          const _HistoryMessage(
            icon: Icons.quiz_outlined,
            message: 'Complete a saved quiz and your score will appear here.',
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                icon: Icons.task_alt,
                label:
                    '${history.completedAttemptCount} completed ${history.completedAttemptCount == 1 ? 'attempt' : 'attempts'}',
              ),
              _SummaryChip(
                icon: Icons.today,
                label: '${history.questionsCompletedToday} questions today',
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Every completed attempt counts toward today’s goal, including retakes.',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...history.visibleRecentEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AttemptCard(entry: entry),
            ),
          ),
        ],
      ],
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final AttemptHistoryEntry entry;

  const _AttemptCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final score = entry.scorePercent.round();
    return Semantics(
      label:
          '${entry.quizTitle}, $score percent, ${entry.correctAnswers} of ${entry.totalQuestions} correct',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              child: Text(
                '$score%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.quizTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${entry.correctAnswers} of ${entry.totalQuestions} correct • ${_formatDuration(entry.attempt.elapsedSeconds)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(entry.completedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(int elapsedSeconds) {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${_monthNames[local.month - 1]} ${local.day}, ${local.year} at $hour:${local.minute.toString().padLeft(2, '0')} $period';
  }

  static const _monthNames = [
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

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  final bool showProgress;

  const _HistoryMessage({
    required this.icon,
    required this.message,
    this.action,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (showProgress) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
    );
  }
}
