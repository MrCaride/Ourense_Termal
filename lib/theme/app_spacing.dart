import 'package:flutter/material.dart';

/// 📐 SISTEMA DE ESPACIADO Y DIMENSIONES
class AppSpacing {
  // ━━━━━ ESPACIADO BASE ━━━━━
  static const double xs = 4.0;    // Espaciado mínimo (2px gaps)
  static const double sm = 8.0;    // Espaciado pequeño
  static const double md = 12.0;   // Espaciado medio
  static const double lg = 16.0;   // Espaciado largo (estándar)
  static const double xl = 24.0;   // Espaciado extra large
  static const double xxl = 32.0;  // Espaciado 2x large
  static const double xxxl = 48.0; // Espaciado 3x large

  // ━━━━━ ALIASES ÚTILES ━━━━━
  static const double none = 0.0;
  static const double tiny = xs;
  static const double small = sm;
  static const double medium = md;
  static const double large = lg;
  static const double huge = xl;

  // ━━━━━ PADDING COMÚN ━━━━━
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  // ━━━━━ PADDING HORIZONTAL ━━━━━
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // ━━━━━ PADDING VERTICAL ━━━━━
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);

  // ━━━━━ PADDING CUSTOM ━━━━━
  static const EdgeInsets paddingCard = EdgeInsets.all(lg);
  static const EdgeInsets paddingScreen = EdgeInsets.all(lg);
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets paddingInput = EdgeInsets.symmetric(horizontal: md, vertical: sm);
}

/// 🔲 SISTEMA DE BORDER RADIUS
class AppRadius {
  // ━━━━━ BORDER RADIUS BASE ━━━━━
  static const double xs = 4.0;      // Minimal rounding
  static const double sm = 8.0;      // Small corners
  static const double md = 12.0;     // Medium corners (estándar)
  static const double lg = 16.0;     // Large corners
  static const double xl = 24.0;     // Extra large corners
  static const double xxl = 32.0;    // 2x large corners
  static const double full = 48.0;   // Pill/fully rounded

  // ━━━━━ BORDER RADIUS COMUNES ━━━━━
  static final BorderRadius radiusXs = BorderRadius.circular(xs);
  static final BorderRadius radiusSm = BorderRadius.circular(sm);
  static final BorderRadius radiusMd = BorderRadius.circular(md);
  static final BorderRadius radiusLg = BorderRadius.circular(lg);
  static final BorderRadius radiusXl = BorderRadius.circular(xl);
  static final BorderRadius radiusXxl = BorderRadius.circular(xxl);
  static final BorderRadius radiusFull = BorderRadius.circular(full);

  // ━━━━━ ALIASES ━━━━━
  static const double card = lg;
  static const double button = md;
  static const double input = sm;
  static const double badge = xs;
}

/// ⬜ TAMAÑOS DE COMPONENTES
class AppSizes {
  // ━━━━━ BOTONES ━━━━━
  static const double buttonHeightLarge = 56.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightSmall = 36.0;

  // ━━━━━ ICONOS ━━━━━
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ━━━━━ APP BAR ━━━━━
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 120.0;

  // ━━━━━ BOTTOM NAVIGATION ━━━━━
  static const double bottomNavHeight = 80.0;

  // ━━━━━ FLOATING ACTION BUTTON ━━━━━
  static const double fabSizeMedium = 56.0;
  static const double fabSizeLarge = 72.0;

  // ━━━━━ TARJETAS ━━━━━
  static const double cardMinHeight = 100.0;
  static const double cardMaxWidth = 300.0;

  // ━━━━━ MODAL ━━━━━
  static const double modalMinHeight = 200.0;
  static const double modalMaxWidth = 500.0;

  // ━━━━━ CHIPS & TAGS ━━━━━
  static const double chipHeight = 32.0;
}

/// 🌊 SISTEMA DE SOMBRAS
class AppShadows {
  // ━━━━━ SOMBRAS MATERIAL ━━━━━
  
  /// Sombra Elevation 1 - Cards, chips (suave)
  static final List<BoxShadow> elevation1 = const [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  /// Sombra Elevation 2 - Cards elevadas, floating elements
  // Changed from const to static final
  static final List<BoxShadow> elevation2 = const [
    BoxShadow(
      color: Color(0x24000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  /// Sombra Elevation 3 - Modals, dropdowns (prominente)
  static final List<BoxShadow> elevation3 = const [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 10),
      blurRadius: 30,
      spreadRadius: 0,
    ),
  ];

  /// Sombra Elevation 4 - FAB, sistema importante
  static final List<BoxShadow> elevation4 = const [
    BoxShadow(
      color: Color(0x2E000000),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  // ━━━━━ SOMBRAS SUAVES ━━━━━
  
  /// Sombra muy suave - Texto debajo de imagen
  static final List<BoxShadow> subtle = const [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Sombra interna - Para efectos de profundidad
  static final List<BoxShadow> inset = const [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, -2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  // ━━━━━ SOMBRAS CON COLOR ━━━━━
  
  /// Sombra térmica cálida (naranja)
  static final List<BoxShadow> thermalWarmShadow = const [
    BoxShadow(
      color: Color(0x40EA6947),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// Sombra térmica fresca (menta)
  static final List<BoxShadow> thermalCoolShadow = const [
    BoxShadow(
      color: Color(0x4014B8A6),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// Sombra de éxito (verde)
  static final List<BoxShadow> successShadow = const [
    BoxShadow(
      color: Color(0x4010B981),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// Sombra de error (rojo)
  static final List<BoxShadow> errorShadow = const [
    BoxShadow(
      color: Color(0x40EF4444),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  // ━━━━━ SOMBRA PARA FLOATING ELEMENTS ━━━━━
  static final List<BoxShadow> floating = elevation3;

  // ━━━━━ SOMBRA PARA FOCUS STATE ━━━━━
  static List<BoxShadow> focus(Color focusColor) => [
    BoxShadow(
      color: focusColor.withOpacity(0.3),
      offset: Offset.zero,
      blurRadius: 8,
      spreadRadius: 2,
    ),
  ];
}

/// 🔄 DURACIONES DE ANIMACIONES
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  static const Duration longest = Duration(milliseconds: 1200);

  // Curvas
  static const Curve easeOutCubic = Cubic(0.215, 0.61, 0.355, 1);
  static const Curve easeInOutCubic = Cubic(0.645, 0.045, 0.355, 1);
  static const Curve easeOutQuad = Cubic(0.25, 0.46, 0.45, 0.94);
  static const Curve bounceOut = Cubic(0.68, -0.55, 0.265, 1.55);
}
