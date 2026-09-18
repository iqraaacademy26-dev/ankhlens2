import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'daos/sign_dao.dart';
import 'daos/history_dao.dart';
import 'daos/agency_dao.dart';
import 'tables/gardiner_signs_table.dart';
import 'tables/history_tables.dart';
import 'tables/agency_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    GardinerSigns,
    SignTranslations,
    ContentVersions,
    ScanHistory,
    CartoucheGenerations,
    AgencyProfile,
    ItineraryItems,
  ],
  daos: [SignDao, HistoryDao, AgencyDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Bump this whenever the table *schema* changes (not the seed content —
  /// content versioning is handled separately via [ContentVersions]).
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createFtsTable();
        },
        onUpgrade: (m, from, to) async {
          // Additive migrations go here as schemaVersion increments, e.g.:
          // if (from < 2) { await m.addColumn(gardinerSigns, gardinerSigns.someNewColumn); }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createFtsTable() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS signs_fts USING fts5(
        gardiner_code, transliteration, literal_meaning, cultural_meaning,
        content='gardiner_signs', content_rowid='id'
      );
    ''');
    // Keep FTS in sync with the content table.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS signs_ai AFTER INSERT ON gardiner_signs BEGIN
        INSERT INTO signs_fts(rowid, gardiner_code, transliteration, literal_meaning, cultural_meaning)
        VALUES (new.id, new.gardiner_code, new.transliteration, new.literal_meaning, new.cultural_meaning);
      END;
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS signs_ad AFTER DELETE ON gardiner_signs BEGIN
        INSERT INTO signs_fts(signs_fts, rowid, gardiner_code, transliteration, literal_meaning, cultural_meaning)
        VALUES('delete', old.id, old.gardiner_code, old.transliteration, old.literal_meaning, old.cultural_meaning);
      END;
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS signs_au AFTER UPDATE ON gardiner_signs BEGIN
        INSERT INTO signs_fts(signs_fts, rowid, gardiner_code, transliteration, literal_meaning, cultural_meaning)
        VALUES('delete', old.id, old.gardiner_code, old.transliteration, old.literal_meaning, old.cultural_meaning);
        INSERT INTO signs_fts(rowid, gardiner_code, transliteration, literal_meaning, cultural_meaning)
        VALUES (new.id, new.gardiner_code, new.transliteration, new.literal_meaning, new.cultural_meaning);
      END;
    ''');
  }

  /// Imports assets/data/signs_v1.json into the DB if it hasn't been
  /// imported yet (tracked via [ContentVersions]). Call once at app startup,
  /// before any dictionary UI reads. Safe to call every launch — it's a no-op
  /// once the current version is already imported.
  Future<void> seedDictionaryIfNeeded({
    required Future<String> Function() loadSeedJson,
    int seedVersion = 1,
    String contentKey = 'gardiner_signs',
  }) async {
    final existing = await (select(contentVersions)
          ..where((t) => t.contentKey.equals(contentKey)))
        .getSingleOrNull();

    if (existing != null && existing.version >= seedVersion) return;

    final jsonString = await loadSeedJson();
    final List<dynamic> raw = jsonDecode(jsonString) as List<dynamic>;

    final companions = raw.map((entry) {
      final map = entry as Map<String, dynamic>;
      return GardinerSignsCompanion.insert(
        gardinerCode: map['gardiner_code'] as String,
        categoryCode: map['category_code'] as String,
        unicodeGlyph: Value(map['unicode_glyph'] as String?),
        transliteration: Value(map['transliteration'] as String?),
        approxPronunciation: Value(map['approx_pronunciation'] as String?),
        literalMeaning: Value(map['literal_meaning'] as String?),
        culturalMeaning: Value(map['cultural_meaning'] as String?),
        historicalContext: Value(map['historical_context'] as String?),
        phoneticValue: Value(map['phonetic_value'] as String?),
        signType: map['sign_type'] as String,
        imageAssetPath: map['image_asset_path'] as String,
        audioAssetPath: Value(map['audio_asset_path'] as String?),
      );
    }).toList();

    await transaction(() async {
      await batch((b) => b.insertAllOnConflictUpdate(gardinerSigns, companions));
      await into(contentVersions).insertOnConflictUpdate(
        ContentVersionsCompanion.insert(
          contentKey: contentKey,
          version: seedVersion,
          importedAt: DateTime.now(),
        ),
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Required on some older Android devices for sqlite3_flutter_libs to load correctly.
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ankhlens.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
