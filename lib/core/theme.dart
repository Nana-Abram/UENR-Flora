import 'package:flutter/material.dart';
import 'app_brightness.dart';

// ─────────────────────────────────────────────────────────────
// COLOUR TOKENS — import this file wherever colours are needed.
// Never hardcode hex values in widget files.
//
// DARK MODE: every token below is a *getter*, not a `const`, and resolves
// against [AppBrightness.isDark] — set by [ThemeModeProvider], the app's
// single source of truth for light/dark/system. This lets every widget in
// the app keep writing `color: kTx` exactly as before; nothing needed a
// BuildContext threaded through just to pick a color. The tradeoff: none
// of these can be used inside a `const` expression anymore (a `const
// TextStyle(color: kTx)` won't compile, since kTx is no longer a
// compile-time constant) — remove the `const` keyword at each call site
// the analyzer flags, which is a purely mechanical, behavior-preserving
// fix in light mode and is what actually makes dark mode responsive
// (Flutter skips rebuilding `const` widgets on ancestor rebuilds, so a
// `const`-marked color reference would otherwise never update on toggle).
//
// Some tokens are deliberately IDENTICAL across both themes — kDeep, kMint,
// and kDark are all "this is a dark green/near-black surface" colors used
// for hero blocks and the footer that already look correct regardless of
// the surrounding page's overall light/dark mode, the same way a photo's
// black frame doesn't need to change with the wall color around it. The
// quiz-state overlay colors (kQuizCorrectBg etc.) are also kept constant —
// they're translucent highlights over an existing surface, not solid
// surfaces themselves, so they read fine layered over either theme's card
// color without a bespoke dark variant.
// ─────────────────────────────────────────────────────────────

// Primary brand — light-mode values match the Figma design tokens
// (--primary, --secondary, --accent, --chart-4) exactly, so the light
// palette stays in lockstep with Figma. Dark-mode values are this app's
// own derived palette (no Figma dark spec exists) — same hues, adjusted
// for contrast against dark surfaces.
const Color _kDeepBoth = Color(0xFF1A3C2D); // chart-4 — deepest green, hero/dark headers (same both themes)
Color get kDeep => _kDeepBoth;

const Color _kGreenLight = Color(0xFF2D6A4F); // --primary — buttons, links, primary accents
const Color _kGreenDark  = Color(0xFF4FAE81); // brighter for contrast as text/links on dark surfaces
Color get kGreen => AppBrightness.isDark ? _kGreenDark : _kGreenLight;

const Color _kLightLight = Color(0xFFD8EFDE); // --secondary — fact cards, tip backgrounds
const Color _kLightDark  = Color(0xFF1F3A2C); // dark-mode equivalent surface tint
Color get kLight => AppBrightness.isDark ? _kLightDark : _kLightLight;

const Color _kMintBoth = Color(0xFF95D5B2); // --chart-3 / --switch-background — subtext on dark green (same both themes, always sits on kDeep)
Color get kMint => _kMintBoth;

// CTA / Action — primary buttons and highlights use the Figma accent green
const Color _kAccentBoth = Color(0xFF52B788); // --accent / --chart-2 — reads fine on both themes as an icon/accent color
Color get kAccent => _kAccentBoth;

const Color _kAccentLLight = Color(0xFFE3F5EC); // light tint of --accent, for icon backgrounds
const Color _kAccentLDark  = Color(0xFF1C3428); // dark tint of --accent, same role
Color get kAccentL => AppBrightness.isDark ? _kAccentLDark : _kAccentLLight;

// Page surfaces
const Color _kBgLight = Color.fromARGB(255, 228, 255, 243); // --background — mint-tinted off-white page bg
const Color _kBgDark  = Color(0xFF0F1A14); // mint-tinted near-black page bg
Color get kBg => AppBrightness.isDark ? _kBgDark : _kBgLight;

const Color _kWhiteLight = Color(0xFFFFFFFF); // --card — card backgrounds only
const Color _kWhiteDark  = Color(0xFF17241D); // dark-mode card surface (name kept for the hundreds of existing call sites — not literally white)
Color get kWhite => AppBrightness.isDark ? _kWhiteDark : _kWhiteLight;

const Color _kMutedLight = Color(0xFFEAF3EC); // --muted / --input-background
const Color _kMutedDark  = Color(0xFF1B2921);
Color get kMuted => AppBrightness.isDark ? _kMutedDark : _kMutedLight;

const Color _kDarkBoth = Color(0xFF1A1A1A); // near-black — footer background (same both themes, already dark)
Color get kDark => _kDarkBoth;

// Text
const Color _kTxLight = Color(0xFF1A2E1A); // --foreground — primary text
const Color _kTxDark  = Color(0xFFE8F5EC); // light, high-contrast primary text on dark surfaces
Color get kTx => AppBrightness.isDark ? _kTxDark : _kTxLight;

const Color _kMuLight = Color(0xFF5C7A5C); // --muted-foreground — secondary text
const Color _kMuDark  = Color(0xFF8FAF97); // lighter muted-green, readable on dark surfaces
Color get kMu => AppBrightness.isDark ? _kMuDark : _kMuLight;

// Borders
const Color _kBorderLight = Color(0x262D6A4F); // --border — primary green @ 15% opacity
const Color _kBorderDark  = Color(0x33E8F5EC); // primary text-on-dark @ 20% opacity — visible against dark surfaces
Color get kBorder => AppBrightness.isDark ? _kBorderDark : _kBorderLight;

// Health status pills
Color get kHealthyBg => kLight;
Color get kHealthyTx => kGreen;
const Color _kUnhealthyBgLight = Color(0xFFFBE4E8); // light tint of --destructive
const Color _kUnhealthyBgDark  = Color(0xFF3A1D22);
Color get kUnhealthyBg => AppBrightness.isDark ? _kUnhealthyBgDark : _kUnhealthyBgLight;
const Color _kUnhealthyTxLight = Color(0xFFD4183D); // --destructive
const Color _kUnhealthyTxDark  = Color(0xFFFF5C72); // brightened for contrast on dark surfaces
Color get kUnhealthyTx => AppBrightness.isDark ? _kUnhealthyTxDark : _kUnhealthyTxLight;

// Quiz option states (post-submit) — translucent overlays, kept constant
// across themes; see file-level comment above for why.
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
    TextStyle(fontFamily: kFontDisplay, fontSize: 28, fontWeight: FontWeight.w500, color: kTx);

TextStyle kH1(BuildContext ctx) =>
    TextStyle(fontFamily: kFontDisplay, fontSize: 22, fontWeight: FontWeight.w500, color: kTx);

TextStyle kH2(BuildContext ctx) =>
    TextStyle(fontFamily: kFontDisplay, fontSize: 18, fontWeight: FontWeight.w500, color: kTx);

TextStyle kH3(BuildContext ctx) =>
    TextStyle(fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: kTx);

TextStyle kBody(BuildContext ctx) =>
    TextStyle(fontFamily: kFontBody, fontSize: 14, fontWeight: FontWeight.w400, color: kTx);

TextStyle kSmall(BuildContext ctx) =>
    TextStyle(fontFamily: kFontBody, fontSize: 13, fontWeight: FontWeight.w400, color: kTx);

TextStyle kXSmall(BuildContext ctx) =>
    TextStyle(fontFamily: kFontBody, fontSize: 12, fontWeight: FontWeight.w400, color: kMu);

TextStyle kLabel(BuildContext ctx) =>
    TextStyle(fontFamily: kFontBody, fontSize: 11, fontWeight: FontWeight.w500,
        color: kMu, letterSpacing: 0.5);

TextStyle kMicro(BuildContext ctx) =>
    TextStyle(fontFamily: kFontBody, fontSize: 10, fontWeight: FontWeight.w400, color: kMu);

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
//
// MaterialApp needs two genuinely distinct, static ThemeData objects (one
// always-light, one always-dark) to hand to its own `theme:`/`darkTheme:`
// switch — it can't be driven by the same mutable AppBrightness flag the
// getters above use, or both would collapse to whichever one is "current"
// right now. So this one function takes an explicit `dark` flag and reads
// the private `_kXxxLight`/`_kXxxDark` values directly, instead of going
// through the getters — the single source of truth for each color's two
// values still lives in one place (the const declarations above), just
// accessed two different ways for two different consumers (custom widgets
// via the getters; MaterialApp's own theme-derived widgets via this).
// ─────────────────────────────────────────────────────────────
ThemeData buildAppTheme({required bool dark}) {
  final bg     = dark ? _kBgDark : _kBgLight;
  final white  = dark ? _kWhiteDark : _kWhiteLight;
  final tx     = dark ? _kTxDark : _kTxLight;
  final mu     = dark ? _kMuDark : _kMuLight;
  final border = dark ? _kBorderDark : _kBorderLight;
  final green  = dark ? _kGreenDark : _kGreenLight;

  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorSchemeSeed: _kDeepBoth,
  );
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
    scaffoldBackgroundColor: bg,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: _kDeepBoth,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: _kDeepBoth),
    ),
    cardTheme: CardThemeData(
      color: white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: kBRXl,
        side: BorderSide(color: border, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: green,       // ALL primary buttons use the Figma primary green
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: kBRSm),
        textStyle: const TextStyle(
            fontFamily: kFontBody, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tx,
        side: BorderSide(color: border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: kBRSm),
        textStyle: const TextStyle(
            fontFamily: kFontBody, fontSize: 13, fontWeight: FontWeight.w400),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: mu,
        textStyle: const TextStyle(
            fontFamily: kFontBody, fontSize: 12, fontWeight: FontWeight.w400),
      ),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 0.5),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: kBRLg,
        borderSide: BorderSide(color: border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: kBRLg,
        borderSide: BorderSide(color: border, width: 0.5),
      ),
      hintStyle: TextStyle(fontFamily: kFontBody, fontSize: 13, color: mu),
    ),
  );
}
