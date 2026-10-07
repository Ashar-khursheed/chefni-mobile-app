import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens mirror the Chefni prototype design system.
/// Display/headings: Sora. Body/UI: Manrope.
class AppTheme {
  // ---- Core palette (from prototype) ----
  // Pink carries the brand; the logo's own pink is the primary.
  static const Color coralPrimary = Color(0xFFE85A7E);
  static const Color coralPrimaryDark = Color(0xFFC9456A);
  static const Color coralPrimaryLight = Color(0xFFF2839F);
  static const Color tealPrimary = Color(0xFF7FC4E8);
  static const Color tealDeep = Color(0xFF3E8BB8);

  static const Color bgSand = Color(0xFFF4F8FB);
  static const Color bgShell = Color(0xFFFFFFFF);
  static const Color bgWhite = Color(0xFFFFFFFF);

  static const Color darkText = Color(0xFF2E2029);
  static const Color mutedText = Color(0xFF5F7284);

  static const Color cardBorder = Color(0xFFEAE3E6);
  static const Color chipNeutral = Color(0xFFF3E4EA);
  static const Color tintTeal = Color(0xFFE3F2FB);
  static const Color tintCoral = Color(0xFFFCEDF2);
  static const Color tintGreen = Color(0xFFEAF7EE);

  static const Color successGreen = Color(0xFF4CAF6D);
  static const Color successDeep = Color(0xFF2B6B3F);
  static const Color accentGold = Color(0xFFC9932E);
  static const Color alertRed = Color(0xFFC9502E);

  // Hairline dividers / borders used across the prototype.
  static const Color hairline = Color(0x1A2E2029); // rgba(46,32,41,0.10)
  static const Color inputBorder = Color(0x242E2029); // rgba(46,32,41,0.14)

  // ---- Backward-compatible aliases (existing screens reference these) ----
  static const Color primaryPink = coralPrimary;
  static const Color primaryPinkDark = coralPrimaryDark;
  static const Color primaryPinkLight = coralPrimaryLight;
  static const Color bgOffWhite = bgSand;
  static const Color darkCocoa = bgSand;
  static const Color darkCocoaSurface = chipNeutral;
  static const Color darkCocoaCard = bgWhite;
  static const Color warmCream = darkText;
  static const Color warmCreamMuted = mutedText;
  static const Color skyBlueAccent = tealPrimary;
  static const Color skyBlueText = tealDeep;
  static const Color bgSkyBlueLight = tintTeal;
  static const Color bgCoralLight = tintCoral;

  // ---- Gradients ----
  /// Splash keeps a whisper of tint so a white ground doesn't read as a blank
  /// page while the app boots.
  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF6FAFD), Color(0xFFFDF2F6)],
    stops: [0.0, 0.45, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient logoGradient = LinearGradient(
    colors: [tealPrimary, coralPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [coralPrimary, coralPrimaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [bgWhite, Color(0xFFFDF8FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Upgrade / unlock banner — teal to coral, as in the prototype home feed.
  static const LinearGradient unlockBannerGradient = LinearGradient(
    colors: [tealPrimary, coralPrimary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ---- Type helpers ----
  /// Sora — display, headings, buttons, numerals.
  static TextStyle display({
    double size = 22,
    FontWeight weight = FontWeight.w800,
    Color color = darkText,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.sora(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Manrope — body copy, labels, inputs.
  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = darkText,
    double? height,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  // ---- Shadows ----
  // Cards sit on a white shell now, so elevation — not fill — is what
  // separates them. Tinted with the ink colour rather than pure black.
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(color: Color(0x0D2E2029), blurRadius: 3, offset: Offset(0, 1)),
      ];

  static List<BoxShadow> get softShadow => const [
        BoxShadow(color: Color(0x0F2E2029), blurRadius: 8, offset: Offset(0, 2)),
      ];

  static List<BoxShadow> get heroShadow => const [
        BoxShadow(color: Color(0x1A2E2029), blurRadius: 24, offset: Offset(0, 8)),
      ];

  static List<BoxShadow> coralGlow([double opacity = 0.35]) => [
        BoxShadow(
          color: coralPrimary.withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: coralPrimary,
      scaffoldBackgroundColor: bgShell,
      splashColor: coralPrimary.withValues(alpha: 0.08),
      highlightColor: coralPrimary.withValues(alpha: 0.04),
      colorScheme: const ColorScheme.light(
        primary: coralPrimary,
        secondary: tealPrimary,
        surface: bgWhite,
        error: alertRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkText,
      ),
      textTheme: TextTheme(
        displayLarge: display(size: 32),
        displayMedium: display(size: 24),
        displaySmall: display(size: 22),
        headlineMedium: display(size: 19),
        headlineSmall: display(size: 17),
        titleLarge: display(size: 15, weight: FontWeight.w700),
        titleMedium: display(size: 13.5, weight: FontWeight.w700),
        bodyLarge: body(size: 15, height: 1.5),
        bodyMedium: body(size: 14, color: mutedText, height: 1.5),
        bodySmall: body(size: 12, color: mutedText),
        labelLarge: display(size: 14.5, weight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgShell,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkText),
        titleTextStyle: display(size: 19),
      ),
      cardTheme: CardThemeData(
        color: bgWhite,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipNeutral,
        selectedColor: coralPrimary,
        labelStyle: display(size: 13.5, weight: FontWeight.w700),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: hairline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: inputBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tealPrimary, width: 1.5),
        ),
        labelStyle: body(size: 14, color: mutedText),
        hintStyle: body(size: 14.5, color: mutedText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coralPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: display(size: 15, weight: FontWeight.w700, color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          side: const BorderSide(color: inputBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: display(size: 14, weight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tealPrimary,
          textStyle: display(size: 13, weight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? tealPrimary : cardBorder,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgWhite,
        selectedItemColor: coralPrimary,
        unselectedItemColor: mutedText,
        selectedLabelStyle: display(size: 10, weight: FontWeight.w700),
        unselectedLabelStyle: display(size: 10, weight: FontWeight.w700),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
