/// Domain-layer representation of a dictionary sign — decoupled from the
/// Drift-generated `GardinerSign` row class so presentation code never
/// depends on the data layer directly.
class GlyphSign {
  final int id;
  final String gardinerCode;
  final String categoryCode;
  final String? unicodeGlyph;
  final String? transliteration;
  final String? approxPronunciation;
  final String? literalMeaning;
  final String? culturalMeaning;
  final String? historicalContext;
  final String? phoneticValue;
  final String signType;
  final String imageAssetPath;
  final String? audioAssetPath;

  const GlyphSign({
    required this.id,
    required this.gardinerCode,
    required this.categoryCode,
    this.unicodeGlyph,
    this.transliteration,
    this.approxPronunciation,
    this.literalMeaning,
    this.culturalMeaning,
    this.historicalContext,
    this.phoneticValue,
    required this.signType,
    required this.imageAssetPath,
    this.audioAssetPath,
  });
}
