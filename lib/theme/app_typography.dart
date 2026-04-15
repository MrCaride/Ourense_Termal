import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// 📝 TIPOGRAFÍA MODERNA - SISTEMA DE ESTILOS
class AppTypography {
  // ━━━━━ FONT FAMILY ━━━━━
  static TextStyle get _baseFont {
    return GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontFeatures: const [FontFeature.proportionalFigures()],
    );
  }

  static TextStyle get _baseMontserat {
    return GoogleFonts.montserrat(
      color: AppColors.textPrimary,
    );
  }

  // ━━━━━ DISPLAY & HEADLINES ━━━━━
  /// Display Large - 32px, Bold (700) - Para títulos principales
  static TextStyle get displayLarge {
    return _baseMontserat.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  /// Display Medium - 28px, Bold (700) - Para headers de sección
  static TextStyle get displayMedium {
    return _baseMontserat.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.3,
    );
  }

  /// Display Small - 24px, Bold (700)
  static TextStyle get displaySmall {
    return _baseMontserat.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: -0.15,
    );
  }

  // ━━━━━ TÍTULOS ━━━━━
  /// Title Large - 22px, SemiBold (600) - Card titles principales
  static TextStyle get titleLarge {
    return _baseFont.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 0.1,
    );
  }

  /// Title Medium - 18px, SemiBold (600) - Subtítulos
  static TextStyle get titleMedium {
    return _baseFont.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.45,
      letterSpacing: 0.2,
    );
  }

  /// Title Small - 16px, SemiBold (600) - Labels en componentes
  static TextStyle get titleSmall {
    return _baseFont.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.15,
    );
  }

  // ━━━━━ BODY ━━━━━
  /// Body Large - 16px, Regular (400) - Contenido principal
  static TextStyle get bodyLarge {
    return _baseFont.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.1,
    );
  }

  /// Body Medium - 14px, Regular (400) - Texto estándar
  static TextStyle get bodyMedium {
    return _baseFont.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.6,
      letterSpacing: 0.2,
    );
  }

  /// Body Small - 12px, Regular (400) - Texto pequeño
  static TextStyle get bodySmall {
    return _baseFont.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.1,
    );
  }

  // ━━━━━ LABELS & CAPTIONS ━━━━━
  /// Label Large - 14px, SemiBold (600) - Botones, badges
  static TextStyle get labelLarge {
    return _baseFont.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 0.1,
    );
  }

  /// Label Medium - 12px, SemiBold (600) - Tags, labels
  static TextStyle get labelMedium {
    return _baseFont.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.4,
    );
  }

  /// Label Small - 11px, SemiBold (600) - Captions, hints
  static TextStyle get labelSmall {
    return _baseFont.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.5,
    );
  }

  // ━━━━━ CUSTOM VARIANTS ━━━━━
  /// Button Text - Centrado en botones
  static TextStyle get buttonText {
    return _baseFont.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 0.1,
    );
  }

  /// App Bar Title - Large title en app bars
  static TextStyle get appBarTitle {
    return _baseMontserat.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.4,
      letterSpacing: 0,
    );
  }

  /// Card Title - Títulos en cards
  static TextStyle get cardTitle {
    return _baseFont.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 0.1,
    );
  }

  /// Badge Text - Badges y pills
  static TextStyle get badgeText {
    return _baseFont.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.04,
    );
  }

  // ━━━━━ VARIANTS CON COLOR ━━━━━
  /// Encabezado principal con degradado (visual benefit)
  static TextStyle get headingAccent {
    return displayMedium.copyWith(
      color: AppColors.thermalCool,
      fontWeight: FontWeight.w800,
    );
  }

  /// Texto secundario deshabilitado
  static TextStyle get bodySoft {
    return bodyMedium.copyWith(
      color: AppColors.textSecondary,
    );
  }

  /// Texto de error
  static TextStyle get bodyError {
    return bodyMedium.copyWith(
      color: AppColors.accentRed,
    );
  }

  /// Texto de éxito
  static TextStyle get bodySuccess {
    return bodyMedium.copyWith(
      color: AppColors.accentGreen,
    );
  }

  // ━━━━━ HELPERS ━━━━━
  /// Aplicar color a cualquier estilo
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Aplicar opacity a cualquier estilo
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(
      color: style.color?.withOpacity(opacity),
    );
  }
}

/// 📏 EXTENSIÓN PARA TEXT THEME EN BUILD CONTEXT
extension TextThemeExtension on TextTheme {
  /// Alias para fluent access
  TextStyle get cardTitle => AppTypography.cardTitle;
  TextStyle get badgeText => AppTypography.badgeText;
  TextStyle get buttonText => AppTypography.buttonText;
  TextStyle get bodySoft => AppTypography.bodySoft;
}
