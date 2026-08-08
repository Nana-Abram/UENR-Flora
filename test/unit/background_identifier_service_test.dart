import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plantid_app/features/scan/services/background_identifier_service.dart';
import 'package:plantid_app/features/scan/services/rejection_gate.dart';
import 'package:plantid_app/models/identification_result.dart';
import 'package:plantid_app/models/plant_species.dart';

/// Builds a 76-class probability vector: [named] are the top few classes'
/// exact probabilities, and everything left over is spread evenly across
/// the remaining classes — same helper shape as rejection_gate_test.dart.
List<double> _vector(List<double> named, {int totalClasses = RejectionGate.numClasses}) {
  final remainingCount = totalClasses - named.length;
  final remainingTotal = 1.0 - named.fold(0.0, (a, b) => a + b);
  final tail = remainingCount > 0 ? remainingTotal / remainingCount : 0.0;
  return [...named, ...List.filled(remainingCount, tail)];
}

/// Builds a 76-class probability vector with the top (and optional
/// second-place) probability at an arbitrary class index — [_vector]
/// always puts its named values at the front (indices 0, 1, 2...), which
/// can't test BackgroundIdentifierService.shouldActivate's species-aware
/// rules (they key off *which* classIndex wins, not just its probability).
List<double> _vectorAt(
  int topIndex,
  double topProb, {
  int? secondIndex,
  double secondProb = 0.0,
  int totalClasses = RejectionGate.numClasses,
}) {
  final namedTotal = topProb + (secondIndex != null ? secondProb : 0.0);
  final namedCount = 1 + (secondIndex != null ? 1 : 0);
  final remainingCount = totalClasses - namedCount;
  final tail = remainingCount > 0 ? (1.0 - namedTotal) / remainingCount : 0.0;
  final probs = List<double>.filled(totalClasses, tail);
  probs[topIndex] = topProb;
  if (secondIndex != null) probs[secondIndex] = secondProb;
  return probs;
}

ClassificationOutput _output(List<double> probs, {int ttaAgreement = 5}) {
  var best = 0;
  for (var i = 1; i < probs.length; i++) {
    if (probs[i] > probs[best]) best = i;
  }
  return ClassificationOutput(
    classIndex: best,
    confidence: probs[best],
    healthStatus: HealthStatus.healthy,
    healthConfidence: 0.9,
    probabilities: probs,
    ttaAgreement: ttaAgreement,
  );
}

List<PlantSpecies> _fakeSpecies(int count) => List.generate(
      count,
      (i) => PlantSpecies(
        id: 'species-$i',
        scientificName: 'Species scientificus $i',
        commonName: 'Species $i',
        modelClassIndex: i,
        galleryImageUrls: ['https://example.com/$i/a.jpg', 'https://example.com/$i/b.jpg'],
      ),
    );

void main() {
  final gate = RejectionGate();

  group('BackgroundIdentifierService.shouldActivate', () {
    // Class indices from class_names.json / plant_species.model_class_index.
    // Weak (in _weakSpeciesClassIndices): 8 = Avocado, 41 = Mango.
    // Strong (not in the set): 0 = Ackee, 1 = African_Oil_Palm.
    const avocado = 8;
    const mango = 41;
    const ackee = 0;
    const africanOilPalm = 1;

    test('Rule 1 — weak species, confidence 0.80 (below 0.85 ceiling) → activates', () {
      final probs = _vectorAt(avocado, 0.80, secondIndex: africanOilPalm, secondProb: 0.05);
      expect(
        BackgroundIdentifierService.shouldActivate(output: _output(probs), gate: gate),
        isTrue,
      );
    });

    test('Rule 1 — weak species, confidence exactly 0.85 → does not activate', () {
      final probs = _vectorAt(avocado, 0.85, secondIndex: africanOilPalm, secondProb: 0.05);
      expect(
        BackgroundIdentifierService.shouldActivate(output: _output(probs), gate: gate),
        isFalse,
      );
    });

    test('Rule 1 — weak species, confidence 0.90 → does not activate', () {
      final probs = _vectorAt(avocado, 0.90, secondIndex: africanOilPalm, secondProb: 0.03);
      expect(
        BackgroundIdentifierService.shouldActivate(output: _output(probs), gate: gate),
        isFalse,
      );
    });

    test('strong species, confidence 0.70 (below the OLD 0.85 ceiling) → does NOT activate — the key behaviour change', () {
      final probs = _vectorAt(ackee, 0.70, secondIndex: africanOilPalm, secondProb: 0.10);
      expect(
        BackgroundIdentifierService.shouldActivate(output: _output(probs), gate: gate),
        isFalse,
      );
    });

    test('strong species, confidence 0.99 → does not activate', () {
      final probs = _vectorAt(ackee, 0.99, secondIndex: africanOilPalm, secondProb: 0.005);
      expect(
        BackgroundIdentifierService.shouldActivate(output: _output(probs), gate: gate),
        isFalse,
      );
    });

    test('Rule 2 — strong species, confidence 0.59 (below the 0.60 safety net) → activates', () {
      final probs = _vectorAt(ackee, 0.59, secondIndex: africanOilPalm, secondProb: 0.20);
      expect(
        BackgroundIdentifierService.shouldActivate(output: _output(probs), gate: gate),
        isTrue,
      );
    });

    test('Rule 2 boundary — strong species, confidence exactly 0.60 → does not activate (strict <)', () {
      final probs = _vectorAt(ackee, 0.60, secondIndex: africanOilPalm, secondProb: 0.20);
      expect(
        BackgroundIdentifierService.shouldActivate(output: _output(probs), gate: gate),
        isFalse,
      );
    });

    test('Rule 2 safety net fires for ANY species, not just weak ones, below 0.60', () {
      // avocado (weak) at 0.55 activates via Rule 1 *and* Rule 2 — this
      // case specifically checks a species that ISN'T in the weak set
      // still gets caught once confidence drops far enough.
      final probs = _vectorAt(mango, 0.55, secondIndex: ackee, secondProb: 0.10);
      expect(
        BackgroundIdentifierService.shouldActivate(output: _output(probs), gate: gate),
        isTrue,
      );
    });

    test('Rule 3 code path — both top candidates weak with a narrow margin → activates '
        '(also covered by Rules 1/2, since a margin this narrow forces confidence '
        'below both _confidenceCeiling and _lowConfidenceSafetyNet — see shouldActivate\'s '
        'own doc comment on why Rule 3 can never be the sole reason)', () {
      final probs = _vectorAt(avocado, 0.50, secondIndex: mango, secondProb: 0.45);
      expect(
        BackgroundIdentifierService.shouldActivate(output: _output(probs), gate: gate),
        isTrue,
      );
    });

    test('narrow margin between two STRONG species still activates, but via Rule 2 '
        '(the safety net), not Rule 3 — confirms Rule 3 adds nothing Rule 2 didn\'t '
        'already cover, exactly as documented', () {
      final probs = _vectorAt(ackee, 0.50, secondIndex: africanOilPalm, secondProb: 0.45);
      expect(
        BackgroundIdentifierService.shouldActivate(output: _output(probs), gate: gate),
        isTrue,
      );
    });

    test('gate/brightness/variance are accepted but no longer influence the result', () {
      final probs = _vectorAt(ackee, 0.99, secondIndex: africanOilPalm, secondProb: 0.005);
      expect(
        BackgroundIdentifierService.shouldActivate(
          output: _output(probs),
          gate: gate,
          brightness: 1, // would have activated the old brightness rule
          variance: 1, // would have activated the old variance rule
        ),
        isFalse,
      );
    });
  });

  group('BackgroundIdentifierService.applyResult', () {
    final service = BackgroundIdentifierService.testable(
      (name, {required body}) async => FunctionResponse(data: {}, status: 200),
      () => const [],
    );
    final localOutput = _output(_vector([0.60, 0.30, 0.05]));

    test('rule 1 — agreement leaves localOutput untouched', () {
      final result = service.applyResult(
        localOutput: localOutput,
        bgResult: const BackgroundIdentificationResult(
          success: true,
          agreesWithLocalPrediction: true,
          replacementRecommended: false,
        ),
      );
      expect(result, same(localOutput));
    });

    test('rule 1 — failed call leaves localOutput untouched', () {
      final result = service.applyResult(
        localOutput: localOutput,
        bgResult: BackgroundIdentificationResult.failure('timeout'),
      );
      expect(result, same(localOutput));
    });

    test('rule 2 — validated replacement swaps classIndex/confidence to Claude\'s own confidence, keeps everything else', () {
      final result = service.applyResult(
        localOutput: localOutput,
        bgResult: const BackgroundIdentificationResult(
          success: true,
          agreesWithLocalPrediction: false,
          replacementRecommended: true,
          isDatabaseSpecies: true,
          suggestedSpeciesId: 'species-7',
          suggestedClassIndex: 7,
          suggestedLocalProbability: 0.30, // resolved/logged, but no longer the displayed number
          confidenceScore: 0.91,
        ),
      );
      expect(result.classIndex, 7);
      expect(result.confidence, 0.91); // Claude's own confidence, not the candidate's local 0.30
      expect(result.probabilities, same(localOutput.probabilities));
      expect(result.ttaAgreement, localOutput.ttaAgreement);
      expect(result.healthStatus, localOutput.healthStatus);
    });

    test('rule 2 boundary — confidence exactly at the floor (0.70) still applies', () {
      final result = service.applyResult(
        localOutput: localOutput,
        bgResult: const BackgroundIdentificationResult(
          success: true,
          agreesWithLocalPrediction: false,
          replacementRecommended: true,
          isDatabaseSpecies: true,
          suggestedSpeciesId: 'species-7',
          suggestedClassIndex: 7,
          confidenceScore: 0.70,
        ),
      );
      expect(result.classIndex, 7);
      expect(result.confidence, 0.70);
    });

    test('rule 1 — replacement recommended but below the confidence floor (0.70) leaves localOutput untouched', () {
      final result = service.applyResult(
        localOutput: localOutput,
        bgResult: const BackgroundIdentificationResult(
          success: true,
          agreesWithLocalPrediction: false,
          replacementRecommended: true,
          isDatabaseSpecies: true,
          suggestedSpeciesId: 'species-7',
          suggestedClassIndex: 7,
          confidenceScore: 0.69,
        ),
      );
      expect(result, same(localOutput));
    });

    test('rule 1 — replacement recommended with a very low Claude confidence (0.15) leaves localOutput untouched', () {
      final result = service.applyResult(
        localOutput: localOutput,
        bgResult: const BackgroundIdentificationResult(
          success: true,
          agreesWithLocalPrediction: false,
          replacementRecommended: true,
          isDatabaseSpecies: true,
          suggestedSpeciesId: 'species-7',
          suggestedClassIndex: 7,
          confidenceScore: 0.15,
        ),
      );
      expect(result, same(localOutput));
    });

    test('rule 3 — Gemini uncertain (replacementRecommended false, no suggestion) leaves localOutput untouched', () {
      final result = service.applyResult(
        localOutput: localOutput,
        bgResult: const BackgroundIdentificationResult(
          success: true,
          agreesWithLocalPrediction: false,
          replacementRecommended: false,
          isDatabaseSpecies: false,
        ),
      );
      expect(result, same(localOutput));
    });
  });

  group('BackgroundIdentifierService.analysePrediction', () {
    test('success + agree → agreesWithLocalPrediction true, no replacement', () async {
      final species = _fakeSpecies(10);
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async => FunctionResponse(
          status: 200,
          data: {
            'success': true,
            'agrees_with_local': true,
            'replacement_recommended': false,
            'is_database_species': true,
            'suggested_candidate_number': 1,
            'suggested_species_common_name': 'Species 0',
            'suggested_species_scientific_name': 'Species scientificus 0',
            'confidence_score': 0.9,
            'reasoning': 'matches',
          },
        ),
        () => species,
      );
      final output = _output(_vector([0.5, 0.3, 0.1]));
      final result = await service.analysePrediction(
        images: [Uint8List(0)],
        output: output,
      );
      expect(result.success, isTrue);
      expect(result.agreesWithLocalPrediction, isTrue);
      expect(result.replacementRecommended, isFalse);
    });

    test('success + valid replacement → resolves speciesId/classIndex/localProbability from the real candidate list', () async {
      final species = _fakeSpecies(10);
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async => FunctionResponse(
          status: 200,
          data: {
            'success': true,
            'agrees_with_local': false,
            'replacement_recommended': true,
            'is_database_species': true,
            'suggested_candidate_number': 2, // second-highest local probability
            'suggested_species_common_name': 'whatever gemini says',
            'suggested_species_scientific_name': 'whatever gemini says',
            'confidence_score': 0.8,
            'reasoning': 'closer match',
          },
        ),
        () => species,
      );
      // classIndex 0 highest (0.5), classIndex 3 second (0.3) → candidate 2.
      final probs = List<double>.filled(RejectionGate.numClasses, 0.0);
      probs[0] = 0.5;
      probs[3] = 0.3;
      probs[5] = 0.2;
      final output = _output(probs);
      final result = await service.analysePrediction(
        images: [Uint8List(0)],
        output: output,
      );
      expect(result.success, isTrue);
      expect(result.replacementRecommended, isTrue);
      expect(result.suggestedClassIndex, 3);
      expect(result.suggestedSpeciesId, 'species-3');
      expect(result.suggestedLocalProbability, closeTo(0.3, 1e-9));
      // Never trusts the wire response's own name strings for the
      // resolved fields — uses the client's own candidate list instead.
      expect(result.suggestedSpecies, 'Species 3');
    });

    test('success + outside pick (candidate_number 0, valid species id) → resolves classIndex/local probability from output.probabilities', () async {
      final species = _fakeSpecies(10); // ids 'species-0'..'species-9', classIndex == list index
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async => FunctionResponse(
          status: 200,
          data: {
            'success': true,
            'agrees_with_local': false,
            'replacement_recommended': true,
            'is_database_species': true,
            'suggested_candidate_number': 0,
            'suggested_species_id': 'species-8', // outside the top-5 candidates
            'suggested_species_common_name': 'whatever claude says',
            'suggested_species_scientific_name': 'whatever claude says',
            'confidence_score': 0.85,
            'reasoning': 'recognisable despite not being in the shortlist',
          },
        ),
        () => species,
      );
      final probs = List<double>.filled(RejectionGate.numClasses, 0.0);
      probs[0] = 0.5;
      probs[3] = 0.3;
      probs[5] = 0.2;
      probs[8] = 0.004; // species-8's true local probability — never in top 5
      final output = _output(probs);
      final result = await service.analysePrediction(
        images: [Uint8List(0)],
        output: output,
      );
      expect(result.success, isTrue);
      expect(result.replacementRecommended, isTrue);
      expect(result.suggestedSpeciesId, 'species-8');
      expect(result.suggestedClassIndex, 8);
      expect(result.suggestedLocalProbability, closeTo(0.004, 1e-9));
      // Never trusts the wire response's own name strings — uses the
      // client's own species list instead, same guarantee as in-candidate picks.
      expect(result.suggestedSpecies, 'Species 8');
    });

    test('outside pick with an unmatched species id → downgraded to no replacement', () async {
      final species = _fakeSpecies(10);
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async => FunctionResponse(
          status: 200,
          data: {
            'success': true,
            'agrees_with_local': false,
            'replacement_recommended': true,
            'is_database_species': true,
            'suggested_candidate_number': 0,
            'suggested_species_id': 'not-a-real-species-id',
            'confidence_score': 0.85,
            'reasoning': 'hallucinated id',
          },
        ),
        () => species,
      );
      final result = await service.analysePrediction(
        images: [Uint8List(0)],
        output: _output(_vector([0.5, 0.3, 0.1])),
      );
      expect(result.success, isTrue);
      expect(result.replacementRecommended, isFalse);
      expect(result.suggestedClassIndex, isNull);
    });

    test('candidates include every gallery photo (not a single reference_image_url)', () async {
      Map<String, dynamic>? capturedBody;
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async {
          capturedBody = body;
          return FunctionResponse(
            status: 200,
            data: {
              'success': true,
              'agrees_with_local': true,
              'replacement_recommended': false,
              'is_database_species': true,
              'suggested_candidate_number': 1,
              'confidence_score': 0.9,
              'reasoning': 'matches',
            },
          );
        },
        () => _fakeSpecies(10), // each fake species has 2 gallery photos
      );
      await service.analysePrediction(
        images: [Uint8List(0)],
        output: _output(_vector([0.5, 0.3, 0.1])),
      );
      final candidates = capturedBody!['candidates'] as List;
      final top = candidates.first as Map;
      expect(top['reference_image_urls'], [
        'https://example.com/0/a.jpg',
        'https://example.com/0/b.jpg',
      ]);
    });

    test('candidates include morphology fields when present, omit them when null', () async {
      Map<String, dynamic>? capturedBody;
      const withMorphology = PlantSpecies(
        id: 'species-morph',
        scientificName: 'Morphologia testa',
        commonName: 'Test Plant',
        modelClassIndex: 0,
        leafArrangement: 'alternate',
        leafMargin: 'serrate',
        venation: 'pinnate',
        leafShape: 'ovate',
        leafTexture: 'leathery, glossy',
        flowerDescription: 'Small white flowers',
        fruitDescription: 'Red berry',
        barkDescription: 'Smooth grey bark',
      );
      const withoutMorphology =
          PlantSpecies(id: 'species-bare', scientificName: 'Bare plant', commonName: 'Bare', modelClassIndex: 1);
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async {
          capturedBody = body;
          return FunctionResponse(
            status: 200,
            data: {
              'success': true,
              'agrees_with_local': true,
              'replacement_recommended': false,
              'is_database_species': true,
              'suggested_candidate_number': 1,
              'confidence_score': 0.9,
              'reasoning': 'matches',
            },
          );
        },
        () => [withMorphology, withoutMorphology],
      );
      final probs = List<double>.filled(RejectionGate.numClasses, 0.0);
      probs[0] = 0.6;
      probs[1] = 0.4;
      await service.analysePrediction(images: [Uint8List(0)], output: _output(probs));

      final candidates = capturedBody!['candidates'] as List;
      final withFields = candidates.firstWhere((c) => (c as Map)['scientific_name'] == 'Morphologia testa') as Map;
      expect(withFields['leaf_arrangement'], 'alternate');
      expect(withFields['leaf_margin'], 'serrate');
      expect(withFields['venation'], 'pinnate');
      expect(withFields['leaf_shape'], 'ovate');
      expect(withFields['leaf_texture'], 'leathery, glossy');
      expect(withFields['flower'], 'Small white flowers');
      expect(withFields['fruit'], 'Red berry');
      expect(withFields['bark'], 'Smooth grey bark');

      final bareFields = candidates.firstWhere((c) => (c as Map)['scientific_name'] == 'Bare plant') as Map;
      expect(bareFields.containsKey('leaf_arrangement'), isFalse);
      expect(bareFields.containsKey('flower'), isFalse);
    });

    test('full species list is sent alongside candidates in the request body', () async {
      Map<String, dynamic>? capturedBody;
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async {
          capturedBody = body;
          return FunctionResponse(
            status: 200,
            data: {
              'success': true,
              'agrees_with_local': true,
              'replacement_recommended': false,
              'is_database_species': true,
              'suggested_candidate_number': 1,
              'confidence_score': 0.9,
              'reasoning': 'matches',
            },
          );
        },
        () => _fakeSpecies(10),
      );
      await service.analysePrediction(
        images: [Uint8List(0)],
        output: _output(_vector([0.5, 0.3, 0.1])),
      );
      final allSpecies = capturedBody!['all_species'] as List;
      expect(allSpecies, hasLength(10));
      expect((allSpecies.first as Map)['species_id'], 'species-0');
      expect((allSpecies.first as Map)['scientific_name'], isNotEmpty);
      expect((allSpecies.first as Map)['common_name'], isNotEmpty);
    });

    test('success but candidate_number out of range → downgraded to no replacement', () async {
      final species = _fakeSpecies(10);
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async => FunctionResponse(
          status: 200,
          data: {
            'success': true,
            'agrees_with_local': false,
            'replacement_recommended': true,
            'is_database_species': true,
            'suggested_candidate_number': 99, // not one of the 5 sent
            'confidence_score': 0.8,
            'reasoning': 'hallucinated',
          },
        ),
        () => species,
      );
      final output = _output(_vector([0.5, 0.3, 0.1]));
      final result = await service.analysePrediction(
        images: [Uint8List(0)],
        output: output,
      );
      expect(result.success, isTrue);
      expect(result.replacementRecommended, isFalse);
      expect(result.suggestedClassIndex, isNull);
    });

    test('success:false from the function → failure result, not thrown', () async {
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async => FunctionResponse(
          status: 200,
          data: {'success': false, 'error_message': 'gemini_request_failed'},
        ),
        () => _fakeSpecies(10),
      );
      final result = await service.analysePrediction(
        images: [Uint8List(0)],
        output: _output(_vector([0.5, 0.3, 0.1])),
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, 'gemini_request_failed');
    });

    test('non-Map response data → failure result, not thrown', () async {
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async => FunctionResponse(data: 'not a map', status: 200),
        () => _fakeSpecies(10),
      );
      final result = await service.analysePrediction(
        images: [Uint8List(0)],
        output: _output(_vector([0.5, 0.3, 0.1])),
      );
      expect(result.success, isFalse);
    });

    test('thrown FunctionException → failure result, not propagated', () async {
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async =>
            throw const FunctionException(status: 500, details: 'boom'),
        () => _fakeSpecies(10),
      );
      final result = await service.analysePrediction(
        images: [Uint8List(0)],
        output: _output(_vector([0.5, 0.3, 0.1])),
      );
      expect(result.success, isFalse);
    });

    test('invoker that never resolves → times out into a failure result', () async {
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) => Completer<FunctionResponse>().future,
        () => _fakeSpecies(10),
      );
      final result = await service.analysePrediction(
        images: [Uint8List(0)],
        output: _output(_vector([0.5, 0.3, 0.1])),
      );
      expect(result.success, isFalse);
    }, timeout: const Timeout(Duration(seconds: 35)));

    test('no candidates resolve from the species list → failure result', () async {
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async => FunctionResponse(data: {}, status: 200),
        () => const [], // empty species list — no class index will resolve
      );
      final result = await service.analysePrediction(
        images: [Uint8List(0)],
        output: _output(_vector([0.5, 0.3, 0.1])),
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('no candidate'));
    });

    test('empty images list → failure result, not sent to the edge function', () async {
      var invoked = false;
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async {
          invoked = true;
          return FunctionResponse(data: {}, status: 200);
        },
        () => _fakeSpecies(10),
      );
      final result = await service.analysePrediction(
        images: const [],
        output: _output(_vector([0.5, 0.3, 0.1])),
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('no images'));
      expect(invoked, isFalse);
    });

    test('multiple images are all resized and included in the request body', () async {
      Map<String, dynamic>? capturedBody;
      final service = BackgroundIdentifierService.testable(
        (name, {required body}) async {
          capturedBody = body;
          return FunctionResponse(
            status: 200,
            data: {
              'success': true,
              'agrees_with_local': true,
              'replacement_recommended': false,
              'is_database_species': true,
              'suggested_candidate_number': 1,
              'confidence_score': 0.9,
              'reasoning': 'matches',
            },
          );
        },
        () => _fakeSpecies(10),
        (bytes) async => Uint8List.fromList([...bytes, 0xFF]), // detectable "resized" marker
      );
      final result = await service.analysePrediction(
        images: [Uint8List(0), Uint8List(0), Uint8List(0)],
        output: _output(_vector([0.5, 0.3, 0.1])),
      );
      expect(result.success, isTrue);
      final images = capturedBody!['images'] as List;
      expect(images, hasLength(3));
      for (final img in images) {
        expect((img as Map)['data'], isNotEmpty);
        expect(img['mime_type'], 'image/jpeg');
      }
    });
  });

  group('BackgroundIdentifierService.isStronglyConfident', () {
    test('confidence_score above 0.80 → strongly confident', () {
      const result = BackgroundIdentificationResult(success: true, confidenceScore: 0.81);
      expect(BackgroundIdentifierService.isStronglyConfident(result), isTrue);
    });

    test('confidence_score exactly 0.80 → not strongly confident (strict >)', () {
      const result = BackgroundIdentificationResult(success: true, confidenceScore: 0.80);
      expect(BackgroundIdentifierService.isStronglyConfident(result), isFalse);
    });

    test('high confidence_score but success:false → not strongly confident', () {
      const result = BackgroundIdentificationResult(success: false, confidenceScore: 0.95);
      expect(BackgroundIdentifierService.isStronglyConfident(result), isFalse);
    });
  });
}
