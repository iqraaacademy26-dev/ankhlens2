/// A deterministic phoneme unit produced by grapheme-to-phoneme conversion.
/// `symbol` uses a simplified ARPABET-like alphabet — not full ARPABET,
/// just enough distinct symbols for the consonant-skeleton stage to work with.
class Phoneme {
  final String symbol; // e.g. "AH", "L", "EH", "K", "S", "AE", "N", "D", "ER"
  final bool isVowel;

  const Phoneme(this.symbol, {required this.isVowel});

  @override
  String toString() => symbol;

  @override
  bool operator ==(Object other) =>
      other is Phoneme && other.symbol == symbol && other.isVowel == isVowel;

  @override
  int get hashCode => Object.hash(symbol, isVowel);
}

/// Rule-based, on-device English grapheme-to-phoneme (G2P) converter.
///
/// Deliberately NOT a full CMUdict/ML G2P model: the goal here is a small,
/// deterministic, auditable rule table an Egyptology consultant can review
/// and that unit tests can pin exactly — not maximum phonetic accuracy on
/// every possible English name. Expand [_digraphRules] / [_singleRules] as
/// real-world name coverage gaps are found.
class G2PConverter {
  /// Longest-match-first digraph/trigraph rules, checked before single
  /// letters. Order matters — more specific patterns must come first.
  static final List<MapEntry<String, List<Phoneme>>> _multiLetterRules = [
    // Trigraphs
    MapEntry('tch', const [Phoneme('CH', isVowel: false)]),
    MapEntry('igh', const [Phoneme('AY', isVowel: true)]),
    // Digraphs — consonant clusters commonly written as one sound
    MapEntry('ph', const [Phoneme('F', isVowel: false)]),
    MapEntry('th', const [Phoneme('TH', isVowel: false)]),
    MapEntry('sh', const [Phoneme('SH', isVowel: false)]),
    MapEntry('ch', const [Phoneme('CH', isVowel: false)]),
    MapEntry('ck', const [Phoneme('K', isVowel: false)]),
    MapEntry('ng', const [Phoneme('NG', isVowel: false)]),
    MapEntry('qu', const [Phoneme('K', isVowel: false), Phoneme('W', isVowel: false)]),
    MapEntry('wh', const [Phoneme('W', isVowel: false)]),
    MapEntry('kh', const [Phoneme('KH', isVowel: false)]),
    // Digraph vowels
    MapEntry('ee', const [Phoneme('IY', isVowel: true)]),
    MapEntry('ea', const [Phoneme('IY', isVowel: true)]),
    MapEntry('oo', const [Phoneme('UW', isVowel: true)]),
    MapEntry('ou', const [Phoneme('AW', isVowel: true)]),
    MapEntry('ow', const [Phoneme('AW', isVowel: true)]),
    MapEntry('ai', const [Phoneme('EY', isVowel: true)]),
    MapEntry('ay', const [Phoneme('EY', isVowel: true)]),
    MapEntry('oy', const [Phoneme('OY', isVowel: true)]),
    MapEntry('oi', const [Phoneme('OY', isVowel: true)]),
    MapEntry('ie', const [Phoneme('AY', isVowel: true)]),
    MapEntry('ei', const [Phoneme('EY', isVowel: true)]),
    MapEntry('au', const [Phoneme('AO', isVowel: true)]),
    MapEntry('aw', const [Phoneme('AO', isVowel: true)]),
  ];

  /// Single-letter fallback rules, applied when no multi-letter rule matches
  /// at the current position.
  static final Map<String, List<Phoneme>> _singleLetterRules = {
    'a': const [Phoneme('AE', isVowel: true)],
    'b': const [Phoneme('B', isVowel: false)],
    'c': const [Phoneme('K', isVowel: false)], // simplification; see _softC
    'd': const [Phoneme('D', isVowel: false)],
    'e': const [Phoneme('EH', isVowel: true)],
    'f': const [Phoneme('F', isVowel: false)],
    'g': const [Phoneme('G', isVowel: false)],
    'h': const [Phoneme('HH', isVowel: false)],
    'i': const [Phoneme('IH', isVowel: true)],
    'j': const [Phoneme('JH', isVowel: false)],
    'k': const [Phoneme('K', isVowel: false)],
    'l': const [Phoneme('L', isVowel: false)],
    'm': const [Phoneme('M', isVowel: false)],
    'n': const [Phoneme('N', isVowel: false)],
    'o': const [Phoneme('AA', isVowel: true)],
    'p': const [Phoneme('P', isVowel: false)],
    'q': const [Phoneme('K', isVowel: false)],
    'r': const [Phoneme('R', isVowel: false)],
    's': const [Phoneme('S', isVowel: false)],
    't': const [Phoneme('T', isVowel: false)],
    'u': const [Phoneme('AH', isVowel: true)],
    'v': const [Phoneme('V', isVowel: false)],
    'w': const [Phoneme('W', isVowel: false)],
    'x': const [Phoneme('K', isVowel: false), Phoneme('S', isVowel: false)],
    'y': const [Phoneme('Y', isVowel: false)], // treated as consonant onset
    'z': const [Phoneme('Z', isVowel: false)],
  };

  static const Set<String> _softCFollowers = {'e', 'i', 'y'};
  static const Set<String> _softGFollowers = {'e', 'i', 'y'};

  /// Converts [name] into an ordered list of [Phoneme]s.
  ///
  /// This is a heuristic rule pass, not a dictionary lookup — it will not
  /// match professional G2P/CMUdict accuracy on irregular English spellings,
  /// which is an accepted tradeoff for staying deterministic and offline.
  List<Phoneme> convert(String name) {
    final input = name.trim().toLowerCase().replaceAll(
          RegExp(r"[^a-z]"),
          '',
        );
    if (input.isEmpty) return const [];

    final phonemes = <Phoneme>[];
    var i = 0;

    while (i < input.length) {
      // Soft C / soft G special cases first (context-sensitive, single letter).
      if (input[i] == 'c' &&
          i + 1 < input.length &&
          _softCFollowers.contains(input[i + 1])) {
        phonemes.add(const Phoneme('S', isVowel: false));
        i += 1;
        continue;
      }
      if (input[i] == 'g' &&
          i + 1 < input.length &&
          _softGFollowers.contains(input[i + 1])) {
        phonemes.add(const Phoneme('JH', isVowel: false));
        i += 1;
        continue;
      }

      // Longest-match multi-letter rules (trigraphs, then digraphs).
      final matched = _tryMatchMultiLetter(input, i);
      if (matched != null) {
        phonemes.addAll(matched.value);
        i += matched.key;
        continue;
      }

      // Silent trailing 'e' (very common English pattern: "e" at word end
      // after a consonant, e.g. "Anne", "Kate" — dropped, not phonemized).
      if (input[i] == 'e' && i == input.length - 1 && input.length > 1) {
        i += 1;
        continue;
      }

      // Fallback: single-letter rule.
      final single = _singleLetterRules[input[i]];
      if (single != null) {
        phonemes.addAll(single);
      }
      i += 1;
    }

    return phonemes;
  }

  MapEntry<int, List<Phoneme>>? _tryMatchMultiLetter(String input, int pos) {
    for (final rule in _multiLetterRules) {
      final pattern = rule.key;
      if (pos + pattern.length <= input.length &&
          input.substring(pos, pos + pattern.length) == pattern) {
        return MapEntry(pattern.length, rule.value);
      }
    }
    return null;
  }
}
