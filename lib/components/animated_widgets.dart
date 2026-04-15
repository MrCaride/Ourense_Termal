import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// ✨ ANIMATED LIST ITEM - Item con animación de entrada para listas
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final AnimationType animationType;

  const AnimatedListItem({
    Key? key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 0),
    this.duration = const Duration(milliseconds: 400),
    this.animationType = AnimationType.fadeSlide,
  }) : super(key: key);

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

enum AnimationType { fadeSlide, fadeScale, slideUp, fade }

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animationType) {
      case AnimationType.fadeSlide:
        return FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _offsetAnimation,
            child: widget.child,
          ),
        );
      case AnimationType.fadeScale:
        return FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.child,
          ),
        );
      case AnimationType.slideUp:
        return SlideTransition(
          position: _offsetAnimation,
          child: widget.child,
        );
      case AnimationType.fade:
        return FadeTransition(
          opacity: _opacityAnimation,
          child: widget.child,
        );
    }
  }
}

/// 🔄 ANIMATED TAB INDICATOR - Custom indicator para tabs
class AnimatedTabIndicator extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final Color? indicatorColor;

  const AnimatedTabIndicator({
    Key? key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.indicatorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onTabChanged(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[index],
                    style: isSelected
                        ? AppTypography.labelLarge.copyWith(
                            color: indicatorColor ?? AppColors.thermalCool,
                          )
                        : AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    width: isSelected ? 30 : 0,
                    decoration: BoxDecoration(
                      color: indicatorColor ?? AppColors.thermalCool,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// ✨ ANIMATED EMPTY STATE - Estado vacío elegante
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final Color? iconColor;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.iconColor,
  }) : super(key: key);

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.05).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (widget.iconColor ?? AppColors.thermalCool)
                    .withValues(alpha: 0.1),
              ),
              child: Icon(
                widget.icon,
                size: 40,
                color: widget.iconColor ?? AppColors.thermalCool,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            widget.title,
            style: AppTypography.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (widget.description != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Text(
                widget.description!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (widget.action != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: widget.action,
            ),
        ],
      ),
    );
  }
}

/// 🔔 TOAST NOTIFICATION - Notificaciones flotantes
enum ToastType { success, error, warning, info }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final color = _getColorForType(type);
    final icon = _getIconForType(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 8,
        margin: EdgeInsets.all(AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
      ),
    );
  }

  static Color _getColorForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return AppColors.accentGreen;
      case ToastType.error:
        return AppColors.accentRed;
      case ToastType.warning:
        return AppColors.accentAmber;
      case ToastType.info:
        return AppColors.accentBlue;
    }
  }

  static IconData _getIconForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
    }
  }
}

/// ✨ SHIMMER LOADING - Efecto skeleton loading
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 - (_controller.value * 2), 0),
              end: Alignment(1, 0),
              colors: [
                AppColors.surfaceAlt,
                AppColors.background,
                AppColors.surfaceAlt,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}
