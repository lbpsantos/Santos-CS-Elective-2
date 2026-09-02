class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
  });
}

// List of Products
const List<Product> sampleProducts = [
  Product(
    id: '1',
    name: 'Sample Product 1',
    price: 10,
    description: '',
    imageUrl: '',
  ),
  Product(
    id: '2',
    name: 'Sample Product 2',
    price: 10,
    description: '',
    imageUrl: '',
  ),
  Product(
    id: '3',
    name: 'Sample Product 3',
    price: 10,
    description: '',
    imageUrl: '',
  ),
  Product(
    id: '4',
    name: 'Sample Product 4',
    price: 10,
    description: '',
    imageUrl: '',
  ),
  Product(
    id: '5',
    name: 'Sample Product 5',
    price: 10,
    description: '',
    imageUrl: '',
  ),
  Product(
    id: '6',
    name: 'Sample Product 6',
    price: 10,
    description: '',
    imageUrl: '',
  ),
];
