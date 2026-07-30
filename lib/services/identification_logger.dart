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
  Future<void> log({
    required ClassificationOutput classification,
    required String? speciesId,
    String? deviceId,
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
    }).timeout(_insertTimeout);
  }

  /// A photo RejectionGate screened out before it ever reached the
  /// weighted average — logged with confidence 0 and no species (attaching
  /// a predicted species to something the app is asserting *isn't a
  /// plant* would be misleading), distinct from a real low-confidence
  /// identification. Same best-effort throttle as [log]; a failure here is
  /// even lower-stakes (it's not tied to anything the offline queue needs
  /// to replay), so it's just swallowed by the caller rather than queued.
  Future<void> logRejection({String? deviceId}) async {
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
      'note':                 'rejected: not_plant',
    }).timeout(_insertTimeout);
  }
}
