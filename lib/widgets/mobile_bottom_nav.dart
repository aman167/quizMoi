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
    final foregroundColor = isActive
        ? AppColors.onSecondaryContainer
        : AppColors.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: '$label tab',
        child: InkWell(
          onTap: () => onTap(index),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: foregroundColor, size: 22),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
