// Pokemon model.
class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
  });

  // Build a Pokemon from the details json (.../pokemon/25/).
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;

    // "types" looks like: [{slot: 1, type: {name: grass, url: ...}}, ...]
    final List typesJson = json['types'];
    final types = typesJson
        .map((item) => item['type']['name'] as String)
        .toList();

    return Pokemon(
      id: id,
      name: json['name'],
      imageUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
      types: types,
    );
  }

  // Name with the first letter capitalized (ex: pikachu -> Pikachu).
  String get displayName => capitalize(name);
}

// Capitalize the first letter of a word.
String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
