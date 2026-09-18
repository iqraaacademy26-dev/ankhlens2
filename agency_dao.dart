import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/agency_tables.dart';

part 'agency_dao.g.dart';

@DriftAccessor(tables: [AgencyProfile, ItineraryItems])
class AgencyDao extends DatabaseAccessor<AppDatabase> with _$AgencyDaoMixin {
  AgencyDao(super.db);

  // ---- Agency profile (singleton row) ----

  Stream<AgencyProfileData?> watchAgencyProfile() {
    return (select(agencyProfile)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }

  Future<void> upsertAgencyProfile(AgencyProfileCompanion profile) {
    return into(agencyProfile).insertOnConflictUpdate(
      profile.copyWith(id: const Value(1)),
    );
  }

  // ---- Itinerary ----

  Stream<List<ItineraryItemsData>> watchItinerary() {
    return (select(itineraryItems)
          ..orderBy([
            (t) => OrderingTerm.asc(t.dayIndex),
            (t) => OrderingTerm.asc(t.scheduledTime),
          ]))
        .watch();
  }

  Future<void> replaceItinerary(List<ItineraryItemsCompanion> items) async {
    // Full replace-on-sync: itinerary is agency-authoritative, so a sync
    // pull replaces the local cache wholesale rather than diffing.
    await transaction(() async {
      await delete(itineraryItems).go();
      await batch((b) => b.insertAll(itineraryItems, items));
    });
  }
}
