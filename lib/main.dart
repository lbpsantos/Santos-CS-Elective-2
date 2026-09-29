import 'package:flutter/material.dart';
import 'screens/pokedex_screen.dart';

void main() {
  runApp(const MyApp());
}

// App entry widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const PokedexScreen(),
    );
  }
}
