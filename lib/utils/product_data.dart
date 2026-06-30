class ProductData {
  static const String _storageBase = 'http://192.168.1.15:8000/storage/';

  static String? _firstStringValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  static int id(Map<String, dynamic> product) =>
      int.tryParse(product['id']?.toString() ?? '') ??
      int.tryParse(product['product_id']?.toString() ?? '') ??
      0;

  static String name(Map<String, dynamic> product) =>
      product['name']?.toString() ??
      product['product_name']?.toString() ??
      product['title']?.toString() ??
      'Product';

  static String description(Map<String, dynamic> product) =>
      product['description']?.toString() ??
      product['product_description']?.toString() ??
      product['details']?.toString() ??
      product['short_description']?.toString() ??
      '';

  static double price(Map<String, dynamic> product) =>
      double.tryParse(product['price']?.toString() ?? '') ??
      double.tryParse(product['selling_price']?.toString() ?? '') ??
      double.tryParse(product['sale_price']?.toString() ?? '') ??
      double.tryParse(product['mrp']?.toString() ?? '') ??
      double.tryParse(product['amount']?.toString() ?? '') ??
      0;

  static String? assetUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    if (cleanPath.startsWith('storage/')) {
      return 'http://192.168.1.15:8000/$cleanPath';
    }
    return '$_storageBase$cleanPath';
  }

  static String category(Map<String, dynamic> product) {
    final displayName = product['category_display_name']?.toString() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final categoryName = product['category_name']?.toString() ?? '';
    if (categoryName.isNotEmpty) return categoryName;

    final category = product['category'];
    if (category is Map<String, dynamic>) {
      final nestedName = _firstStringValue(category, [
        'display_name',
        'category_name',
        'name',
        'title',
      ]);
      if (nestedName != null) return nestedName;
    }

    return category?.toString() ?? 'Unknown';
  }

  static String? image(Map<String, dynamic> product) {
    final raw = _firstStringValue(product, [
      'image_url',
      'image',
      'product_image',
      'productImage',
      'image_path',
      'imagePath',
      'thumbnail',
      'thumbnail_url',
      'photo',
      'main_image',
    ]);
    return assetUrl(raw);
  }

  static List<String> images(Map<String, dynamic> product) {
    final rawImages = product['images'];
    final imageUrls = rawImages is List
        ? rawImages
              .map(
                (item) => item is Map<String, dynamic>
                    ? _firstStringValue(item, [
                        'image_url',
                        'image',
                        'product_image',
                        'image_path',
                        'url',
                        'path',
                      ])
                    : item?.toString(),
              )
              .whereType<String>()
              .map(assetUrl)
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
