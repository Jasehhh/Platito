import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App-wide theme built from the DESIGN.md tokens in [AppColors].
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary)
        .copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryLight,
          onPrimaryContainer: AppColors.primaryDark,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textMuted,
          surfaceContainerLowest: AppColors.surface,
          outline: AppColors.border,
          outlineVariant: AppColors.border,
          error: AppColors.error,
          errorContainer: AppColors.errorLight,
        );

    // DESIGN.md section 3: one font family, sizes and weights per role.
    const textTheme = TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(fontSize: 14),
      bodyMedium: TextStyle(fontSize: 13.5),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
      labelSmall: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),

      // Centered bar (DESIGN.md 6.3): light background, 17 bold title.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),

      // Cards: white, 1 px border, radius 18, no shadow.
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // Text fields: white, 1.5 px border, radius 14; primary on focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        errorStyle: const TextStyle(fontSize: 11),
        border: _fieldBorder(AppColors.border),
        enabledBorder: _fieldBorder(AppColors.border),
        focusedBorder: _fieldBorder(AppColors.primary),
        errorBorder: _fieldBorder(AppColors.error),
        focusedErrorBorder: _fieldBorder(AppColors.error),
      ),

      // Chips: white pill with border; selected = primary fill, white text.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
      ),

      // Primary button: primary fill, white bold 15, height 52, pill.
      filledButtonTheme: FilledButtonThemeData(style: _primaryButtonStyle()),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle(),
      ),

      // Outlined button: 1.5 px primary border, primary bold 13, pill.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      // Extended FAB: primary, radius 18.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }

  static ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(64, 52),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }
}
