class ProductData {
  static int id(Map<String, dynamic> product) =>
      int.tryParse(product['id']?.toString() ?? '') ??
      int.tryParse(product['product_id']?.toString() ?? '') ??
      0;

  static String name(Map<String, dynamic> product) =>
      product['name']?.toString() ??
      product['product_name']?.toString() ??
      'Product';

  static String description(Map<String, dynamic> product) =>
      product['description']?.toString() ?? '';

  static double price(Map<String, dynamic> product) =>
      double.tryParse(product['price']?.toString() ?? '') ?? 0;

  static String category(Map<String, dynamic> product) {
    final displayName = product['category_display_name']?.toString() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final categoryName = product['category_name']?.toString() ?? '';
    if (categoryName.isNotEmpty) return categoryName;

    return product['category']?.toString() ?? 'Unknown';
  }

  static String? image(Map<String, dynamic> product) {
    final url =
        product['image_url']?.toString() ?? product['image']?.toString();
    return url == null || url.isEmpty ? null : url;
  }

  static List<String> images(Map<String, dynamic> product) {
    final rawImages = product['images'];
    final imageUrls = rawImages is List
        ? rawImages
              .map(
                (item) => item is Map<String, dynamic>
                    ? item['image_url']?.toString() ?? item['image']?.toString()
                    : item?.toString(),
              )
              .whereType<String>()
              .where((url) => url.isNotEmpty)
              .toList()
        : <String>[];

    final primaryImage = image(product);
    if (primaryImage != null && !imageUrls.contains(primaryImage)) {
      return [primaryImage, ...imageUrls];
    }

    return imageUrls;
  }

  static int stock(Map<String, dynamic> product) =>
      int.tryParse(product['stock']?.toString() ?? '') ??
      int.tryParse(product['available_stock']?.toString() ?? '') ??
      0;

  static double rating(Map<String, dynamic> product) =>
      double.tryParse(product['rating']?.toString() ?? '') ?? 0;

  static bool isInStock(Map<String, dynamic> product) {
    final value = product['is_in_stock'];
    if (value is bool) return value;
    return stock(product) > 0;
  }

  static List<Map<String, dynamic>> variations(Map<String, dynamic> product) {
    final rawVariations = product['variations'];
    if (rawVariations is! List) return <Map<String, dynamic>>[];
    return rawVariations.whereType<Map<String, dynamic>>().toList();
  }

  static Map<String, dynamic> toWishlistItem(Map<String, dynamic> product) => {
    'product_id': id(product),
    'product_name': name(product),
    'description': description(product),
    'price': price(product),
    'category': category(product),
    'image': image(product),
    'rating': rating(product),
    'stock': stock(product),
    'is_in_stock': isInStock(product),
    'raw_product': Map<String, dynamic>.from(product),
  };

  static Map<String, dynamic> toCartItem(
    Map<String, dynamic> product, {
    int quantity = 1,
  }) => {
    'product_id': id(product),
    'product_name': name(product),
    'image': image(product),
    'price': price(product),
    'quantity': quantity,
    'available_stock': stock(product),
    'is_in_stock': isInStock(product),
    'raw_product': Map<String, dynamic>.from(product),
  };
}
