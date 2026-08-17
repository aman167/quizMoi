import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MobileBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(index: 0, icon: Icons.auto_stories, label: 'Learn'),
          _buildNavItem(index: 1, icon: Icons.history_edu, label: 'Review'),
          _buildNavItem(index: 2, icon: Icons.insert_chart, label: 'Stats'),
          _buildNavItem(index: 3, icon: Icons.account_circle, label: 'Account'),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isActive = currentIndex == index;

    if (isActive) {
      return GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.onSecondaryContainer, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.onSecondaryContainer,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
