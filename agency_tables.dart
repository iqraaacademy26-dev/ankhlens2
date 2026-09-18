import 'package:drift/drift.dart';

/// Singleton row (id is always 1) holding the active white-label agency's
/// branding + contact info. Seeded with a default at first launch; overwritten
/// wholesale when an agency sync succeeds. Never blocks app function if empty.
class AgencyProfile extends Table {
  IntColumn get id =>
      integer().withDefault(const Constant(1)).customConstraint(
            'PRIMARY KEY CHECK (id = 1)',
          )();

  TextColumn get agencyName => text().nullable()();
  TextColumn get logoAssetPath => text().nullable()();
  TextColumn get primaryColorHex => text().nullable()();
  TextColumn get contactPhone => text().nullable()();
  TextColumn get contactWhatsapp => text().nullable()();
  TextColumn get guideName => text().nullable()();
  TextColumn get guidePhotoPath => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per itinerary stop. Pulled once from the agency backend (if any)
/// and cached fully for offline access; a manual/self-guided user can also
/// have locally-created itinerary items with no agency involved.
class ItineraryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayIndex => integer()();
  TextColumn get siteName => text()();
  TextColumn get scheduledTime => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// JSON array of gardiner_code strings — "signs you'll see at this site"
  TextColumn get relatedSignCodesJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
