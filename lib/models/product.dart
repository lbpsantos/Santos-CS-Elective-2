class Product {
  final String id;
  final String name;
  final String author;
  final double price;
  final String description;
  final String imageUrl;
  final String genre;
  final double rating;

  const Product({
    required this.id,
    required this.name,
    required this.author,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.genre = 'Fantasy',
    this.rating = 4.8,
  });
}

// Book Catalog
const List<Product> sampleProducts = [
  Product(
    id: 'hp1',
    name: "Harry Potter and the Philosopher's Stone",
    author: 'J.K. Rowling',
    price: 499.00,
    description:
        'Harry Potter has never even heard of Hogwarts when the letters start dropping on the doormat at number four, Privet Drive. On his eleventh birthday, he discovers he is a wizard and begins his magical journey.',
    imageUrl: 'lib/assets/9781408855652.webp',
    genre: 'Fantasy / Magic',
    rating: 4.8,
  ),
  Product(
    id: 'hp2',
    name: 'Harry Potter and the Chamber of Secrets',
    author: 'J.K. Rowling',
    price: 529.00,
    description:
        'The plot follows Harry\'s second year at Hogwarts School of Witchcraft and Wizardry, during which a series of messages on the walls of the school\'s corridors warn that the "Chamber of Secrets" has been opened.',
    imageUrl: 'lib/assets/harry-potter-and-the-chamber-of-secrets.jpeg',
    genre: 'Fantasy / Magic',
    rating: 4.7,
  ),
  Product(
    id: 'hp4',
    name: 'Harry Potter and the Goblet of Fire',
    author: 'J.K. Rowling',
    price: 599.00,
    description:
        'Harry Potter is midway through his training as a wizard and his coming of age. The Triwizard Tournament is to be held at Hogwarts, and Harry finds his name mysteriously drawn from the Goblet of Fire.',
    imageUrl: 'lib/assets/images.jfif',
    genre: 'Fantasy / Adventure',
    rating: 4.9,
  ),
  Product(
    id: 'hp7',
    name: 'Harry Potter and the Deathly Hallows',
    author: 'J.K. Rowling',
    price: 649.00,
    description:
        'The climactic seventh and final novel of the Harry Potter series. Harry, Ron, and Hermione leave Hogwarts to track down and destroy Lord Voldemort\'s remaining Horcruxes.',
    imageUrl: 'lib/assets/images (1).jfif',
    genre: 'Fantasy / Epic',
    rating: 4.9,
  ),
  Product(
    id: 'pj1',
    name: 'The Lightning Thief',
    author: 'Rick Riordan',
    price: 450.00,
    description:
        'Percy Jackson is a good kid, but he can\'t seem to focus on his schoolwork or control his temper. When his mom tells him the truth about who he is—a demigod son of Poseidon—his world changes forever.',
    imageUrl: 'lib/assets/images (2).jfif',
    genre: 'Mythology / Adventure',
    rating: 4.8,
  ),
  Product(
    id: 'pj2',
    name: 'The Sea of Monsters',
    author: 'Rick Riordan',
    price: 450.00,
    description:
        'Percy Jackson\'s seventh-grade year has been quiet until a game of dodgeball turns into a death match against giants. To save Camp Half-Blood, Percy and his friends must sail into the Sea of Monsters.',
    imageUrl: 'lib/assets/images (3).jfif',
    genre: 'Mythology / Adventure',
    rating: 4.7,
  ),
];
