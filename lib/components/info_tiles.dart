import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'custom_card.dart';

class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;
  final Color? color;
  final bool showBadge;
  final String? badgeText;
  final VoidCallback? onTap;
  final bool highlighted;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    this.label,
    this.color,
    this.showBadge = false,
    this.badgeText,
    this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.thermalCool;
    final bgColor = highlighted
        ? tileColor.withValues(alpha: 0.1)
        : AppColors.background;

    return CustomCard(
      onTap: onTap,
      isClickable: onTap != null,
      backgroundColor: bgColor,
      border: Border.all(
        color: highlighted ? tileColor : AppColors.border,
        width: highlighted ? 2 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tileColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tileColor, size: 20),
              ),
              if (showBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: tileColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText ?? 'NEW',
                    style: AppTypography.labelSmall.copyWith(color: tileColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTypography.displaySmall),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                label!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isHighlighted;

  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.iconColor,
    this.onTap,
    this.trailing,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final usedIconColor = iconColor ?? AppColors.thermalCool;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: AppSpacing.paddingLg,
          decoration: BoxDecoration(
            color: isHighlighted
                ? usedIconColor.withValues(alpha: 0.1)
                : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted ? usedIconColor : AppColors.border,
              width: isHighlighted ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: usedIconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: usedIconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleSmall),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          subtitle!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (trailingText != null)
                Text(
                  trailingText!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class AchievementBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final bool isUnlocked;

  const AchievementBadge({
    super.key,
    required this.label,
    required this.icon,
    this.color,
    this.isUnlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppColors.accentPurple;

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isUnlocked
              ? badgeColor.withValues(alpha: 0.15)
              : AppColors.surfaceAlt,
          border: Border.all(
            color: isUnlocked ? badgeColor : AppColors.textDisabled,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isUnlocked ? badgeColor : AppColors.textDisabled,
          size: 28,
        ),
      ),
    );
  }
}
