import 'package:flutter/material.dart';

/// Paleta y tema de la app, según el mockup entregado por el cliente:
/// azul corporativo #1E3A8A sobre fondos slate claros, AppBar blanca,
/// navegación inferior, tarjetas redondeadas y píldoras de estado con color.
class AppColors {
  AppColors._();

  // --- Marca ---
  static const Color primary = Color(0xFF1E3A8A); // azul corporativo
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primarySoft = Color(0xFFDBEAFE); // blue-100 (pill activo)

  // --- Superficies / fondos ---
  static const Color bg = Color(0xFFF8FAFC); // slate-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color sectionBg = Color(0xFFF1F5F9); // slate-100
  static const Color fieldFill = Color(0xFFF8FAFC); // slate-50

  // --- Líneas / bordes ---
  static const Color border = Color(0xFFE2E8F0); // slate-200
  static const Color borderStrong = Color(0xFFCBD5E1); // slate-300

  // --- Texto ---
  static const Color textStrong = Color(0xFF1F2937); // gray-800
  static const Color textBody = Color(0xFF334155); // slate-700
  static const Color textMuted = Color(0xFF64748B); // slate-500
  static const Color iconMuted = Color(0xFF94A3B8); // slate-400

  // --- Etiquetas / acentos (compatibilidad con código existente) ---
  static const Color label = primary;
  static const Color steel = primary;
  static const Color slate = textStrong;
  static const Color slateDark = textStrong;
  static const Color inactive = Color(0xFFE2E8F0);
  static const Color accent = Color(0xFF16A34A); // green-600
  static const Color editable = Color(0xFFDC2626); // red-600

  // --- Colores semánticos suaves (píldoras: fondo-50 / texto / borde-200) ---
  static const SemanticColors danger = SemanticColors(
      bg: Color(0xFFFEF2F2), fg: Color(0xFFDC2626), border: Color(0xFFFECACA));
  static const SemanticColors success = SemanticColors(
      bg: Color(0xFFF0FDF4), fg: Color(0xFF15803D), border: Color(0xFFBBF7D0));
  static const SemanticColors warning = SemanticColors(
      bg: Color(0xFFFFF7ED), fg: Color(0xFFEA580C), border: Color(0xFFFED7AA));
  static const SemanticColors info = SemanticColors(
      bg: Color(0xFFEFF6FF), fg: Color(0xFF1D4ED8), border: Color(0xFFBFDBFE));
  static const SemanticColors neutral = SemanticColors(
      bg: Color(0xFFF1F5F9), fg: Color(0xFF475569), border: Color(0xFFE2E8F0));

  static SemanticColors semantic(PillKind kind) => switch (kind) {
        PillKind.danger => danger,
        PillKind.success => success,
        PillKind.warning => warning,
        PillKind.info => info,
        PillKind.neutral => neutral,
      };
}

/// Tipos de píldora semántica.
enum PillKind { danger, success, warning, info, neutral }

class SemanticColors {
  const SemanticColors(
      {required this.bg, required this.fg, required this.border});
  final Color bg;
  final Color fg;
  final Color border;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Inter',
      useMaterial3: true,
    );

    OutlineInputBorder borderSide(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      visualDensity: VisualDensity.compact,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textStrong,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        elevation: 3,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: AppColors.cardBg,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.06),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: AppColors.fieldFill,
        border: borderSide(AppColors.borderStrong),
        enabledBorder: borderSide(AppColors.borderStrong),
        focusedBorder: borderSide(AppColors.primary, 1.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.iconMuted),
        labelStyle: const TextStyle(color: AppColors.textMuted),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.sectionBg,
        side: BorderSide.none,
        labelStyle: const TextStyle(fontSize: 11.5, color: AppColors.textBody),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }
}
