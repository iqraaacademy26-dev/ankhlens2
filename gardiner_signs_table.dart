import 'package:drift/drift.dart';

/// Canonical Gardiner sign dictionary — seeded from assets/data/signs_v1.json
/// on first launch (or on content-version bump). See [SignTranslations] for
/// per-locale copy.
class GardinerSigns extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// e.g. "G17"
  TextColumn get gardinerCode => text().unique()();

  /// Gardiner category letter, e.g. "G" (birds), "A" (man and his occupations)
  TextColumn get categoryCode => text()();

  /// Unicode Egyptian Hieroglyph code point, if one exists for this sign.
  TextColumn get unicodeGlyph => text().nullable()();

  /// Standard Egyptological transliteration, e.g. "m"
  TextColumn get transliteration => text().nullable()();

  /// Tourist-friendly approximate pronunciation, e.g. "mm" (owl convention)
  TextColumn get approxPronunciation => text().nullable()();

  TextColumn get literalMeaning => text().nullable()();
  TextColumn get culturalMeaning => text().nullable()();
  TextColumn get historicalContext => text().nullable()();

  /// Phonetic value the sign carries when used phonetically (null for pure
  /// ideograms/determinatives that carry no sound value).
  TextColumn get phoneticValue => text().nullable()();

  /// uniliteral | biliteral | triliteral | ideogram | determinative
  TextColumn get signType => text()();

  TextColumn get imageAssetPath => text()();
  TextColumn get audioAssetPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Localized copy for a sign (en, ar, fr, ...). Falls back to the base
/// [GardinerSigns] English fields when no row exists for the active locale.
class SignTranslations extends Table {
  IntColumn get signId =>
      integer().references(GardinerSigns, #id)();
  TextColumn get locale => text()();

  TextColumn get literalMeaning => text().nullable()();
  TextColumn get culturalMeaning => text().nullable()();
  TextColumn get historicalContext => text().nullable()();

  @override
  Set<Column> get primaryKey => {signId, locale};
}

/// Tracks which version of the seed JSON has been imported, so app updates
/// can ship signs_v2.json etc. and migrate additively without a full re-seed.
class ContentVersions extends Table {
  TextColumn get contentKey => text()(); // e.g. "gardiner_signs"
  IntColumn get version => integer()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {contentKey};
}
