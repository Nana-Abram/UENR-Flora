// lib/core/constants.dart

/// Minimum confidence for a prediction to be shown as a result.
/// Below this value the user is asked to retake the photo.
const double kConfidenceThreshold = 0.70;

/// Human-readable app name used in the UI.
const String kAppName = 'UENR Flora';

/// Tagline shown in the hero section.
const String kAppTagline = 'Identify every plant on campus — instantly';

/// Responsive breakpoints — used with LayoutBuilder in every screen.
const double kBreakpointSm = 480.0;
const double kBreakpointMd = 640.0;
const double kBreakpointLg = 960.0;

/// Maximum width of page content on large screens.
const double kMaxContentWidth = 1000.0;

/// Sample plant data used by the Explorer screen and Recent Scans
/// before the live Supabase connection is active.
///
/// Each entry:
///   common      — display name
///   scientific  — italic name shown under common name
///   family      — plant family name
///   type        — filter category: 'trees' | 'shrubs' | 'herbs' | 'medicinal' | 'ornamental'
///   healthy     — bool, drives the PillBadge colour
///   cardColor   — ARGB int for the coloured image-placeholder background
///   iconColor   — ARGB int for the icon drawn over cardColor
const List<Map<String, dynamic>> kSamplePlants = [
  {
    'common': 'Flamboyant Tree',
    'scientific': 'Delonix regia',
    'family': 'Fabaceae',
    'type': 'trees',
    'healthy': true,
    'cardColor': 0xFFFAEEDA,
    'iconColor': 0xFFBA7517,
  },
  {
    'common': 'Weeping Fig',
    'scientific': 'Ficus benjamina',
    'family': 'Moraceae',
    'type': 'trees',
    'healthy': true,
    'cardColor': 0xFFEAF3DE,
    'iconColor': 0xFF3B6D11,
  },
  {
    'common': 'Neem Tree',
    'scientific': 'Azadirachta indica',
    'family': 'Meliaceae',
    'type': 'trees',
    'healthy': true,
    'cardColor': 0xFFE1F5EE,
    'iconColor': 0xFF0F6E56,
  },
  {
    'common': 'Mango Tree',
    'scientific': 'Mangifera indica',
    'family': 'Anacardiaceae',
    'type': 'trees',
    'healthy': false,
    'cardColor': 0xFFFAC775,
    'iconColor': 0xFF633806,
  },
  {
    'common': 'Coconut Palm',
    'scientific': 'Cocos nucifera',
    'family': 'Arecaceae',
    'type': 'trees',
    'healthy': true,
    'cardColor': 0xFFC0DD97,
    'iconColor': 0xFF27500A,
  },
  {
    'common': 'Papaya',
    'scientific': 'Carica papaya',
    'family': 'Caricaceae',
    'type': 'herbs',
    'healthy': true,
    'cardColor': 0xFFFAECE7,
    'iconColor': 0xFF993C1D,
  },
  {
    'common': 'Hibiscus',
    'scientific': 'Hibiscus rosa-sinensis',
    'family': 'Malvaceae',
    'type': 'ornamental',
    'healthy': true,
    'cardColor': 0xFFFBEAF0,
    'iconColor': 0xFF993556,
  },
  {
    'common': 'Teak',
    'scientific': 'Tectona grandis',
    'family': 'Lamiaceae',
    'type': 'trees',
    'healthy': true,
    'cardColor': 0xFFD3D1C7,
    'iconColor': 0xFF444441,
  },
  {
    'common': 'Aloe Vera',
    'scientific': 'Aloe vera',
    'family': 'Asphodelaceae',
    'type': 'medicinal',
    'healthy': true,
    'cardColor': 0xFF9FE1CB,
    'iconColor': 0xFF085041,
  },
  {
    'common': 'Bougainvillea',
    'scientific': 'Bougainvillea spectabilis',
    'family': 'Nyctaginaceae',
    'type': 'ornamental',
    'healthy': true,
    'cardColor': 0xFFF5C4B3,
    'iconColor': 0xFF712B13,
  },
  {
    'common': 'African Tulip',
    'scientific': 'Spathodea campanulata',
    'family': 'Bignoniaceae',
    'type': 'trees',
    'healthy': true,
    'cardColor': 0xFFFAC775,
    'iconColor': 0xFF854F0B,
  },
  {
    'common': 'Cassava',
    'scientific': 'Manihot esculenta',
    'family': 'Euphorbiaceae',
    'type': 'shrubs',
    'healthy': true,
    'cardColor': 0xFFC0DD97,
    'iconColor': 0xFF27500A,
  },
];
