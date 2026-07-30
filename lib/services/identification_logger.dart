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
}
