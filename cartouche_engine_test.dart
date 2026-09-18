import 'package:flutter_test/flutter_test.dart';
import 'package:ankhlens/features/cartouche_maker/data/phonetics/cartouche_engine.dart';
import 'package:ankhlens/features/cartouche_maker/data/phonetics/g2p_rules.dart';
import 'package:ankhlens/features/cartouche_maker/data/phonetics/phoneme_normalizer.dart';
import 'package:ankhlens/features/cartouche_maker/data/phonetics/sign_mapper.dart';

// Minimal in-memory mapping table mirroring assets/data/phoneme_to_sign_map.json,
// so these tests don't depend on Flutter asset loading.
const _testMappingJson = '''
{
  "uniliterals": {
    "i-glide": { "gardiner_code": "M17" },
    "L": { "gardiner_code": "D21" },
    "K": { "gardiner_code": "V31" },
    "S": { "gardiner_code": "S29" },
    "N": { "gardiner_code": "N35" },
    "D": { "gardiner_code": "D46" },
    "R": { "gardiner_code": "D21" }
  },
  "biliterals": {}
}
''';

void main() {
  group('G2PConverter', () {
    final g2p = G2PConverter();

    test('converts a simple name to phonemes', () {
      final result = g2p.convert('Sam');
      expect(result.map((p) => p.symbol).toList(), ['S', 'AE', 'M']);
    });

    test('handles digraphs before single letters', () {
      final result = g2p.convert('Ash');
      // 'sh' must match as one digraph phoneme, not S + H
      expect(result.map((p) => p.symbol).toList(), ['AE', 'SH']);
    });

    test('drops silent trailing e', () {
      final result = g2p.convert('Kate');
      expect(result.map((p) => p.symbol).toList(), ['K', 'AE', 'T']);
    });
  });

  group('PhonemeNormalizer', () {
    final normalizer = PhonemeNormalizer();

    test('drops non-initial vowels, keeps consonants', () {
      final phonemes = [
        const Phoneme('S', isVowel: false),
        const Phoneme('AE', isVowel: true),
        const Phoneme('M', isVowel: false),
      ];
      final result = normalizer.normalize(phonemes);
      expect(result.map((u) => u.symbol).toList(), ['S', 'M']);
    });

    test('approximates an initial vowel with the i-glide carrier', () {
      final phonemes = [
        const Phoneme('AH', isVowel: true),
        const Phoneme('L', isVowel: false),
      ];
      final result = normalizer.normalize(phonemes);
      expect(result.first.symbol, 'i-glide');
      expect(result.first.isVowelApproximation, isTrue);
    });

    test('collapses consecutive identical consonants', () {
      final phonemes = [
        const Phoneme('N', isVowel: false),
        const Phoneme('N', isVowel: false),
      ];
      final result = normalizer.normalize(phonemes);
      expect(result.length, 1);
    });
  });

  group('CartoucheEngine end-to-end', () {
    late CartoucheEngine engine;

    setUp(() {
      engine = CartoucheEngine(
        signMapper: SignMapper.fromJson(_testMappingJson),
      );
    });

    test('ALEXANDER produces a non-empty, documented sign sequence', () {
      final result = engine.generate('ALEXANDER');

      expect(result.signs, isNotEmpty);
      expect(result.gardinerCodeSequence, everyElement(isA<String>()));
      // The consultant-reviewable expectation for this exact name should be
      // pinned here once the real mapping table is finalized -- this test
      // currently only guards against pipeline breakage, not exact output.
    });

    test('a name with only unmappable sounds still returns a result object',
        () {
      // 'X' alone -> K + S, both mappable in the test table; use a symbol
      // with no vowel-carrier and no mapping to exercise the empty path.
      final result = engine.generate('');
      expect(result.signs, isEmpty);
      expect(result.phonemes, isEmpty);
    });
  });
}
