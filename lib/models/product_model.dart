// class ProductVariation {
//   final int id;
//   final String type;
//   final String label;
//   final double price;
//   final int stock;
//   final bool isAvailable;
//   final String? colorHex;
//   final String? image;

//   const ProductVariation({
//     required this.id,
//     required this.type,
//     required this.label,
//     required this.price,
//     required this.stock,
//     required this.isAvailable,
//     this.colorHex,
//     this.image,
//   });
// }

// class Product {
//   final int id;
//   final String name;
//   final String description;
//   final double price;
//   final String category;
//   final int? categoryId;
//   final String? imageUrl;
//   final List<String> images;
//   final int stock;
//   final double rating;
//   final bool delFlag;
//   final bool isInStock;
//   final String createdAt;
//   final int? skuId;
//   final List<ProductVariation> variations;

//   Product({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.price,
//     required this.category,
//     this.categoryId,
//     this.imageUrl,
//     required this.images,
//     required this.stock,
//     required this.rating,
//     required this.delFlag,
//     required this.isInStock,
//     required this.createdAt,
//     this.skuId,
//     this.variations = const [],
//   });

//   factory Product.fromJson(Map<String, dynamic> json) {
//     final rawImages = json['images'] as List<dynamic>? ?? const [];

//     String categoryValue;
//     if (json['category_display_name'] != null &&
//         json['category_display_name'].toString().isNotEmpty) {
//       categoryValue = json['category_display_name'].toString();
//     } else if (json['category_name'] != null &&
//         json['category_name'].toString().isNotEmpty) {
//       categoryValue = json['category_name'].toString();
//     } else if (json['category'] != null) {
//       categoryValue = json['category'].toString();
//     } else {
//       categoryValue = 'Unknown';
//     }

//     int? categoryIdValue;
//     if (json['category'] is int) {
//       categoryIdValue = json['category'] as int;
//     } else if (json['category'] is String) {
//       categoryIdValue = int.tryParse(json['category'] as String);
//     }

//     return Product(
//       id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
//       name: json['name']?.toString() ?? 'Product',
//       description: json['description']?.toString() ?? '',
//       price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
//       category: categoryValue,
//       categoryId: categoryIdValue,
//       imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
//       images: rawImages
//           .map(
//             (e) => e is Map<String, dynamic>
//                 ? e['image_url']?.toString()
//                 : e?.toString(),
//           )
//           .whereType<String>()
//           .where((url) => url.isNotEmpty)
//           .toList(),
//       stock: int.tryParse(json['stock']?.toString() ?? '') ?? 0,
//       rating: double.tryParse(json['rating']?.toString() ?? '') ?? 0,
//       delFlag: json['del_flag'] ?? false,
//       isInStock:
//           json['is_in_stock'] ??
//           ((int.tryParse(json['stock']?.toString() ?? '') ?? 0) > 0),
//       createdAt: json['created_at']?.toString() ?? '',
//       skuId: int.tryParse(json['sku_id']?.toString() ?? ''),
//       variations: const [],
//     );
//   }

//   Map<String, dynamic> toWishlistItem() => {
//     'product_id': id,
//     'product_name': name,
//     'description': description,
//     'price': price,
//     'category': category,
//     'image': imageUrl,
//     'rating': rating,
//     'stock': stock,
//     'is_in_stock': isInStock,
//   };

//   Map<String, dynamic> toCartItem({int quantity = 1}) => {
//     'product_id': id,
//     'product_name': name,
//     'image': imageUrl,
//     'price': price,
//     'quantity': quantity,
//     'available_stock': stock,
//     'is_in_stock': isInStock,
//   };
// }

// // ─────────────────────────────────────────────
// //  STATIC DATA
// // ─────────────────────────────────────────────

// const List<Map<String, dynamic>> staticCategories = [
//   {'id': 0, 'name': 'all', 'display_name': 'All'},
//   {'id': null, 'name': 'weapons', 'display_name': 'Weapons'},
//   {'id': null, 'name': 'sports', 'display_name': 'Uniforms'},
//   {'id': null, 'name': 'accessories', 'display_name': 'Accessories'},
// ];

// final List<Product> staticProducts = [
//   // ── 101 · Surul Vaal ──────────────────────────────────────────────
//   Product(
//     id: 101,
//     name: 'Surul Vaal',
//     description: 'High-quality steel practice sword for martial arts training.',
//     price: 79.99,
//     category: 'weapons',
//     categoryId: 1,
//     imageUrl: 'https://m.media-amazon.com/images/I/61NceaQeQ5L.jpg',
//     images: ['https://m.media-amazon.com/images/I/61NceaQeQ5L.jpg'],
//     stock: 12,
//     rating: 4.5,
//     delFlag: false,
//     isInStock: true,
//     createdAt: '2026-06-01',
//     skuId: 1001,
//     variations: [
//       ProductVariation(
//         id: 1,
//         type: 'material',
//         label: 'Steel',
//         price: 79.99,
//         stock: 12,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 2,
//         type: 'material',
//         label: 'Fiberglass',
//         price: 59.99,
//         stock: 8,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 3,
//         type: 'material',
//         label: 'Aluminum',
//         price: 69.99,
//         stock: 5,
//         isAvailable: true,
//       ),
//     ],
//   ),

//   // ── 102 · Silambam Kambu ──────────────────────────────────────────
//   Product(
//     id: 102,
//     name: 'Silambam Kambu',
//     description:
//         'Premium quality roasted bamboo staff (Pirambu) for traditional '
//         'martial arts practice and tournaments.',
//     price: 24.99,
//     category: 'weapons',
//     categoryId: 1,
//     imageUrl:
//         'https://miro.medium.com/v2/resize:fit:1000/0*V4-yNet09q1-8UDN.jpg',
//     images: [
//       'https://miro.medium.com/v2/resize:fit:1000/0*V4-yNet09q1-8UDN.jpg',
//     ],
//     stock: 35,
//     rating: 4.8,
//     delFlag: false,
//     isInStock: true,
//     createdAt: '2026-06-04',
//     skuId: 1002,
//     variations: [
//       ProductVariation(
//         id: 4,
//         type: 'length',
//         label: '3ft',
//         price: 14.99,
//         stock: 20,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 5,
//         type: 'length',
//         label: '4ft',
//         price: 19.99,
//         stock: 15,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 6,
//         type: 'length',
//         label: '5ft',
//         price: 24.99,
//         stock: 35,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 7,
//         type: 'length',
//         label: '6ft',
//         price: 29.99,
//         stock: 8,
//         isAvailable: true,
//       ),
//     ],
//   ),

//   // ── 103 · Maan Kombu ──────────────────────────────────────────────
//   Product(
//     id: 103,
//     name: 'Maan Kombu',
//     description: 'Elegant wooden stand for collectibles and training swords.',
//     price: 49.99,
//     category: 'weapons',
//     categoryId: 1,
//     imageUrl:
//         'https://5.imimg.com/data5/ANDROID/Default/2022/2/UM/JY/TH/50095616/product-jpeg.jpg',
//     images: [
//       'https://5.imimg.com/data5/ANDROID/Default/2022/2/UM/JY/TH/50095616/product-jpeg.jpg',
//     ],
//     stock: 10,
//     rating: 4.7,
//     delFlag: false,
//     isInStock: true,
//     createdAt: '2026-06-05',
//     skuId: 1005,
//     variations: const [],
//   ),

//   // ── 104 · T-Shirt ─────────────────────────────────────────────────
//   // Size variations — 'S' carries its own image (shows in chip + swaps carousel)
//   Product(
//     id: 104,
//     name: 'T-shirt',
//     description:
//         'Breathable, moisture-wicking athletic jersey designed for maximum '
//         'comfort and peak performance.',
//     price: 34.99,
//     category: 'sports',
//     categoryId: 2,
//     imageUrl:
//         'https://fashionous.in/cdn/shop/files/Silambam_women_s_Tshirt_mockup.jpg?v=1748004278',
//     images: [
//       'https://fashionous.in/cdn/shop/files/Silambam_women_s_Tshirt_mockup.jpg?v=1748004278',
//     ],
//     stock: 45,
//     rating: 4.6,
//     delFlag: false,
//     isInStock: true,
//     createdAt: '2026-06-04',
//     skuId: 1002,
//     variations: [
//       // 'S' has an image → renders as an image-thumbnail chip
//       ProductVariation(
//         id: 8,
//         type: 'size',
//         label: 'S',
//         price: 29.99,
//         stock: 12,
//         isAvailable: true,
//         image:
//             'https://fashionous.in/cdn/shop/files/Silambam_women_s_Tshirt_mockup.jpg?v=1748004278',
//       ),
//       ProductVariation(
//         id: 9,
//         type: 'size',
//         label: 'M',
//         price: 34.99,
//         stock: 20,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 10,
//         type: 'size',
//         label: 'L',
//         price: 34.99,
//         stock: 18,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 11,
//         type: 'size',
//         label: 'XL',
//         price: 36.99,
//         stock: 10,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 12,
//         type: 'size',
//         label: 'XXL',
//         price: 39.99,
//         stock: 5,
//         isAvailable: true,
//       ),
//     ],
//   ),

//   // ── 105 · Yoga Mat ────────────────────────────────────────────────
//   Product(
//     id: 105,
//     name: 'Yoga Mat',
//     description: 'Non-slip yoga mat with comfortable cushioning and grip.',
//     price: 24.99,
//     category: 'sports',
//     categoryId: 2,
//     imageUrl:
//         'https://images.unsplash.com/photo-1591291621164-2c6367723315?q=80&w=2071&auto=format&fit=crop',
//     images: [
//       'https://images.unsplash.com/photo-1591291621164-2c6367723315?q=80&w=2071&auto=format&fit=crop',
//     ],
//     stock: 18,
//     rating: 4.2,
//     delFlag: false,
//     isInStock: true,
//     createdAt: '2026-06-04',
//     skuId: 1004,
//     variations: const [],
//   ),

//   // ── 106 · Silambam Bag ────────────────────────────────────────────
//   Product(
//     id: 106,
//     name: 'Silambam Bag',
//     description:
//         'Silambam Sticks Bag | Sports Bag | 5 feet Sticks | '
//         'Capacity 4–5 sticks (Black, Kit Bag)',
//     price: 49.99,
//     category: 'accessories',
//     categoryId: 3,
//     imageUrl: 'https://m.media-amazon.com/images/I/61OA+B6VszL._AC_UY1100_.jpg',
//     images: ['https://m.media-amazon.com/images/I/61OA+B6VszL._AC_UY1100_.jpg'],
//     stock: 15,
//     rating: 4.6,
//     delFlag: false,
//     isInStock: true,
//     createdAt: '2026-06-04',
//     skuId: 1003,
//     variations: [
//       ProductVariation(
//         id: 13,
//         type: 'capacity',
//         label: '3-stick',
//         price: 39.99,
//         stock: 10,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 14,
//         type: 'capacity',
//         label: '5-stick',
//         price: 49.99,
//         stock: 15,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 15,
//         type: 'capacity',
//         label: '7-stick',
//         price: 59.99,
//         stock: 6,
//         isAvailable: true,
//       ),
//     ],
//   ),

//   // ── 107 · Wristbands ──────────────────────────────────────────────
//   Product(
//     id: 107,
//     name: 'Wristbands',
//     description:
//         'High-elasticity tracking wristbands designed to analyze '
//         'hand-rotation fluidity and footwork sync during complex '
//         'Silambam sequences.',
//     price: 34.99,
//     category: 'accessories',
//     categoryId: 3,
//     imageUrl:
//         'https://m.media-amazon.com/images/I/31M6Um4mc1L._QL92_SH45_SS200_.jpg',
//     images: [
//       'https://m.media-amazon.com/images/I/31M6Um4mc1L._QL92_SH45_SS200_.jpg',
//     ],
//     stock: 22,
//     rating: 4.4,
//     delFlag: false,
//     isInStock: true,
//     createdAt: '2026-06-04',
//     skuId: 1004,
//     variations: [
//       ProductVariation(
//         id: 20,
//         type: 'color',
//         label: 'Green',
//         price: 609.00,
//         stock: 18,
//         isAvailable: true,
//         colorHex: '#7CB87A',
//         image: 'https://m.media-amazon.com/images/I/61OFGjVRWJL._SX522_.jpg',
//       ),
//     ],
//   ),

//   Product(
//     id: 108,
//     name: 'Portronics Toad 8 Wireless Mouse',
//     description:
//         'Ambidextrous optical mouse with a transparent see-through body that '
//         'reveals its precision internals. Dual-mode connectivity via '
//         'Bluetooth 5.3 and 2.4 GHz wireless receiver. Rechargeable via '
//         'USB-C with up to 30 days battery life. Adjustable DPI up to '
//         '1600 for desktop accuracy and on-the-go portability.',
//     price: 609.00,
//     category: 'accessories',
//     categoryId: 3,
//     imageUrl: 'https://m.media-amazon.com/images/I/61OFGjVRWJL._SX522_.jpg',
//     images: [
//       'https://m.media-amazon.com/images/I/61OFGjVRWJL._SX522_.jpg',
//       'https://m.media-amazon.com/images/I/71kFDf1qMHL._SX522_.jpg',
//       'https://m.media-amazon.com/images/I/71vJDXtwnCL._SX522_.jpg',
//       'https://m.media-amazon.com/images/I/61w2J5YLKXL._SX522_.jpg',
//     ],
//     stock: 48,
//     rating: 4.5,
//     delFlag: false,
//     isInStock: true,
//     createdAt: '2026-06-27',
//     skuId: 1008,
//     variations: [
//       // ── Color variations ──
//       // Each color has colorHex (for the swatch circle) + image (swaps carousel).
//       ProductVariation(
//         id: 20,
//         type: 'color',
//         label: 'Green',
//         price: 609.00,
//         stock: 18,
//         isAvailable: true,
//         colorHex: '#7CB87A',
//         image: 'https://m.media-amazon.com/images/I/61OFGjVRWJL._SX522_.jpg',
//       ),
//       ProductVariation(
//         id: 21,
//         type: 'color',
//         label: 'Black',
//         price: 609.00,
//         stock: 14,
//         isAvailable: true,
//         colorHex: '#3A3A3A',
//         image: 'https://m.media-amazon.com/images/I/61w2J5YLKXL._SX522_.jpg',
//       ),
//       ProductVariation(
//         id: 22,
//         type: 'color',
//         label: 'Purple',
//         price: 609.00,
//         stock: 10,
//         isAvailable: true,
//         colorHex: '#9B7FC7',
//         image: 'https://m.media-amazon.com/images/I/71kFDf1qMHL._SX522_.jpg',
//       ),
//       ProductVariation(
//         id: 23,
//         type: 'color',
//         label: 'Red',
//         price: 629.00,
//         stock: 6,
//         isAvailable: true,
//         colorHex: '#D94F4F',
//         image: 'https://m.media-amazon.com/images/I/71vJDXtwnCL._SX522_.jpg',
//       ),
//       ProductVariation(
//         id: 24,
//         type: 'color',
//         label: 'Dark Grey',
//         price: 609.00,
//         stock: 0,
//         isAvailable: false,
//         colorHex: '#5A5A5A',
//         // No image — out of stock anyway
//       ),

//       // ── DPI variations ──
//       ProductVariation(
//         id: 25,
//         type: 'dpi',
//         label: '800 DPI',
//         price: 589.00,
//         stock: 12,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 26,
//         type: 'dpi',
//         label: '1200 DPI',
//         price: 609.00,
//         stock: 24,
//         isAvailable: true,
//       ),
//       ProductVariation(
//         id: 27,
//         type: 'dpi',
//         label: '1600 DPI',
//         price: 649.00,
//         stock: 12,
//         isAvailable: true,
//       ),
//     ],
//   ),
// ];
