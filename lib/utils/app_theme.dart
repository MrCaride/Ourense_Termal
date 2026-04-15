import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// 🎨 APP THEME - Sistema de tema global moderno
/// Utiliza Design Tokens de AppColors, AppTypography, AppSpacing
class AppTheme {
  // ━━━━━ LEGACY SUPPORT (para compatibilidad) ━━━━━
  static const Color brandTeal = AppColors.thermalCool;
  static const Color brandCyan = AppColors.accentBlue;
  static const Color brandSand = AppColors.thermalGold;
  static const Color brandSlate = AppColors.primaryDark;
  static const Color brandSoft = AppColors.surfaceAlt;

  static final LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.headerGradient,
  );

  /// 🌞 Tema claro (Light Theme) - Principal
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.thermalCool,
      brightness: Brightness.light,
      primary: AppColors.thermalCool,
      secondary: AppColors.accentBlue,
      surface: AppColors.background,
      onSurface: AppColors.primaryDark,
      error: AppColors.accentRed,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(),
    );

    return base.copyWith(
      // ━━━━━ CARD THEME ━━━━━
      cardTheme: CardThemeData(
        color: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ━━━━━ APP BAR THEME ━━━━━
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: AppTypography.appBarTitle,
        toolbarHeight: AppSizes.appBarHeight,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
      ),

      // ━━━━━ NAVIGATION BAR THEME ━━━━━
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.thermalCool.withValues(alpha: 0.12),
        height: AppSizes.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.all(
          AppTypography.labelSmall,
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: AppColors.thermalCool,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.textSecondary,
            size: 24,
          );
        }),
      ),

      // ━━━━━ INPUT DECORATION THEME ━━━━━
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: AppSpacing.paddingInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: AppColors.thermalCool,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.accentRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: AppColors.accentRed,
            width: 2,
          ),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textHint,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.accentRed,
        ),
      ),

      // ━━━━━ FILLED BUTTON THEME ━━━━━
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.thermalCool,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(0, AppSizes.buttonHeightMedium),
          textStyle: AppTypography.buttonText,
          elevation: 0,
          shadowColor: Colors.transparent,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.thermalCool.withValues(alpha: 0.9);
            }
            if (states.contains(WidgetState.disabled)) {
              return AppColors.disabledBg;
            }
            return AppColors.thermalCool;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textDisabled;
            }
            return Colors.white;
          }),
        ),
      ),

      // ━━━━━ OUTLINED BUTTON THEME ━━━━━
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.thermalCool,
          side: BorderSide(color: AppColors.thermalCool),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(0, AppSizes.buttonHeightMedium),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // ━━━━━ TEXT BUTTON THEME ━━━━━
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.thermalCool,
          textStyle: AppTypography.buttonText,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      // ━━━━━ CHIP THEME ━━━━━
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide(color: AppColors.border),
        ),
        labelStyle: AppTypography.labelMedium,
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.thermalCool.withValues(alpha: 0.12),
      ),

      // ━━━━━ DIALOG THEME ━━━━━
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.displaySmall,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // ━━━━━ SNACK BAR THEME ━━━━━
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      // ━━━━━ FLOATING ACTION BUTTON THEME ━━━━━
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.thermalCool,
        foregroundColor: Colors.white,
        elevation: 8,
        hoverElevation: 12,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        sizeConstraints: BoxConstraints.tight(
          const Size(AppSizes.fabSizeMedium, AppSizes.fabSizeMedium),
        ),
      ),

      // ━━━━━ DIVIDER THEME ━━━━━
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: AppSpacing.lg,
      ),

      // ━━━━━ BOTTOM SHEET THEME ━━━━━
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.background,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.border,
      ),

      // ━━━━━ LIST TILE THEME ━━━━━
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        horizontalTitleGap: AppSpacing.lg,
      ),
    );
  }

  /// Construir TextTheme personalizado
  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      displaySmall: AppTypography.displaySmall,
      headlineMedium: AppTypography.titleLarge,
      headlineSmall: AppTypography.titleMedium,
      titleLarge: AppTypography.titleSmall,
      titleMedium: AppTypography.bodyLarge,
      titleSmall: AppTypography.bodyMedium,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    );
  }
}
