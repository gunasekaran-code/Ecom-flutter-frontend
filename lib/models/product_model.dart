class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final int? categoryId;
  final String? imageUrl;
  final List<String> images;
  final int stock;
  final double rating;
  final bool delFlag;
  final bool isInStock;
  final String createdAt;
  final int? skuId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.categoryId,
    this.imageUrl,
    required this.images,
    required this.stock,
    required this.rating,
    required this.delFlag,
    required this.isInStock,
    required this.createdAt,
    this.skuId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List<dynamic>? ?? const [];

    // Parse category safely - prioritize display name, then name, then convert ID to string
    String categoryValue;
    if (json['category_display_name'] != null &&
        json['category_display_name'].toString().isNotEmpty) {
      categoryValue = json['category_display_name'].toString();
    } else if (json['category_name'] != null &&
        json['category_name'].toString().isNotEmpty) {
      categoryValue = json['category_name'].toString();
    } else if (json['category'] != null) {
      categoryValue = json['category'].toString();
    } else {
      categoryValue = 'Unknown';
    }

    // Parse category ID
    int? categoryIdValue;
    if (json['category'] is int) {
      categoryIdValue = json['category'] as int;
    } else if (json['category'] is String) {
      categoryIdValue = int.tryParse(json['category'] as String);
    }

    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      category: categoryValue,
      categoryId: categoryIdValue,
      imageUrl: json['image_url'],
      images: rawImages
          .map(
            (e) => e is Map<String, dynamic>
                ? e['image_url']?.toString()
                : e?.toString(),
          )
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .toList(),
      stock: json['stock'],
      rating: double.parse(json['rating'].toString()),
      delFlag: json['del_flag'] ?? false,
      isInStock: json['is_in_stock'] ?? false,
      createdAt: json['created_at'],
      skuId: json['sku_id'],
    );
  }

  Map<String, dynamic> toWishlistItem() {
    return {
      'product_id': id,
      'product_name': name,
      'description': description,
      'price': price,
      'category': category,
      'image': imageUrl,
      'rating': rating,
      'stock': stock,
      'is_in_stock': isInStock,
    };
  }

  Map<String, dynamic> toCartItem({int quantity = 1}) {
    return {
      'product_id': id,
      'product_name': name,
      'image': imageUrl,
      'price': price,
      'quantity': quantity,
      'available_stock': stock,
      'is_in_stock': isInStock,
    };
  }
}

const List<Map<String, dynamic>> staticCategories = [
  {'id': 0, 'name': 'all', 'display_name': 'All'},
  {'id': null, 'name': 'weapons', 'display_name': 'Weapons'},
  {'id': null, 'name': 'sports', 'display_name': 'Uniforms'},
  {'id': null, 'name': 'accessories', 'display_name': 'Accessories'},
];

final List<Product> staticProducts = [
  Product(
    id: 101,
    name: 'Surul vaal',
    description: 'High-quality steel practice sword for martial arts training.',
    price: 79.99,
    category: 'weapons',
    categoryId: 1,
    imageUrl: 'https://m.media-amazon.com/images/I/61NceaQeQ5L.jpg',
    images: ['https://m.media-amazon.com/images/I/61NceaQeQ5L.jpg'],
    stock: 12,
    rating: 4.5,
    delFlag: false,
    isInStock: true,
    createdAt: '2026-06-01',
    skuId: 1001,
  ),
  Product(
    id: 102,
    name: 'Silambam Kambu',
    description:
        'Premium quality roasted bamboo staff (Pirambu) for traditional martial arts practice and tournaments.',
    price: 24.99,
    category: 'weapons',
    categoryId: 1,
    imageUrl:
        'https://miro.medium.com/v2/resize:fit:1000/0*V4-yNet09q1-8UDN.jpg',
    images: [
      'https://miro.medium.com/v2/resize:fit:1000/0*V4-yNet09q1-8UDN.jpg',
    ],
    stock: 35,
    rating: 4.8,
    delFlag: false,
    isInStock: true,
    createdAt: '2026-06-04',
    skuId: 1002,
  ),
  Product(
    id: 103,
    name: 'Maan Kombu',
    description: 'Elegant wooden stand for collectibles and training swords.',
    price: 49.99,
    category: 'weapons',
    categoryId: 1,
    imageUrl:
        'https://5.imimg.com/data5/ANDROID/Default/2022/2/UM/JY/TH/50095616/product-jpeg.jpg',
    images: [
      'https://5.imimg.com/data5/ANDROID/Default/2022/2/UM/JY/TH/50095616/product-jpeg.jpg',
    ],
    stock: 10,
    rating: 4.7,
    delFlag: false,
    isInStock: true,
    createdAt: '2026-06-05',
    skuId: 1005,
  ),
  Product(
    id: 104,
    name: 'T-shirt',
    description:
        'Breathable, moisture-wicking athletic jersey designed for maximum comfort and peak performance.',
    price: 34.99,
    category: 'sports',
    categoryId: 2,
    imageUrl:
        'https://fashionous.in/cdn/shop/files/Silambam_women_s_Tshirt_mockup.jpg?v=1748004278',
    images: [
      'https://fashionous.in/cdn/shop/files/Silambam_women_s_Tshirt_mockup.jpg?v=1748004278',
    ],
    stock: 45,
    rating: 4.6,
    delFlag: false,
    isInStock: true,
    createdAt: '2026-06-04',
    skuId: 1002,
  ),
  Product(
    id: 105,
    name: 'Yoga Mat',
    description: 'Non-slip yoga mat with comfortable cushioning and grip.',
    price: 24.99,
    category: 'sports',
    categoryId: 2,
    imageUrl:
        'https://images.unsplash.com/photo-1591291621164-2c6367723315?q=80&w=2071&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    images: [
      'https://images.unsplash.com/photo-1591291621164-2c6367723315?q=80&w=2071&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    ],
    stock: 18,
    rating: 4.2,
    delFlag: false,
    isInStock: true,
    createdAt: '2026-06-04',
    skuId: 1004,
  ),
  Product(
    id: 106,
    name: 'Silambam Bag',
    description:
        'Silambam Sticks Bag | Sports Bag | 5 feet Sticks | Capacity-4 to 5 sticks (Black, Kit Bag)',
    price: 49.99,
    category: 'accessories',
    categoryId: 3,
    imageUrl: 'https://m.media-amazon.com/images/I/61OA+B6VszL._AC_UY1100_.jpg',
    images: ['https://m.media-amazon.com/images/I/61OA+B6VszL._AC_UY1100_.jpg'],
    stock: 15,
    rating: 4.6,
    delFlag: false,
    isInStock: true,
    createdAt: '2026-06-04',
    skuId: 1003,
  ),
  Product(
    id: 107,
    name: 'Wristbands',
    description:
        'High-elasticity tracking wristbands designed to analyze hand-rotation fluidity and footwork sync during complex Silambam sequences.',
    price: 34.99,
    category: 'accessories',
    categoryId: 3,
    imageUrl:
        'https://m.media-amazon.com/images/I/31M6Um4mc1L._QL92_SH45_SS200_.jpg',
    images: [
      'https://m.media-amazon.com/images/I/31M6Um4mc1L._QL92_SH45_SS200_.jpg',
    ],
    stock: 22,
    rating: 4.4,
    delFlag: false,
    isInStock: true,
    createdAt: '2026-06-04',
    skuId: 1004,
  ),
];
