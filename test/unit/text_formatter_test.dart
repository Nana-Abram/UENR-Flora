import 'package:flutter_test/flutter_test.dart';
import 'package:plantid_app/core/utils/text_formatter.dart';
import 'package:plantid_app/widgets/planting_guide_tab.dart';

void main() {
  group('toBullets', () {
    test('returns an empty list for empty/whitespace input', () {
      expect(toBullets(''), isEmpty);
      expect(toBullets('   '), isEmpty);
    });

    test('splits on ". " without breaking mid-number periods', () {
      final bullets = toBullets(
          'Space individual plants at least 1.5 metres apart. Mix soil at a ratio of 3:1 before backfilling.');
      expect(bullets, [
        'Space individual plants at least 1.5 metres apart.',
        'Mix soil at a ratio of 3:1 before backfilling.',
      ]);
    });

    test('splits on semicolons too', () {
      final bullets = toBullets('Water twice a week; fertilise monthly; prune yearly.');
      expect(bullets, [
        'Water twice a week.',
        'Fertilise monthly.',
        'Prune yearly.',
      ]);
    });

    test('capitalises the first letter and appends a period when missing', () {
      final bullets = toBullets('grows quickly in full sun');
      expect(bullets, ['Grows quickly in full sun.']);
    });

    test('drops short fragments (8 chars or fewer)', () {
      final bullets = toBullets('Full sun. Water often and deeply each week.');
      expect(bullets, ['Water often and deeply each week.']);
    });

    test('preserves an existing CAUTION prefix verbatim for BulletList to detect', () {
      final bullets = toBullets(
          "CAUTION — do not plant near children's play areas. Toxic and thorny.");
      expect(bullets.first, startsWith('CAUTION'));
    });
  });

  group('parsePlantingAdvice', () {
    test('splits WHEN/HOW/WHERE sections in order', () {
      const advice = 'WHEN: Plant in May.\n\n'
          'HOW: Dig a hole. Water weekly.\n\n'
          'WHERE: Near the entrance. Avoid shade.';
      final sections = parsePlantingAdvice(advice);
      expect(sections['WHEN'], 'Plant in May.');
      expect(sections['HOW'], 'Dig a hole. Water weekly.');
      expect(sections['WHERE'], 'Near the entrance. Avoid shade.');
    });

    test('returns an empty map when no section labels are present', () {
      expect(parsePlantingAdvice('just some text'), isEmpty);
    });
  });
}
