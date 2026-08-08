// lib/features/scan/services/unknown_plant_reporter.dart
import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Backs the "Report Unknown Plant" button on UnknownPlantScreen — a
/// user-confirmed "this genuinely isn't one of the 76 documented species"
/// signal. Uploads the scan photo to the private `unknown-plant-reports`
/// Storage bucket and inserts a row into `unknown_plant_reports` (see
/// supabase/unknown_plant_reports.sql). Never read back by the app; exists
/// purely for manual review and future OodDetector threshold tuning.
class UnknownPlantReporter {
  static const String bucket = 'unknown-plant-reports';

  final SupabaseClient _client;

  UnknownPlantReporter(this._client);

  /// [diagnostics] must be the exact map ScanDiagnostics.build produced for
  /// this scan's identification_logs entry — this pulls ood_distance/
  /// threshold/entropy/confidence/top3_probability/tta_agreement/
  /// closest_species/model_version straight out of it rather than
  /// recomputing them, so a report and its corresponding identification_logs
  /// row always agree on the numbers (see that class's own doc comment).
  ///
  /// Throws on failure (network error, storage rejection, insert error) —
  /// callers are expected to catch and show their own error state; unlike
  /// IdentificationLogger's best-effort logging calls, a submitted report
  /// silently failing to save would defeat the entire point of the button,
  /// so this doesn't swallow errors itself.
  Future<void> submit({
    required Uint8List imageBytes,
    required String? deviceId,
    required Map<String, dynamic> diagnostics,
    String? locationDescription,
    String? notes,
  }) async {
    final path = '${deviceId ?? 'anon'}/${_randomFileName()}';
    await _client.storage.from(bucket).uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    // Deliberately no `.select()` chained here — unknown_plant_reports has
    // only an INSERT policy (see supabase/unknown_plant_reports.sql), no
    // SELECT policy, since reports are write-only from the client by
    // design. Postgres requires a row inserted under RLS to also satisfy a
    // SELECT policy before it can be returned via `RETURNING` — chaining
    // `.select()` here (which makes supabase-dart request the inserted row
    // back) would turn every submission into an RLS error despite the
    // WITH CHECK itself passing, even though the row really did insert.
    // Confirmed live against the real table: `Prefer: return=minimal`
    // (this client's default without `.select()`) succeeds; requesting a
    // representation back does not.
    await _client.from('unknown_plant_reports').insert({
      'device_id': deviceId,
      'location_description': locationDescription,
      'notes': notes,
      // The bucket is private (no public URL resolves) — this is the
      // object's storage path, fetchable later via a signed URL or
      // dashboard/service-role access, not a directly-loadable link.
      'image_url': path,
      'ood_distance': diagnostics['ood_distance'],
      'ood_threshold': diagnostics['threshold'],
      'closest_species': diagnostics['closest_species'],
      'raw_confidence': diagnostics['confidence'],
      'entropy': diagnostics['entropy'],
      'tta_agreement': diagnostics['tta_agreement'],
      'top3_probability': diagnostics['top3_probability'],
      'model_version': diagnostics['model_version'],
    });
  }

  /// Timestamp + random hex suffix — unique enough for a per-device report
  /// folder without pulling in a uuid package dependency for one call site.
  String _randomFileName() {
    final rand = Random.secure();
    final suffix = List<int>.generate(8, (_) => rand.nextInt(16))
        .map((d) => d.toRadixString(16))
        .join();
    return '${DateTime.now().millisecondsSinceEpoch}_$suffix.jpg';
  }
}
