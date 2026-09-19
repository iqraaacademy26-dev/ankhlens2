import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/gardiner_category.dart';
import '../providers/dictionary_providers.dart';

class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: gardinerCategories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) =>
                  ref.read(selectedCategoryProvider.notifier).state = null,
            );
          }
          final category = gardinerCategories[index - 1];
          final isSelected = selected == category.code;
          return ChoiceChip(
            label: Text(category.label),
            selected: isSelected,
            onSelected: (_) =>
                ref.read(selectedCategoryProvider.notifier).state =
                    isSelected ? null : category.code,
          );
        },
      ),
    );
  }
}
