import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum ProgressStyle { linear, circular }

class CustomProgressBar extends StatelessWidget {
  final double progress;
  final ProgressStyle style;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? label;
  final String? valueText;
  final double? height;
  final bool showPercentage;
  final Gradient? gradient;

  const CustomProgressBar({
    super.key,
    required this.progress,
    this.style = ProgressStyle.linear,
    this.backgroundColor,
    this.foregroundColor,
    this.label,
    this.valueText,
    this.height,
    this.showPercentage = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);

    if (style == ProgressStyle.circular) {
      return SizedBox(
        width: 120,
        height: 120,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: safeProgress),
          duration: AppDurations.normal,
          curve: AppDurations.easeOutCubic,
          builder: (context, value, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor: backgroundColor ?? AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor ?? AppColors.thermalCool,
                  ),
                ),
                if (showPercentage)
                  Text(
                    '${(value * 100).toStringAsFixed(0)}%',
                    style: AppTypography.titleSmall,
                  ),
                if (!showPercentage && label != null)
                  Text(
                    label!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || valueText != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label ?? '', style: AppTypography.labelMedium),
                Text(
                  valueText ??
                      (showPercentage
                          ? '${(safeProgress * 100).toStringAsFixed(0)}%'
                          : ''),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: safeProgress),
          duration: AppDurations.normal,
          curve: AppDurations.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: height ?? 8,
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: backgroundColor ?? AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor ?? AppColors.thermalCool,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class LevelProgressBar extends StatelessWidget {
  final int currentPoints;
  final int pointsPerLevel;
  final int level;
  final Color? color;

  const LevelProgressBar({
    super.key,
    required this.currentPoints,
    required this.pointsPerLevel,
    required this.level,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safePointsPerLevel = pointsPerLevel <= 0 ? 1 : pointsPerLevel;
    final progressPoints = currentPoints % safePointsPerLevel;
    final progress = progressPoints / safePointsPerLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nivel $level', style: AppTypography.titleSmall),
            Text(
              '$progressPoints / $safePointsPerLevel pts',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomProgressBar(
          progress: progress,
          foregroundColor: color ?? AppColors.thermalWarm,
          height: 12,
          showPercentage: false,
        ),
      ],
    );
  }
}
