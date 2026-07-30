// lib/core/app_icons.dart
//
// Single source of truth for every icon used in the app.
// Import this file in widgets instead of hardcoding Icons.xyz directly.
// To swap an icon globally, change it here once.

import 'package:flutter/material.dart';

// ── Navigation ─────────────────────────────────────────────
const IconData kIconHome     = Icons.home_outlined;
const IconData kIconScan     = Icons.camera_alt_outlined;
const IconData kIconExplorer = Icons.yard_outlined;
const IconData kIconLearn    = Icons.menu_book_outlined;
const IconData kIconMenu     = Icons.menu;

// ── App identity ───────────────────────────────────────────
const IconData kIconLogo    = Icons.eco;          // logo leaf
const IconData kIconLeaf    = Icons.eco_outlined; // general leaf

// ── Scan flow ──────────────────────────────────────────────
const IconData kIconCamera   = Icons.camera_alt_outlined;
const IconData kIconGallery  = Icons.photo_library_outlined;
const IconData kIconSearch   = Icons.search_outlined;
const IconData kIconFocus    = Icons.center_focus_strong;
const IconData kIconContrast = Icons.contrast;
const IconData kIconFlipCam  = Icons.flip_camera_ios;

// ── Results & health ───────────────────────────────────────
const IconData kIconHealthy   = Icons.check_circle_outline;
const IconData kIconUnhealthy = Icons.warning_amber_rounded;
// Aliased (not a separately-repeated Icons.* value) so "change it here
// once" is actually true — this used to independently repeat
// Icons.warning_amber_rounded, so editing kIconUnhealthy alone silently
// left kIconWarning pointing at the old icon.
const IconData kIconWarning   = kIconUnhealthy;
const IconData kIconCancel    = Icons.cancel_outlined;

// ── Ecology / care ─────────────────────────────────────────
const IconData kIconCloud  = Icons.cloud_outlined;
const IconData kIconWind   = Icons.air_outlined;
const IconData kIconSoil   = Icons.layers_outlined;
const IconData kIconWater  = Icons.water_drop_outlined;
const IconData kIconSun    = Icons.wb_sunny_outlined;
const IconData kIconTree   = Icons.park_outlined;
const IconData kIconForest = Icons.forest_outlined;
const IconData kIconTerrain = Icons.terrain_outlined;

// ── UI actions ─────────────────────────────────────────────
const IconData kIconShare      = Icons.share_outlined;
const IconData kIconFavorite   = Icons.favorite_border;
const IconData kIconBack       = Icons.arrow_back_outlined;
const IconData kIconForward    = Icons.arrow_forward;
const IconData kIconChevronR   = Icons.chevron_right;
const IconData kIconRefresh    = Icons.refresh;
const IconData kIconLocation   = Icons.location_on_outlined;
const IconData kIconStar       = Icons.star_outline;
const IconData kIconBulb       = Icons.lightbulb_outline;
const IconData kIconCalendar   = Icons.calendar_today_outlined;
const IconData kIconSort       = Icons.sort_outlined;

// ── Learn categories ───────────────────────────────────────
const IconData kIconBiodiversity  = Icons.eco_outlined;
const IconData kIconClimate       = Icons.public_outlined;
const IconData kIconSustainability = Icons.recycling;

// ── Feature cards ──────────────────────────────────────────
const IconData kIconEncyclopedia  = Icons.menu_book_outlined;

// ── Quiz ───────────────────────────────────────────────────
// Aliased to the Results & health icons above for the same reason as
// kIconWarning — same icons, one real source of truth each.
const IconData kIconQuizCorrect = kIconHealthy;
const IconData kIconQuizWrong   = kIconCancel;

// ── Profile & achievements ────────────────────────────────
const IconData kIconEdit      = Icons.edit_outlined;
const IconData kIconStreak    = Icons.local_fire_department_outlined;
const IconData kIconTrophy    = Icons.emoji_events_outlined;
const IconData kIconTarget    = Icons.track_changes_outlined;
const IconData kIconMedal     = Icons.military_tech_outlined;
const IconData kIconLock      = Icons.lock_outline;
const IconData kIconDelete    = Icons.delete_outline;
const IconData kIconClose     = Icons.close;
const IconData kIconCrown     = Icons.workspace_premium_outlined;
const IconData kIconNight     = Icons.dark_mode_outlined;
const IconData kIconMedical   = Icons.medical_services_outlined;
const IconData kIconPets      = Icons.pets_outlined;
const IconData kIconScience   = Icons.biotech_outlined;
const IconData kIconGrass     = Icons.grass_outlined;
const IconData kIconSpa       = Icons.spa_outlined;
const IconData kIconBolt      = Icons.bolt_outlined;
