import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_flutter_ui/main.dart';
import 'package:my_first_flutter_ui/models/pokemon.dart';
import 'package:my_first_flutter_ui/providers/pokemon_provider.dart';

// Fake notifier so the test doesn't need the internet.
class FakePokemonListNotifier extends PokemonListNotifier {
  @override
  Future<List<Pokemon>> build() async => [
    Pokemon(id: 1, name: 'bulbasaur', imageUrl: '', types: ['grass']),
    Pokemon(id: 4, name: 'charmander', imageUrl: '', types: ['fire']),
  ];
}

void main() {
  testWidgets('Shows Pokemon, filters by type and adds a favorite', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pokemonListProvider.overrideWith(FakePokemonListNotifier.new),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Charmander'), findsOneWidget);

    // Filter by Fire.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Fire'));
    await tester.pumpAndSettle();
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Charmander'), findsOneWidget);

    // Clear the filter.
    await tester.tap(find.text('Clear filter'));
    await tester.pumpAndSettle();
    expect(find.text('Bulbasaur'), findsOneWidget);

    // Tap the heart on the first card, then open the favorites panel.
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites (1)'), findsOneWidget);
  });
}
