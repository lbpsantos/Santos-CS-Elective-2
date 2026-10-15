import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pokemon.dart';
import '../providers/type_filter_provider.dart';
import '../utils/type_colors.dart';

// Row of chips for filtering the Pokemon by type.
class TypeFilterBar extends ConsumerWidget {
  const TypeFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(pokemonTypesProvider);
    final selectedType = ref.watch(typeFilterProvider);
    final filterNotifier = ref.read(typeFilterProvider.notifier);

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          // "All" chip clears the filter.
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedType == null,
              onSelected: (_) => filterNotifier.clearFilter(),
            ),
          ),
          for (final type in types)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(capitalize(type)),
                selected: selectedType == type,
                selectedColor: typeColor(type),
                avatar: CircleAvatar(backgroundColor: typeColor(type)),
                // Tapping the selected chip again clears the filter.
                onSelected: (selected) => selected
                    ? filterNotifier.selectType(type)
                    : filterNotifier.clearFilter(),
              ),
            ),
        ],
      ),
    );
  }
}
