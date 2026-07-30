// lib/features/scan/pending_scan.dart
import '../../models/identification_result.dart';

/// A scan whose identification_logs insert / profile-record RPC failed
/// (almost always because the device was offline) — everything
/// [OfflineScanQueue] needs to replay [IdentificationLogger.log] and
/// [ProfileProvider.recordScan] later, once connectivity returns. Kept to
/// primitive fields only, deliberately mirroring [IdentificationLogger.log]'s
/// now-primitive `speciesId` parameter, so this can round-trip through
/// SharedPreferences as plain JSON.
class PendingScan {
  final int classIndex;
  final double confidence;
  final HealthStatus healthStatus;
  final double healthConfidence;
  final String? speciesId;
  final bool isCorrect;
  final DateTime queuedAt;

  const PendingScan({
    required this.classIndex,
    required this.confidence,
    required this.healthStatus,
    required this.healthConfidence,
    required this.speciesId,
    required this.isCorrect,
    required this.queuedAt,
  });

  ClassificationOutput get classification => ClassificationOutput(
        classIndex: classIndex,
        confidence: confidence,
        healthStatus: healthStatus,
        healthConfidence: healthConfidence,
      );

  factory PendingScan.fromClassification({
    required ClassificationOutput classification,
    required String? speciesId,
    required bool isCorrect,
  }) =>
      PendingScan(
        classIndex: classification.classIndex,
        confidence: classification.confidence,
        healthStatus: classification.healthStatus,
        healthConfidence: classification.healthConfidence,
        speciesId: speciesId,
        isCorrect: isCorrect,
        queuedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'classIndex': classIndex,
        'confidence': confidence,
        'healthStatus': healthStatus.name,
        'healthConfidence': healthConfidence,
        'speciesId': speciesId,
        'isCorrect': isCorrect,
        'queuedAt': queuedAt.toIso8601String(),
      };

  factory PendingScan.fromJson(Map<String, dynamic> json) => PendingScan(
        classIndex: json['classIndex'] as int,
        confidence: (json['confidence'] as num).toDouble(),
        healthStatus: HealthStatus.values.byName(json['healthStatus'] as String),
        healthConfidence: (json['healthConfidence'] as num).toDouble(),
        speciesId: json['speciesId'] as String?,
        isCorrect: json['isCorrect'] as bool,
        queuedAt: DateTime.parse(json['queuedAt'] as String),
      );
}
