// Pokemon model.
class Pokemon {
  final int id;
  final String name;
  final String imageUrl;

  Pokemon({required this.id, required this.name, required this.imageUrl});

  // Build a Pokemon from the API json.
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    // Get the ID from the url (ex: .../pokemon/25/).
    final url = json['url'] as String;
    final parts = url.split('/');
    final id = int.parse(parts[parts.length - 2]);

    return Pokemon(
      id: id,
      name: json['name'],
      imageUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
    );
  }
}
