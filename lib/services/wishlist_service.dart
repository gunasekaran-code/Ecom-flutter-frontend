import 'dart:async';

import 'package:ecom_app/models/product_model.dart';

class WishlistService {
  static final WishlistService _instance = WishlistService._internal();

  final _wishlistChangeController =
      StreamController<WishlistChangeEvent>.broadcast();
  final Map<int, Product> _localWishlistProducts = {};

  WishlistService._internal();

  factory WishlistService() {
    return _instance;
  }

  Stream<WishlistChangeEvent> get wishlistChangeStream =>
      _wishlistChangeController.stream;

  List<Product> get localWishlistProducts =>
      _localWishlistProducts.values.toList();

  bool isInLocalWishlist(int productId) {
    return _localWishlistProducts.containsKey(productId);
  }

  void addLocalProduct(Product product) {
    _localWishlistProducts[product.id] = product;
    notifyWishlistChange(
      WishlistChangeEvent(productId: product.id, isAdded: true),
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
