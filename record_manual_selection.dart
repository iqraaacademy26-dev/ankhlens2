import '../../../core/database/daos/history_dao.dart';

/// Records a manually-picked glyph into scan history, identically to how an
/// ML-classified result will be recorded once Phase 3 wires in the CV
/// pipeline (confidence fixed at 1.0, flagged `wasManuallySelected`). Kept as
/// a thin use case so presentation code never talks to the DAO directly.
class RecordManualSelection {
  final HistoryDao _historyDao;
  const RecordManualSelection(this._historyDao);

  Future<void> call({required int signId, String? imageThumbnailPath}) {
    return _historyDao.recordScan(
      signId: signId,
      confidence: 1.0,
      wasManuallySelected: true,
      imageThumbnailPath: imageThumbnailPath,
    );
  }
}
