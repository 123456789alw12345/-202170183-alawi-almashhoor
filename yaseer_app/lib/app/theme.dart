import 'package:flutter/material.dart';

/// The visual identity shared by every Yaseer surface.
abstract final class YaseerColors {
  static const primary = Color(0xFF0F766E);
  static const primaryDark = Color(0xFF0B4F4A);
  static const background = Color(0xFFF7F9F8);
  static const surface = Color(0xFFFFFFFF);
  static const pro = Color(0xFFF4B740);

  static const ink = Color(0xFF17201F);
  static const muted = Color(0xFF63706E);
  static const outline = Color(0xFFDDE5E3);

  static const success = Color(0xFF198754);
  static const warning = Color(0xFFD98310);
  static const danger = Color(0xFFC43D4B);
  static const info = Color(0xFF2B6CB0);

  static const darkBackground = Color(0xFF0D1716);
  static const darkSurface = Color(0xFF152220);
  static const darkOutline = Color(0xFF2B3A38);
}

abstract final class YaseerSpacing {
  static const xSmall = 4.0;
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const xLarge = 32.0;
  static const section = 40.0;
}

abstract final class YaseerRadii {
  static const small = 10.0;
  static const medium = 16.0;
  static const large = 24.0;

  static const card = BorderRadius.all(Radius.circular(medium));
  static const input = BorderRadius.all(Radius.circular(medium));
}

/// Material 3 themes for Yaseer.
///
/// RTL direction is intentionally applied by the app/shell rather than the
/// theme, because [ThemeData] does not own text direction.
abstract final class YaseerTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background =
        isDark ? YaseerColors.darkBackground : YaseerColors.background;
    final surface = isDark ? YaseerColors.darkSurface : YaseerColors.surface;
    final outline = isDark ? YaseerColors.darkOutline : YaseerColors.outline;

    final scheme = ColorScheme.fromSeed(
      seedColor: YaseerColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? const Color(0xFF65D1C5) : YaseerColors.primary,
      onPrimary: isDark ? YaseerColors.primaryDark : Colors.white,
      secondary: YaseerColors.pro,
      onSecondary: const Color(0xFF302300),
      surface: surface,
      onSurface: isDark ? const Color(0xFFE5EFED) : YaseerColors.ink,
      error: YaseerColors.danger,
      outline: outline,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'NotoSansArabic',
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        height: 1.18,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.2,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -.5,
        height: 1.25,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.55),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.55),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: YaseerRadii.input,
      borderSide: BorderSide(color: outline),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: YaseerSpacing.medium,
          vertical: 15,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? const Color(0xFF9AA9A7) : YaseerColors.muted,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: YaseerRadii.card,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: YaseerRadii.card,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: outline),
          shape: const RoundedRectangleBorder(
            borderRadius: YaseerRadii.card,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: YaseerRadii.card,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: YaseerRadii.card,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: .14),
        height: 72,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: .14),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
        useIndicator: true,
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: outline),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A short alias for app entry points that prefer `AppTheme.light`.
abstract final class AppTheme {
  static ThemeData get light => YaseerTheme.light();

  static ThemeData get dark => YaseerTheme.dark();
}
