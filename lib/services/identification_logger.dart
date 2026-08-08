// lib/services/identification_logger.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/identification_result.dart';

class IdentificationLogger {
  final SupabaseClient _client;
  IdentificationLogger(this._client);

  /// Best-effort client-side throttle against rapid-fire inserts (a buggy
  /// retry loop, accidental double-taps) — this is analytics logging, not
  /// a security boundary. A client bypassing the app entirely could still
  /// insert directly with the anon key; real abuse protection needs a
  /// server-side rate limit, which is out of scope for this client class.
  static const _minInterval = Duration(seconds: 1);
  static const _insertTimeout = Duration(seconds: 10);
  DateTime? _lastLogAt;

  /// [speciesId] rather than a full PlantSpecies — only the id is ever
  /// sent, and taking just the id lets callers (see OfflineScanQueue) queue
  /// and replay a log call from persisted JSON without needing to refetch
  /// or serialize an entire species record.
  /// [aiAnalysis] is the background Claude second-opinion layer's verdict
  /// (see BackgroundIdentificationResult.toLogJson), when it ran — null
  /// whenever the activation rule didn't fire or the call failed. QA/
  /// analytics data only; never read back by the app.
  /// [modelDiagnostics] is the per-scan OOD/entropy/confidence/TTA payload
  /// (see ScanDiagnostics.build) — populated for every call, unlike
  /// [aiAnalysis] which is null whenever Claude never ran. Intended for
  /// future model improvement and threshold tuning, also never read back.
  Future<void> log({
    required ClassificationOutput classification,
    required String? speciesId,
    String? deviceId,
    Map<String, dynamic>? aiAnalysis,
    Map<String, dynamic>? modelDiagnostics,
  }) async {
    final now = DateTime.now();
    final last = _lastLogAt;
    if (last != null && now.difference(last) < _minInterval) return;
    _lastLogAt = now;

    await _client.from('identification_logs').insert({
      'device_id':            deviceId,
      'predicted_species_id': speciesId,
      'confidence_score':     classification.confidence,
      'health_status':        classification.healthStatus.name,
      'health_confidence':    classification.healthConfidence,
      'ai_analysis':          aiAnalysis,
      if (modelDiagnostics != null) 'model_diagnostics': modelDiagnostics,
    }).timeout(_insertTimeout);
  }

  /// A photo screened out before it ever reached the weighted average, or
  /// (see [note]) an OOD/user-reported "unknown species" verdict — logged
  /// with confidence 0 and no species (attaching a predicted species to
  /// something the app is asserting *isn't a confident match* would be
  /// misleading), distinct from a real low-confidence identification. Same
  /// best-effort throttle as [log]; a failure here is even lower-stakes
  /// (it's not tied to anything the offline queue needs to replay), so
  /// it's just swallowed by the caller rather than queued.
  ///
  /// [note] defaults to the original RejectionGate/gate-model wording —
  /// callers logging a different kind of rejection (e.g. OodDetector's
  /// out-of-distribution verdict, or a user tapping "Report Unknown Plant")
  /// pass their own. [aiAnalysis] is free-form diagnostic data, same column
  /// [log] uses for the background Claude verdict — omitted entirely when
  /// null so this doesn't change the insert shape for existing callers.
  /// [modelDiagnostics] is the structured OOD/entropy/confidence/TTA
  /// payload (see ScanDiagnostics.build and [log]'s own doc comment) —
  /// used by the OOD rejection path, where [aiAnalysis] stays null since
  /// Claude is never consulted on that path (see scan_screen.dart's
  /// _runIdentification).
  Future<void> logRejection({
    String? deviceId,
    String note = 'rejected: not_plant',
    Map<String, dynamic>? aiAnalysis,
    Map<String, dynamic>? modelDiagnostics,
  }) async {
    final now = DateTime.now();
    final last = _lastLogAt;
    if (last != null && now.difference(last) < _minInterval) return;
    _lastLogAt = now;

    await _client.from('identification_logs').insert({
      'device_id':            deviceId,
      'predicted_species_id': null,
      'confidence_score':     0,
      'health_status':        HealthStatus.healthy.name,
      'health_confidence':    0,
      'note':                 note,
      if (aiAnalysis != null) 'ai_analysis': aiAnalysis,
      if (modelDiagnostics != null) 'model_diagnostics': modelDiagnostics,
    }).timeout(_insertTimeout);
  }
}
