import 'package:flutter/material.dart';

/// 🎨 OURENSE TERMAL - PALETA DE COLORES MODERNA
/// Sistema de colores coherente, accesible y moderna con enfoque en diseño termal
class AppColors {
  // ━━━━━ PRIMARIOS ━━━━━
  /// Color principal oscuro para backgrounds y texto
  static const Color primaryDark = Color(0xFF1F2937);
  static const Color primaryDarkShade = Color(0xFF111827);

  /// Color primario claro para backgrounds secundarios
  static const Color primaryLight = Color(0xFFF0F9FF);

  // ━━━━━ TERMALES (SECONDARY) ━━━━━
  /// Naranja cálido representa la energía térmica
  static const Color thermalWarm = Color(0xFFEA6947);
  static const Color thermalWarmLight = Color(0xFFF97166);
  static const Color thermalWarmDark = Color(0xFFD93828);

  /// Verde menta representa el agua termal fresca
  static const Color thermalCool = Color(0xFF14B8A6);
  static const Color thermalCoolLight = Color(0xFF2DD4BF);
  static const Color thermalCoolDark = Color(0xFF0D9488);

  /// Oro representa lujo y experiencia
  static const Color thermalGold = Color(0xFFF59E0B);
  static const Color thermalGoldLight = Color(0xFFFBBF24);
  static const Color thermalGoldDark = Color(0xFFD97706);

  // ━━━━━ ACENTOS (TERTIARY) ━━━━━
  /// Azul cielo para estados activos y llamadas a acción
  static const Color accentBlue = Color(0xFF0EA5E9);
  static const Color accentBlueDark = Color(0xFF0284C7);
  static const Color accentBlueLight = Color(0xFF38BDF8);

  /// Púrpura para gamificación y achievements
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentPurpleDark = Color(0xFF7E22CE);
  static const Color accentPurpleLight = Color(0xFFC084FC);

  /// Verde para estado success y completado
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentGreenDark = Color(0xFF059669);
  static const Color accentGreenLight = Color(0xFF34D399);

  /// Rojo para estados de error/peligro
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentRedDark = Color(0xFFDC2626);
  static const Color accentRedLight = Color(0xFFF87171);

  /// Ámbar para advertencias
  static const Color accentAmber = Color(0xFFF59E0B);

  // ━━━━━ TEXTO ━━━━━
  /// Texto principal - muy oscuro
  static const Color textPrimary = Color(0xFF111827);

  /// Texto secundario - gris
  static const Color textSecondary = Color(0xFF6B7280);

  /// Texto deshabilitado - gris claro
  static const Color textDisabled = Color(0xFF9CA3AF);

  /// Texto hint - muy claro
  static const Color textHint = Color(0xFFD1D5DB);

  /// Texto sobre colores oscuros
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ━━━━━ BACKGROUNDS ━━━━━
  /// Background principal - blanco
  static const Color background = Color(0xFFFFFFFF);

  /// Superficie alternativa - gris 50
  static const Color surfaceAlt = Color(0xFFF9FAFB);

  /// Superficie secundaria - gris 100
  static const Color surface = Color(0xFFF3F4F6);

  /// Background (alias de background para compatibilidad)
  static const Color backgroundColor = Color(0xFFFFFFFF);

  // ━━━━━ BORDES & DIVISORES ━━━━━
  /// Borde principal - gris 300
  static const Color border = Color(0xFFD1D5DB);

  /// Borde suave - gris 200
  static const Color borderLight = Color(0xFFE5E7EB);

  /// Borde muy suave - gris 100
  static const Color borderLighter = Color(0xFFF3F4F6);

  /// Divisor - gris 100
  static const Color divider = Color(0xFFF3F4F6);

  // ━━━━━ ESTADOS ━━━━━
  /// Overlay semitransparente para modales y dialogs
  static const Color overlay = Color(0x80000000);

  /// Feedback de hover
  static const Color hoverOverlay = Color(0x0A000000);

  /// Feedback de tap/pressed
  static const Color pressedOverlay = Color(0x14000000);

  /// Disabled state
  static const Color disabledBg = Color(0xFFF3F4F6);

  // ━━━━━ GRADIENTES ━━━━━
  /// Gradiente principal - de termal cálido a fresco
  static const List<Color> primaryGradient = [
    thermalWarm,
    thermalGold,
    thermalCool,
  ];

  /// Gradiente para headers - azul a púrpura
  static const List<Color> headerGradient = [
    accentBlue,
    accentPurple,
  ];

  /// Gradiente para success
  static const List<Color> successGradient = [
    accentGreen,
    accentBlueLight,
  ];

  /// Gradiente para backgrounds suave
  static const List<Color> subtleGradient = [
    primaryLight,
    background,
  ];

  /// Gradiente oscuro para overlays
  static const List<Color> darkGradient = [
    Color(0x00000000),
    Color(0x80000000),
  ];
}

/// 🌈 Palette de colores por contexto (para fácil acceso)
class ColorPalette {
  /// Gamificación - Puntos y recompensas
  static const thermal = AppColors.thermalWarm;
  static const reward = AppColors.accentPurple;
  static const achievement = AppColors.thermalGold;

  /// Interacción - Acciones del usuario
  static const primary = AppColors.thermalCool;
  static const secondary = AppColors.accentBlue;
  static const accent = AppColors.thermalGold;

  /// Estado - Feedback visual
  static const success = AppColors.accentGreen;
  static const error = AppColors.accentRed;
  static const warning = AppColors.accentAmber;

  /// UI - Elementos
  static const divider = AppColors.borderLight;
  static const disabled = AppColors.textDisabled;
  static const hint = AppColors.textHint;
}
