import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/history_tables.dart';

part 'history_dao.g.dart';

@DriftAccessor(tables: [ScanHistory, CartoucheGenerations])
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.db);

  // ---- Scan history ----

  Future<int> recordScan({
    required int signId,
    required double confidence,
    required bool wasManuallySelected,
    String? imageThumbnailPath,
  }) {
    return into(scanHistory).insert(
      ScanHistoryCompanion.insert(
        signId: signId,
        confidence: confidence,
        wasManuallySelected: Value(wasManuallySelected),
        imageThumbnailPath: Value(imageThumbnailPath),
        scannedAt: DateTime.now(),
      ),
    );
  }

  Stream<List<ScanHistoryData>> watchRecentScans({int limit = 50}) {
    return (select(scanHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)])
          ..limit(limit))
        .watch();
  }

  // ---- Cartouche generations ----

  Future<int> saveCartouche({
    required String inputName,
    required String phonemeBreakdownJson,
    required String signSequenceJson,
    required String approximationFlagsJson,
    String? renderedAssetPath,
  }) {
    return into(cartoucheGenerations).insert(
      CartoucheGenerationsCompanion.insert(
        inputName: inputName,
        phonemeBreakdownJson: phonemeBreakdownJson,
        signSequenceJson: signSequenceJson,
        approximationFlagsJson: approximationFlagsJson,
        renderedAssetPath: Value(renderedAssetPath),
        createdAt: DateTime.now(),
      ),
    );
  }

  Stream<List<CartoucheGenerationsData>> watchSavedCartouches() {
    return (select(cartoucheGenerations)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}
