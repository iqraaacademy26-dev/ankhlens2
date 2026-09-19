import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../domain/record_manual_selection.dart';

final recordManualSelectionProvider = Provider<RecordManualSelection>((ref) {
  return RecordManualSelection(ref.watch(historyDaoProvider));
});
