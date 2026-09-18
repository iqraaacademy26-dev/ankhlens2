import 'dart:convert';

import 'phoneme_normalizer.dart';

/// One resolved sign in a cartouche, with a flag for whether it's an
/// established match or an approximation the UI must disclose.
class MappedSign {
  final String gardinerCode;
  final bool isApproximated;

  const MappedSign(this.gardinerCode, {required this.isApproximated});
}

/// Stage 3 of the cartouche pipeline: consonant units -> Gardiner codes.
///
/// The mapping table is loaded from `assets/data/phoneme_to_sign_map.json`
/// (data, not code) so an Egyptology consultant can review/edit it without
/// touching Dart. Biliteral shortcuts are preferred over two separate
/// uniliterals when a reviewed biliteral pattern exists.
class SignMapper {
  final Map<String, String> _uniliterals; // consonant symbol -> gardiner_code
  final List<_BiliteralRule> _biliterals;

  SignMapper._(this._uniliterals, this._biliterals);

  factory SignMapper.fromJson(String jsonString) {
    final Map<String, dynamic> data =
        jsonDecode(jsonString) as Map<String, dynamic>;

    final uniliteralsRaw = data['uniliterals'] as Map<String, dynamic>;
    final uniliterals = <String, String>{};
    for (final entry in uniliteralsRaw.entries) {
      if (entry.key.startsWith('_')) continue;
      final value = entry.value as Map<String, dynamic>;
      uniliterals[entry.key] = value['gardiner_code'] as String;
    }

    final biliteralsRaw =
        (data['biliterals'] as Map<String, dynamic>?) ?? const {};
    final biliterals = <_BiliteralRule>[];
    for (final entry in biliteralsRaw.entries) {
      if (entry.key.startsWith('_')) continue;
      final value = entry.value as Map<String, dynamic>;
      final pattern = (value['pattern'] as List<dynamic>).cast<String>();
      biliterals.add(
        _BiliteralRule(pattern, value['gardiner_code'] as String),
      );
    }

    return SignMapper._(uniliterals, biliterals);
  }

  /// Maps a consonantal skeleton to an ordered list of [MappedSign]s,
  /// preferring biliteral matches where a reviewed one covers two
  /// consecutive units.
  List<MappedSign> mapToSigns(List<ConsonantUnit> units) {
    final result = <MappedSign>[];
    var i = 0;

    while (i < units.length) {
      final biliteralMatch = _tryMatchBiliteral(units, i);
      if (biliteralMatch != null) {
        result.add(MappedSign(
          biliteralMatch.gardinerCode,
          isApproximated: units[i].isVowelApproximation,
        ));
        i += 2;
        continue;
      }

      final code = _uniliterals[units[i].symbol];
      if (code != null) {
        result.add(MappedSign(code, isApproximated: units[i].isVowelApproximation));
      }
      // If no uniliteral exists either, the unit is silently skipped here;
      // the orchestrator (cartouche_engine.dart) is responsible for
      // recording that gap for the UI's approximation disclosure.
      i += 1;
    }

    return result;
  }

  _BiliteralRule? _tryMatchBiliteral(List<ConsonantUnit> units, int pos) {
    if (pos + 1 >= units.length) return null;
    for (final rule in _biliterals) {
      if (rule.pattern.length == 2 &&
          rule.pattern[0] == units[pos].symbol &&
          rule.pattern[1] == units[pos + 1].symbol) {
        return rule;
      }
    }
    return null;
  }
}

class _BiliteralRule {
  final List<String> pattern;
  final String gardinerCode;
  const _BiliteralRule(this.pattern, this.gardinerCode);
}
