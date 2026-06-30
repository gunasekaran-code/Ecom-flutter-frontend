import 'dart:async';

import 'package:wss_sports/utils/product_data.dart';

class WishlistService {
  static final WishlistService _instance = WishlistService._internal();

  final _wishlistChangeController =
      StreamController<WishlistChangeEvent>.broadcast();
  final Map<int, Map<String, dynamic>> _localWishlistProducts = {};

  WishlistService._internal();

  factory WishlistService() {
    return _instance;
  }

  Stream<WishlistChangeEvent> get wishlistChangeStream =>
      _wishlistChangeController.stream;

  List<Map<String, dynamic>> get localWishlistProducts => _localWishlistProducts
      .values
      .map((product) => Map<String, dynamic>.from(product))
      .toList();

  bool isInLocalWishlist(int productId) {
    return _localWishlistProducts.containsKey(productId);
  }

  void addLocalProduct(Map<String, dynamic> product) {
    final productId = ProductData.id(product);
    _localWishlistProducts[productId] = Map<String, dynamic>.from(product);
    notifyWishlistChange(
      WishlistChangeEvent(productId: productId, isAdded: true),
    );
  }

  void removeLocalProduct(int productId) {
    _localWishlistProducts.remove(productId);
    notifyWishlistChange(
      WishlistChangeEvent(productId: productId, isAdded: false),
    );
  }

  void notifyWishlistChange(WishlistChangeEvent event) {
    _wishlistChangeController.add(event);
  }

  void dispose() {
    _wishlistChangeController.close();
  }
}

class WishlistChangeEvent {
  final int productId;
  final bool isAdded; // true if added, false if removed

  WishlistChangeEvent({required this.productId, required this.isAdded});
}
