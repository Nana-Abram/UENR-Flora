// lib/services/identification_logger.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/identification_result.dart';
import '../models/plant_species.dart';

class IdentificationLogger {
  final SupabaseClient _client;
  IdentificationLogger(this._client);

  Future<void> log({
    required ClassificationOutput classification,
    required PlantSpecies? species,
    String? deviceId,
  }) async {
    await _client.from('identification_logs').insert({
      'device_id':            deviceId,
      'predicted_species_id': species?.id,
      'confidence_score':     classification.confidence,
      'health_status':        classification.healthStatus.name,
      'health_confidence':    classification.healthConfidence,
    });
  }
}
