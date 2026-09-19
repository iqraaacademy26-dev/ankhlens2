import 'glyph_sign.dart';

/// Domain-facing contract for reading the sign dictionary. The presentation
/// layer depends only on this interface, never on Drift directly — this is
/// also the seam a future white-label build could override if an agency
/// ever needed a different dictionary source.
abstract class DictionaryRepository {
  Future<List<GlyphSign>> getAllSigns();
  Future<List<GlyphSign>> getByCategory(String categoryCode);
  Future<List<GlyphSign>> search(String query);
  Future<GlyphSign?> getByGardinerCode(String code);
}
