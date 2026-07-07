// lib/services/mock_classifier_service.dart
import 'dart:math';
import 'dart:typed_data';
import '../models/identification_result.dart';
import 'classifier_service.dart';

/// Development stand-in. Returns plausible results so the full flow works
/// without loading the real (multi-megabyte) model.
///
/// Returns class index 0 or 1 so the two seed Supabase species are always found.
class MockClassifierService implements ClassifierService {
  final _rng = Random();

  @override
  Future<ClassificationOutput> classify(List<Uint8List> images) async {
    await Future.delayed(const Duration(milliseconds: 1800));
    // Each extra photo nudges confidence up, mirroring the real ensemble's
    // behaviour so the "add another photo" flow is testable without tfjs.
    final confidence =
        (0.55 + images.length * 0.12 + _rng.nextDouble() * 0.10).clamp(0.0, 0.99);
    return ClassificationOutput(
      classIndex:       _rng.nextInt(2),
      confidence:       confidence,
      healthStatus:     _rng.nextDouble() > 0.30
                            ? HealthStatus.healthy
                            : HealthStatus.unhealthy,
      healthConfidence: 0.65 + _rng.nextDouble() * 0.30,
    );
  }
}
