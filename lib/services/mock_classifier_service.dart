// lib/services/mock_classifier_service.dart
import 'dart:math';
import 'dart:typed_data';
import '../models/identification_result.dart';
import 'classifier_service.dart';

/// Development stand-in. Returns plausible results so the full flow works
/// before the real MobileNetV2 model is trained and exported.
///
/// Returns class index 0 or 1 so the two seed Supabase species are always found.
class MockClassifierService implements ClassifierService {
  final _rng = Random();

  @override
  Future<ClassificationOutput> classify(Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 1800));
    return ClassificationOutput(
      classIndex:       _rng.nextInt(2),              // 0 or 1 — matches seed data
      confidence:       0.75 + _rng.nextDouble() * 0.20,
      healthStatus:     _rng.nextDouble() > 0.30
                            ? HealthStatus.healthy
                            : HealthStatus.unhealthy,
      healthConfidence: 0.65 + _rng.nextDouble() * 0.30,
    );
  }
}
