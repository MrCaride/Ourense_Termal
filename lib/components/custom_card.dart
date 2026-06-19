import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

///Componente base para tarjetas modernas
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color backgroundColor;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool isClickable;
  final Border? border;
  final double? elevation;

  const CustomCard({
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.backgroundColor = Colors.white,
    this.shadows,
    this.gradient,
    this.onTap,
    this.isClickable = false,
    this.border,
    this.elevation,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget card = Container(
      padding: padding ?? AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: gradient != null ? null : backgroundColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows ?? (elevation != null ? [AppShadows.elevation2[0]] : null),
      ),
      child: child,
    );

    if (onTap != null || isClickable) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

///Botón moderno con variantes
enum ButtonVariant { filled, outline, ghost }
enum ButtonSize { large, medium, small }

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  const CustomButton({
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    Key? key,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final height = widget.size == ButtonSize.large
        ? AppSizes.buttonHeightLarge
        : widget.size == ButtonSize.medium
            ? AppSizes.buttonHeightMedium
            : AppSizes.buttonHeightSmall;

    final textStyle = widget.size == ButtonSize.large
        ? AppTypography.buttonText
        : widget.size == ButtonSize.medium
            ? AppTypography.labelLarge
            : AppTypography.labelMedium;

    Color bgColor = widget.backgroundColor ?? AppColors.thermalCool;
    Color fgColor = widget.foregroundColor ?? Colors.white;

    // Define colors based on variant
    if (widget.variant == ButtonVariant.outline) {
      bgColor = Colors.transparent;
      fgColor = widget.backgroundColor ?? AppColors.thermalCool;
    } else if (widget.variant == ButtonVariant.ghost) {
      bgColor = Colors.transparent;
      fgColor = widget.backgroundColor ?? AppColors.textSecondary;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = widget.width ?? (constraints.hasBoundedWidth ? double.infinity : null);

        return SizedBox(
          width: buttonWidth,
          height: height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isDisabled || widget.isLoading ? null : widget.onPressed,
              onHighlightChanged: (highlighted) {
                setState(() => _isPressed = highlighted);
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                decoration: BoxDecoration(
                  color: widget.isDisabled
                      ? AppColors.disabledBg
                      : _isPressed
                          ? bgColor.withOpacity(0.9)
                          : bgColor,
                  border: widget.variant != ButtonVariant.filled
                      ? Border.all(
                          color: fgColor.withOpacity(0.3),
                          width: 1.5,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: AnimatedOpacity(
                    opacity: widget.isLoading ? 0.0 : 1.0,
                    duration: AppDurations.fast,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null)
                          Padding(
                            padding: EdgeInsets.only(right: AppSpacing.sm),
                            child: Icon(
                              widget.icon,
                              color: widget.isDisabled ? AppColors.textDisabled : fgColor,
                              size: 20,
                            ),
                          ),
                        Text(
                          widget.label,
                          style: textStyle.copyWith(
                            color: widget.isDisabled ? AppColors.textDisabled : fgColor,
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
      },
    );
  }
}

/// ⏳ LOADING SPINNER
class LoadingSpinner extends StatelessWidget {
  final Color color;
  final double size;

  const LoadingSpinner({
    this.color = AppColors.thermalCool,
    this.size = 24.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 2.5,
      ),
    );
  }
}
