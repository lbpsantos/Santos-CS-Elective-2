import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/pokedex_page.dart';
import 'providers/settings_provider.dart';

void main() {
  // ProviderScope stores the state of all the Riverpod providers.
  runApp(const ProviderScope(child: MyApp()));
}

// App entry widget.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      // Light mode colors.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.blue[50],
        useMaterial3: true,
      ),
      // Dark mode colors.
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        useMaterial3: true,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const PokedexPage(),
    );
  }
}
