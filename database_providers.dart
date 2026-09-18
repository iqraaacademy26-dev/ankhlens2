import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Single app-wide database instance. `keepAlive: true` because closing/
/// reopening the sqlite connection mid-session is never desired.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final signDaoProvider = Provider((ref) => ref.watch(appDatabaseProvider).signDao);
final historyDaoProvider =
    Provider((ref) => ref.watch(appDatabaseProvider).historyDao);
final agencyDaoProvider =
    Provider((ref) => ref.watch(appDatabaseProvider).agencyDao);

/// Runs once at app startup (await this in main() before runApp, or in a
/// splash-screen FutureProvider) to guarantee the dictionary is seeded
/// before any dictionary/scanner UI reads from it.
final dictionarySeedProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  await db.seedDictionaryIfNeeded(
    loadSeedJson: () => rootBundle.loadString('assets/data/signs_v1.json'),
    seedVersion: 1,
  );
});
