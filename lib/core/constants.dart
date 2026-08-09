// lib/core/constants.dart

/// Minimum confidence for a prediction to be shown as a result.
/// Below this value the user is asked to retake the photo.
const double kConfidenceThreshold = 0.70;

/// Identifies which trained species/OOD model produced a scan — logged
/// alongside every identification_logs.model_diagnostics entry and
/// unknown_plant_reports row (see ScanDiagnostics.build) so historical
/// telemetry stays attributable to a specific model generation once this
/// gets retrained/re-exported. Bump this by hand whenever
/// assets/models/model.json (and its paired ood_*.npy assets) are
/// replaced — nothing derives it automatically.
const String kModelVersion = 'mobilenetv2-76species-v3';

/// Human-readable app name used in the UI.
const String kAppName = 'UENR Flora';

/// Tagline shown in the hero section.
const String kAppTagline = 'Identify every plant on campus, instantly';

/// Responsive breakpoints — used with LayoutBuilder in every screen.
const double kBreakpointSm = 480.0;
const double kBreakpointMd = 640.0;
const double kBreakpointLg = 960.0;

/// Maximum width of page content on large screens.
const double kMaxContentWidth = 1400.0;

/// Card/icon colour pairs cycled through for plant cards (Explorer, Recent
/// Identifications, detail modal) since species records carry no colour of
/// their own. Picked via [colorPairForId] so the same species always gets
/// the same colour within a session.
///
/// Deliberately separate from category_style.dart's `categoryStyle` — that
/// colours the growth-type ("Trees"/"Herbs"/etc.) badge shown alongside a
/// card, this colours the card/placeholder background itself. Every call
/// site in the app keeps this split (verified across Explorer, Home,
/// Results, Profile, Challenge); don't merge them into one lookup, or
/// species within the same category would lose their distinct placeholder
/// colours.
const List<List<int>> kPlantCardPalette = [
  [0xFFFAEEDA, 0xFFBA7517],
  [0xFFEAF3DE, 0xFF3B6D11],
  [0xFFE1F5EE, 0xFF0F6E56],
  [0xFFFAC775, 0xFF633806],
  [0xFFC0DD97, 0xFF27500A],
  [0xFFFAECE7, 0xFF993C1D],
  [0xFFFBEAF0, 0xFF993556],
  [0xFFD3D1C7, 0xFF444441],
  [0xFF9FE1CB, 0xFF085041],
  [0xFFF5C4B3, 0xFF712B13],
];

/// Deterministically maps a species id to a (cardColor, iconColor) pair from
/// [kPlantCardPalette], so the same species shows the same colour everywhere.
List<int> colorPairForId(String id) {
  final raw = id.hashCode % kPlantCardPalette.length;
  final index = raw < 0 ? raw + kPlantCardPalette.length : raw;
  return kPlantCardPalette[index];
}
