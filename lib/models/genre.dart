// A book genre. Each genre is one row in the Supabase `genres` table, and
// each book points to its genre with `genre_id`.
class Genre {
  const Genre({required this.id, required this.name});

  final int id;
  final String name;

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: json['id'] as int, name: json['name'] as String);
  }
}
