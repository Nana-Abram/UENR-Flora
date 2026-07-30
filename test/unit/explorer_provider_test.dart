import 'package:flutter_test/flutter_test.dart';
import 'package:plantid_app/features/explorer/explorer_provider.dart';
import 'package:plantid_app/models/plant_species.dart';

const _neem = PlantSpecies(
  id: 'neem',
  scientificName: 'Azadirachta indica',
  commonName: 'Neem Tree',
  modelClassIndex: 0,
  growthType: 'trees',
  familyName: 'Meliaceae',
  medicinalUses: 'Treats over 40 conditions',
);
const _cassava = PlantSpecies(
  id: 'cassava',
  scientificName: 'Manihot esculenta',
  commonName: 'Cassava',
  modelClassIndex: 1,
  growthType: 'shrubs',
  familyName: 'Euphorbiaceae',
);
const _griffonia = PlantSpecies(
  id: 'griffonia',
  scientificName: 'Griffonia simplicifolia',
  commonName: 'Griffonia',
  modelClassIndex: 2,
  growthType: 'herbs',
  familyName: 'Fabaceae',
  medicinalUses: 'Source of 5-HTP',
);

final _all = [_neem, _cassava, _griffonia];

void main() {
  group('ExplorerProvider.apply', () {
    test('returns everything for the default "all" filter with no query', () {
      final p = ExplorerProvider();
      expect(p.apply(_all), _all);
    });

    test('filters by growth type', () {
      final p = ExplorerProvider()..setFilter('trees');
      expect(p.apply(_all), [_neem]);
    });

    test('filters to species with a non-empty medicinalUses for "medicinal"', () {
      final p = ExplorerProvider()..setFilter('medicinal');
      expect(p.apply(_all).map((s) => s.id), containsAll(['neem', 'griffonia']));
      expect(p.apply(_all).map((s) => s.id), isNot(contains('cassava')));
    });

    test('search matches common name case-insensitively', () {
      final p = ExplorerProvider()..setQuery('neem');
      expect(p.apply(_all), [_neem]);
    });

    test('search matches scientific name', () {
      final p = ExplorerProvider()..setQuery('Manihot');
      expect(p.apply(_all), [_cassava]);
    });

    test('search matches family name', () {
      final p = ExplorerProvider()..setQuery('Fabaceae');
      expect(p.apply(_all), [_griffonia]);
    });

    test('filter and search combine (both must match)', () {
      final p = ExplorerProvider()
        ..setFilter('medicinal')
        ..setQuery('griffonia');
      expect(p.apply(_all), [_griffonia]);
    });

    test('returns empty when nothing matches the query', () {
      final p = ExplorerProvider()..setQuery('nonexistent plant xyz');
      expect(p.apply(_all), isEmpty);
    });
  });
}
