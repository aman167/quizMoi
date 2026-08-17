import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/quiz_model.dart';

class KnowledgeBaseCard extends StatelessWidget {
  final KnowledgeBase knowledgeBase;
  final VoidCallback onReview;
  final VoidCallback onTestMe;

  const KnowledgeBaseCard({
    super.key,
    required this.knowledgeBase,
    required this.onReview,
    required this.onTestMe,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'picture_as_pdf':
        return Icons.picture_as_pdf;
      case 'text_snippet':
        return Icons.text_snippet;
      case 'link':
        return Icons.link;
      default:
        return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconData(knowledgeBase.iconName),
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
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
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            knowledgeBase.sourceType,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          '• ${knowledgeBase.questionCount} questions',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                        Text(
                          '• Created ${knowledgeBase.createdDate}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: 0.8,
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReview,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Review',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTestMe,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Test Me'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
