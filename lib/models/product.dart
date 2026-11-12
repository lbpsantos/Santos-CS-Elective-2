// A book sold in the shop. Each book is one row in the Supabase `products`
// table (see supabase/products.sql and supabase/final_project.sql).
class Product {
  // null for a new book that is not saved in Supabase yet.
  // Supabase gives the book its id when it is added.
  final int? id;
  final String name;
  final String author;
  final double price;
  final String description;
  // A web link (https://...), an asset path (lib/assets/...), or empty for
  // no cover.
  final String imageUrl;
  // The id of the book's genre in the `genres` table (null = no genre).
  final int? genreId;
  // The genre's name, read from the `genres` table. Empty = no genre.
  final String genre;
  // 0 means the book has no rating yet.
  final double rating;
  // How many copies are left. 0 = out of stock, can't be added to a cart.
  final int stock;

  const Product({
    this.id,
    required this.name,
    required this.author,
    required this.price,
    this.description = '',
    this.imageUrl = '',
    this.genreId,
    this.genre = '',
    this.rating = 0,
    this.stock = 0,
  });

  bool get inStock => stock > 0;

  // Makes a Product from a row that Supabase sent back.
  // The row looks like {..., 'genre_id': 5, 'genres': {'name': 'Magic'}},
  // because ProductService asks for the genre's name with the book.
  factory Product.fromJson(Map<String, dynamic> json) {
    final genreRow = json['genres'] as Map<String, dynamic>?;
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      author: json['author'] as String? ?? '',
      // Numbers can come back as an int (499) or a double (499.5).
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      genreId: json['genre_id'] as int?,
      genre: genreRow?['name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  // The columns sent to Supabase when a book is added or edited.
  // id and created_at are left out because Supabase fills them in, and the
  // genre is saved by its id (the name stays in the genres table).
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'author': author,
      'price': price,
      'description': description,
      'image_url': imageUrl.isEmpty ? null : imageUrl,
      'genre_id': genreId,
      'rating': rating,
      'stock': stock,
    };
  }

  Product copyWith({int? stock}) {
    return Product(
      id: id,
      name: name,
      author: author,
      price: price,
      description: description,
      imageUrl: imageUrl,
      genreId: genreId,
      genre: genre,
      rating: rating,
      stock: stock ?? this.stock,
    );
  }
}
