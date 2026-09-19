import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../glyph_dictionary/domain/entities/glyph_sign.dart';
import '../../glyph_dictionary/presentation/providers/dictionary_providers.dart';
import '../../glyph_dictionary/presentation/widgets/category_filter_bar.dart';
import '../../glyph_dictionary/presentation/widgets/glyph_detail_sheet.dart';
import '../../glyph_dictionary/presentation/widgets/sign_grid_tile.dart';
import 'providers/manual_selection_providers.dart';

/// Phase-2 "manual-first" scanning screen: a tourist browses/searches the
/// full dictionary and picks the glyph they see, rather than waiting on ML.
/// This is a first-class feature (per the architecture doc), not just a
/// fallback UI — it validates the entire data + presentation path before
/// any model exists, and stays in the app afterward as the ML fallback.
class ManualGlyphSelectorScreen extends ConsumerStatefulWidget {
  /// Optional photo captured just before opening the selector. Null when
  /// opened directly from a "browse dictionary" entry point with no scan
  /// in progress.
  final String? capturedImagePath;

  const ManualGlyphSelectorScreen({super.key, this.capturedImagePath});

  @override
  ConsumerState<ManualGlyphSelectorScreen> createState() =>
      _ManualGlyphSelectorScreenState();
}

class _ManualGlyphSelectorScreenState
    extends ConsumerState<ManualGlyphSelectorScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signsAsync = ref.watch(filteredSignsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select a Glyph')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by code, transliteration, or meaning',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
            ),
          ),
          const SizedBox(height: 8),
          const CategoryFilterBar(),
          const SizedBox(height: 8),
          Expanded(
            child: signsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Could not load dictionary: $err')),
              data: (signs) {
                if (signs.isEmpty) {
                  return const Center(child: Text('No matching glyphs found.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: signs.length,
                  itemBuilder: (context, index) {
                    final sign = signs[index];
                    return SignGridTile(
                      sign: sign,
                      onTap: () => _onSignSelected(context, sign),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSignSelected(BuildContext context, GlyphSign sign) async {
    await ref.read(recordManualSelectionProvider).call(
          signId: sign.id,
          imageThumbnailPath: widget.capturedImagePath,
        );
    if (!context.mounted) return;
    await GlyphDetailSheet.show(
      context,
      sign: sign,
      wasManuallySelected: true,
    );
  }
}
