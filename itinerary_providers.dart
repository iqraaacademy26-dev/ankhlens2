import '../../../../core/database/daos/sign_dao.dart';
import '../../../../core/database/app_database.dart' show GardinerSign;
import '../../domain/entities/glyph_sign.dart';
import '../../domain/repositories/dictionary_repository.dart';

/// Drift-backed implementation of [DictionaryRepository]. Maps Drift's
/// generated `GardinerSign` row class to the domain-layer [GlyphSign] so no
/// Drift types leak past the data layer.
class DictionaryRepositoryImpl implements DictionaryRepository {
  final SignDao _signDao;
  const DictionaryRepositoryImpl(this._signDao);

  @override
  Future<List<GlyphSign>> getAllSigns() async {
    final rows = await _signDao.getAllSigns();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<GlyphSign>> getByCategory(String categoryCode) async {
    final rows = await _signDao.getByCategory(categoryCode);
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<GlyphSign>> search(String query) async {
    final rows = await _signDao.searchSigns(query);
    return rows.map(_toDomain).toList();
  }

  @override
  Future<GlyphSign?> getByGardinerCode(String code) async {
    final row = await _signDao.getByGardinerCode(code);
    return row == null ? null : _toDomain(row);
  }

  GlyphSign _toDomain(GardinerSign row) => GlyphSign(
        id: row.id,
        gardinerCode: row.gardinerCode,
        categoryCode: row.categoryCode,
        unicodeGlyph: row.unicodeGlyph,
        transliteration: row.transliteration,
        approxPronunciation: row.approxPronunciation,
        literalMeaning: row.literalMeaning,
        culturalMeaning: row.culturalMeaning,
        historicalContext: row.historicalContext,
        phoneticValue: row.phoneticValue,
        signType: row.signType,
        imageAssetPath: row.imageAssetPath,
        audioAssetPath: row.audioAssetPath,
      );
}
