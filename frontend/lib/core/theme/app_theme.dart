import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.orange,
        onPrimary: Colors.white,
        secondary: AppColors.orangeSoft,
        onSecondary: AppColors.ink,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.error,
        outline: AppColors.line,
      ),
    );

    final materialText = base.textTheme;
    final textTheme = (GoogleFonts.config.allowRuntimeFetching
            ? GoogleFonts.poppinsTextTheme(materialText)
            : materialText)
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          displayLarge: materialText.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 30,
            height: 1.2,
            color: AppColors.ink,
          ),
          headlineMedium: materialText.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            height: 1.25,
            color: AppColors.ink,
          ),
          titleLarge: materialText.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.ink,
          ),
          titleMedium: materialText.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.ink,
          ),
          bodyLarge: materialText.bodyLarge?.copyWith(
            fontSize: 15,
            height: 1.45,
            color: AppColors.ink,
          ),
          bodyMedium: materialText.bodyMedium?.copyWith(
            fontSize: 13.5,
            height: 1.4,
            color: AppColors.inkMuted,
          ),
          labelLarge: materialText.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line, width: 1.4),
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.orange),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.line),
        ),
        shadowColor: AppColors.ink.withValues(alpha: 0.08),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.orangeSoft,
        selectedColor: AppColors.orange,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.ink),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: Colors.white,
        ),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shadowColor: AppColors.ink.withValues(alpha: 0.06),
        height: 70,
        indicatorColor: AppColors.orangeSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.orange : AppColors.inkMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.orange : AppColors.inkMuted,
            size: 24,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    );
  }
}
