import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../state/learner_settings_provider.dart';

class LearnerSettingsScreen extends StatelessWidget {
  const LearnerSettingsScreen({super.key});

  Future<void> _update(
    BuildContext context, {
    String? cefrLevel,
    int? dailyQuestionGoal,
    bool? remindersEnabled,
  }) async {
    final provider = context.read<LearnerSettingsProvider>();
    final saved = await provider.update(
      cefrLevel: cefrLevel,
      dailyQuestionGoal: dailyQuestionGoal,
      remindersEnabled: remindersEnabled,
    );
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Your settings could not be saved.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearnerSettingsProvider>();
    final settings = provider.settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account & Settings'),
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.loadState == LearnerSettingsLoadState.error
          ? _SettingsError(
              message:
                  provider.errorMessage ??
                  'Your learning settings could not be loaded.',
              onRetry: provider.load,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(child: Icon(Icons.person_outline)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local learner profile',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'No account is required. These preferences stay privately on this device.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Learning preferences',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('level-${settings.cefrLevel}'),
                  initialValue: settings.cefrLevel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Current French level',
                    helperText: 'Uses the CEFR language-level scale',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A1', child: Text('A1 — Beginner')),
                    DropdownMenuItem(
                      value: 'A2',
                      child: Text('A2 — Elementary'),
                    ),
                    DropdownMenuItem(
                      value: 'B1',
                      child: Text('B1 — Intermediate'),
                    ),
                    DropdownMenuItem(
                      value: 'B2',
                      child: Text('B2 — Upper intermediate'),
                    ),
                    DropdownMenuItem(value: 'C1', child: Text('C1 — Advanced')),
                    DropdownMenuItem(
                      value: 'C2',
                      child: Text('C2 — Proficient'),
                    ),
                  ],
                  onChanged: provider.isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            _update(context, cefrLevel: value);
                          }
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey('goal-${settings.dailyQuestionGoal}'),
                  initialValue: settings.dailyQuestionGoal,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Daily question goal',
                    helperText: 'Completed questions needed each study day',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [10, 20, 30, 40, 50, 75, 100]
                      .map(
                        (goal) => DropdownMenuItem(
                          value: goal,
                          child: Text('$goal questions'),
                        ),
                      )
                      .toList(),
                  onChanged: provider.isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            _update(context, dailyQuestionGoal: value);
                          }
                        },
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile(
                    value: settings.remindersEnabled,
                    onChanged: provider.isSaving
                        ? null
                        : (value) => _update(context, remindersEnabled: value),
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Study-reminder preference'),
                    subtitle: const Text(
                      'Saved locally now. Android notifications will be connected in a later phase.',
                    ),
                  ),
                ),
                if (provider.isSaving) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 6),
                  const Text(
                    'Saving on this device…',
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
    );
  }
}

class _SettingsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SettingsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: AppColors.error),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
