import 'g2p_rules.dart';
import 'phoneme_normalizer.dart';
import 'sign_mapper.dart';

/// Full result of running a name through the phonetic pipeline. This is what
/// the UI and [CartoucheGenerations] DB row are built from.
class CartoucheResult {
  final String inputName;
  final List<Phoneme> phonemes;
  final List<ConsonantUnit> consonantSkeleton;
  final List<MappedSign> signs;

  /// True if ANY segment of the result is an approximation rather than an
  /// established sign match. Drives the disclaimer requirement.
  final bool hasApproximations;

  const CartoucheResult({
    required this.inputName,
    required this.phonemes,
    required this.consonantSkeleton,
    required this.signs,
    required this.hasApproximations,
  });

  /// Gardiner codes only, in cartouche order — convenience for rendering.
  List<String> get gardinerCodeSequence =>
      signs.map((s) => s.gardinerCode).toList();
}

/// Public entry point for the cartouche phonetic pipeline described in the
/// architecture doc §5:
///   name -> G2P -> consonantal normalization -> sign mapping -> result
///
/// Each stage is a pure function on its own inputs, which is what makes this
/// independently unit-testable per stage (see test/features/cartouche_maker/
/// phonetics/). The engine itself just wires the stages together.
class CartoucheEngine {
  final G2PConverter _g2p;
  final PhonemeNormalizer _normalizer;
  final SignMapper _signMapper;

  CartoucheEngine({
    required SignMapper signMapper,
    G2PConverter? g2p,
    PhonemeNormalizer? normalizer,
  })  : _signMapper = signMapper,
        _g2p = g2p ?? G2PConverter(),
        _normalizer = normalizer ?? PhonemeNormalizer();

  CartoucheResult generate(String name) {
    final phonemes = _g2p.convert(name);
    final consonantSkeleton = _normalizer.normalize(phonemes);
    final signs = _signMapper.mapToSigns(consonantSkeleton);

    final hasApproximations = signs.any((s) => s.isApproximated) ||
        // Also flag if the skeleton had units that produced NO sign at all
        // (dropped for lack of an uniliteral/biliteral match) -- those are
        // silent gaps the UI should still be able to surface via count
        // mismatch between skeleton length and signs length.
        signs.length < consonantSkeleton.length;

    return CartoucheResult(
      inputName: name,
      phonemes: phonemes,
      consonantSkeleton: consonantSkeleton,
      signs: signs,
      hasApproximations: hasApproximations,
    );
  }
}
