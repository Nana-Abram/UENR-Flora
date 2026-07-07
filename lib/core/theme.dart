import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// COLOUR TOKENS — import this file wherever colours are needed.
// Never hardcode hex values in widget files.
// ─────────────────────────────────────────────────────────────

// Primary brand — values match the Figma design tokens (--primary, --secondary,
// --accent, --chart-4) exactly, so the app's palette stays in lockstep with Figma.
const Color kDeep    = Color(0xFF1A3C2D); // chart-4 — deepest green, hero/dark headers
const Color kGreen   = Color(0xFF2D6A4F); // --primary — buttons, links, primary accents
const Color kLight   = Color(0xFFD8EFDE); // --secondary — fact cards, tip backgrounds
const Color kMint    = Color(0xFF95D5B2); // --chart-3 / --switch-background — subtext on dark green

// CTA / Action — primary buttons and highlights use the Figma accent green
const Color kAccent  = Color(0xFF52B788); // --accent / --chart-2
const Color kAccentL = Color(0xFFE3F5EC); // light tint of --accent, for icon backgrounds

// Page surfaces
const Color kBg      = Color.fromARGB(255, 228, 255, 243); // --background — mint-tinted off-white page bg
const Color kWhite   = Color(0xFFFFFFFF); // --card — card backgrounds only
const Color kMuted   = Color(0xFFEAF3EC); // --muted / --input-background
const Color kDark    = Color(0xFF1A1A1A); // near-black — footer background

// Text
const Color kTx      = Color(0xFF1A2E1A); // --foreground — primary text
const Color kMu      = Color(0xFF5C7A5C); // --muted-foreground — secondary text

// Borders
const Color kBorder  = Color(0x262D6A4F); // --border — primary green @ 15% opacity

// Health status pills
const Color kHealthyBg   = kLight;
const Color kHealthyTx   = kGreen;
const Color kUnhealthyBg = Color(0xFFFBE4E8); // light tint of --destructive
const Color kUnhealthyTx = Color(0xFFD4183D); // --destructive

// Quiz option states (post-submit)
const Color kQuizCorrectBg = Color(0x4D2EA05A); // 30 % green
const Color kQuizCorrectBd = Color(0xFF52B788);
const Color kQuizWrongBg   = Color(0x33DC3545); // 20 % red
const Color kQuizWrongBd   = Color(0xFFE24B4A);

// ─────────────────────────────────────────────────────────────
// TYPOGRAPHY
// Fonts: Space Grotesk (headings) + Inter (body), bundled locally
// under assets/fonts/ — see pubspec.yaml. No Google Fonts CDN
// fetch at runtime.
// Weights used: 400 (regular) and 500 (medium). NEVER 600 or 700.
// ─────────────────────────────────────────────────────────────
const String kFontDisplay = 'Space Grotesk';
const String kFontBody    = 'Inter';

// Text style helpers — use these directly in widgets
TextStyle kDisplay(BuildContext ctx) =>
    const TextStyle(fontFamily: kFontDisplay, fontSize: 28, fontWeight: FontWeight.w500);

TextStyle kH1(BuildContext ctx) =>
    const TextStyle(fontFamily: kFontDisplay, fontSize: 22, fontWeight: FontWeight.w500, color: kTx);

TextStyle kH2(BuildContext ctx) =>
    const TextStyle(fontFamily: kFontDisplay, fontSize: 18, fontWeight: FontWeight.w500, color: kTx);

TextStyle kH3(BuildContext ctx) =>
    const TextStyle(fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: kTx);

TextStyle kBody(BuildContext ctx) =>
    const TextStyle(fontFamily: kFontBody, fontSize: 14, fontWeight: FontWeight.w400, color: kTx);

TextStyle kSmall(BuildContext ctx) =>
    const TextStyle(fontFamily: kFontBody, fontSize: 13, fontWeight: FontWeight.w400, color: kTx);

TextStyle kXSmall(BuildContext ctx) =>
    const TextStyle(fontFamily: kFontBody, fontSize: 12, fontWeight: FontWeight.w400, color: kMu);

TextStyle kLabel(BuildContext ctx) =>
    const TextStyle(fontFamily: kFontBody, fontSize: 11, fontWeight: FontWeight.w500,
        color: kMu, letterSpacing: 0.5);

TextStyle kMicro(BuildContext ctx) =>
    const TextStyle(fontFamily: kFontBody, fontSize: 10, fontWeight: FontWeight.w400, color: kMu);

// ─────────────────────────────────────────────────────────────
// SPACING — use these constants, not raw numbers in widgets
// ─────────────────────────────────────────────────────────────
const double kSp4  = 4;
const double kSp8  = 8;
const double kSp12 = 12;
const double kSp16 = 16;
const double kSp20 = 20;
const double kSp24 = 24;  // standard horizontal page padding
const double kSp32 = 32;
const double kSp36 = 36;  // standard section vertical padding
const double kSp44 = 44;  // hero section padding

// ─────────────────────────────────────────────────────────────
// BORDER RADIUS
// ─────────────────────────────────────────────────────────────
const double kRadiusSm   = 8;
const double kRadiusMd   = 10;
const double kRadiusLg   = 12;
const double kRadiusXl   = 14;
const double kRadius2xl  = 16;
const double kRadiusPill = 20;

BorderRadius kBR(double r) => BorderRadius.circular(r);
BorderRadius get kBRSm   => BorderRadius.circular(kRadiusSm);
BorderRadius get kBRMd   => BorderRadius.circular(kRadiusMd);
BorderRadius get kBRLg   => BorderRadius.circular(kRadiusLg);
BorderRadius get kBRXl   => BorderRadius.circular(kRadiusXl);
BorderRadius get kBR2xl  => BorderRadius.circular(kRadius2xl);
BorderRadius get kBRPill => BorderRadius.circular(kRadiusPill);

// ─────────────────────────────────────────────────────────────
// THEME DATA
// ─────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, colorSchemeSeed: kDeep);
  final textTheme = base.textTheme.apply(fontFamily: kFontBody).copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(fontFamily: kFontDisplay),
        displayMedium: base.textTheme.displayMedium?.copyWith(fontFamily: kFontDisplay),
        displaySmall: base.textTheme.displaySmall?.copyWith(fontFamily: kFontDisplay),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(fontFamily: kFontDisplay),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(fontFamily: kFontDisplay),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontFamily: kFontDisplay),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontFamily: kFontDisplay),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontFamily: kFontDisplay),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontFamily: kFontDisplay),
      );

  return base.copyWith(
    scaffoldBackgroundColor: kBg,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kDeep,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: kDeep),
    ),
    cardTheme: CardThemeData(
      color: kWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: kBRXl,
        side: const BorderSide(color: kBorder, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kGreen,       // ALL primary buttons use the Figma primary green
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: kBRSm),
        textStyle: const TextStyle(
            fontFamily: kFontBody, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTx,
        side: const BorderSide(color: kBorder, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: kBRSm),
        textStyle: const TextStyle(
            fontFamily: kFontBody, fontSize: 13, fontWeight: FontWeight.w400),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kMu,
        textStyle: const TextStyle(
            fontFamily: kFontBody, fontSize: 12, fontWeight: FontWeight.w400),
      ),
    ),
    dividerTheme: const DividerThemeData(color: kBorder, thickness: 0.5),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kWhite,
      border: OutlineInputBorder(
        borderRadius: kBRLg,
        borderSide: const BorderSide(color: kBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: kBRLg,
        borderSide: const BorderSide(color: kBorder, width: 0.5),
      ),
      hintStyle: const TextStyle(fontFamily: kFontBody, fontSize: 13, color: kMu),
    ),
  );
}
