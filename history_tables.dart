import 'package:drift/drift.dart';
import 'gardiner_signs_table.dart';

/// One row per scanned/manually-identified glyph. Fully local — no image data
/// or PII ever leaves the device unless the user explicitly shares a result.
class ScanHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get signId => integer().references(GardinerSigns, #id)();
  RealColumn get confidence => real()();

  /// null when the result came from the Manual Glyph Selector rather than ML
  BoolColumn get wasManuallySelected =>
      boolean().withDefault(const Constant(false))();

  TextColumn get imageThumbnailPath => text().nullable()();
  DateTimeColumn get scannedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local record of a generated cartouche. [phonemeBreakdownJson] and
/// [signSequenceJson] are stored as JSON-encoded string arrays rather than
/// normalized child tables — they're write-once, read-whole, and never
/// queried by individual element, so normalizing would add join overhead
/// for no benefit.
class CartoucheGenerations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get inputName => text()();

  /// JSON array, e.g. ["A","LEK","SAN","DER"]
  TextColumn get phonemeBreakdownJson => text()();

  /// JSON array of Gardiner codes used, in cartouche order
  TextColumn get signSequenceJson => text()();

  /// JSON array of booleans/flags marking which segments were approximated
  /// vs. cleanly matched — drives the disclaimer detail in the UI.
  TextColumn get approximationFlagsJson => text()();

  TextColumn get renderedAssetPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
