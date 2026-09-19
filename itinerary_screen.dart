import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../data/repositories/dictionary_repository_impl.dart';
import '../../domain/entities/glyph_sign.dart';
import '../../domain/repositories/dictionary_repository.dart';

final dictionaryRepositoryProvider = Provider<DictionaryRepository>((ref) {
  return DictionaryRepositoryImpl(ref.watch(signDaoProvider));
});

/// null = no category filter applied ("All").
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Combines search + category filter into the list the dictionary/manual
/// selector grids actually render. Re-fetches whenever either filter changes.
final filteredSignsProvider = FutureProvider<List<GlyphSign>>((ref) async {
  final repo = ref.watch(dictionaryRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);

  if (query.trim().isNotEmpty) {
    final results = await repo.search(query);
    if (category == null) return results;
    return results.where((s) => s.categoryCode == category).toList();
  }

  if (category != null) return repo.getByCategory(category);
  return repo.getAllSigns();
});
