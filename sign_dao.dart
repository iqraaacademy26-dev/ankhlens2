import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/gardiner_signs_table.dart';

part 'sign_dao.g.dart';

@DriftAccessor(tables: [GardinerSigns, SignTranslations])
class SignDao extends DatabaseAccessor<AppDatabase> with _$SignDaoMixin {
  SignDao(super.db);

  Future<List<GardinerSign>> getAllSigns() => select(gardinerSigns).get();

  Future<GardinerSign?> getByGardinerCode(String code) {
    return (select(gardinerSigns)
          ..where((t) => t.gardinerCode.equals(code)))
        .getSingleOrNull();
  }

  Future<List<GardinerSign>> getByCategory(String categoryCode) {
    return (select(gardinerSigns)
          ..where((t) => t.categoryCode.equals(categoryCode)))
        .get();
  }

  /// Full-text search over code/transliteration/meanings. Requires the
  /// `signs_fts` virtual table to be created in a migration (see
  /// app_database.dart) — this uses a raw query since drift's generator
  /// doesn't model FTS5 tables directly.
  Future<List<GardinerSign>> searchSigns(String query) async {
    if (query.trim().isEmpty) return getAllSigns();

    final sanitized = query.replaceAll('"', '""');
    final rows = await customSelect(
      '''
      SELECT gs.* FROM gardiner_signs gs
      JOIN signs_fts fts ON fts.rowid = gs.id
      WHERE signs_fts MATCH ?
      ''',
      variables: [Variable.withString('"$sanitized"*')],
      readsFrom: {gardinerSigns},
    ).get();

    return rows.map((row) => gardinerSigns.map(row.data)).toList();
  }

  Future<int> upsertSign(GardinerSignsCompanion sign) {
    return into(gardinerSigns).insertOnConflictUpdate(sign);
  }

  Future<void> upsertSigns(List<GardinerSignsCompanion> signs) async {
    await batch((b) => b.insertAllOnConflictUpdate(gardinerSigns, signs));
  }

  Future<String?> getLocalizedLiteralMeaning(int signId, String locale) async {
    final row = await (select(signTranslations)
          ..where((t) => t.signId.equals(signId) & t.locale.equals(locale)))
        .getSingleOrNull();
    return row?.literalMeaning;
  }
}
