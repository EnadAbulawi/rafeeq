import 'package:flutter/material.dart';

abstract final class AppColors {
  static const forest = Color(0xFF315C52);
  static const ivory = Color(0xFFF8F7F3);
  static const sage = Color(0xFFE8EEE8);
  static const sand = Color(0xFFD8C7AA);
  static const ink = Color(0xFF242B28);
}

abstract final class AppSpacing {
  static const small = 8.0, medium = 16.0, page = 20.0, large = 24.0;
}

abstract final class AppLayout {
  static const maxWidth = 720.0;
  static double gutter(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360 ? 16 : 20;
  static EdgeInsets pagePadding(BuildContext context) =>
      EdgeInsets.fromLTRB(gutter(context), 16, gutter(context), 24);
}

abstract final class AppRadius {
  static const card = 20.0, large = 24.0;
}

abstract final class AppTypography {
  static const sacred = TextStyle(fontFamily: 'Amiri', fontSize: 28, height: 2);
}

abstract final class AppTheme {
  static ThemeData create(bool dark, {String fontFamily = 'IBMPlexArabic'}) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.forest,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: dark ? const Color(0xFFA2D0C3) : AppColors.forest,
          onPrimary: dark ? const Color(0xFF163B32) : Colors.white,
          surface: dark ? const Color(0xFF1F2623) : Colors.white,
          onSurface: dark ? const Color(0xFFEAE6DF) : AppColors.ink,
          onSurfaceVariant: dark
              ? const Color(0xFF9CA7A1)
              : const Color(0xFF626C65),
          outlineVariant: dark
              ? const Color(0xFF333F3A)
              : const Color(0xFFE2E5E1),
          secondaryContainer: dark ? const Color(0xFF2A3430) : AppColors.sage,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.7),
        bodyMedium: TextStyle(fontSize: 14, height: 1.65),
        bodySmall: TextStyle(fontSize: 12, height: 1.6),
        labelLarge: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        labelMedium: TextStyle(fontSize: 12, height: 1.4, letterSpacing: 0),
      ),
      scaffoldBackgroundColor: dark ? const Color(0xFF161D1A) : AppColors.ivory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.primary, size: 22),
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.secondaryContainer,
        checkmarkColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          height: 1.4,
          color: scheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          height: 1.6,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          height: 1.6,
          color: scheme.onSurfaceVariant,
        ),
        minVerticalPadding: 12,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 24,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearMinHeight: 4,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: scheme.outlineVariant,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 10,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
