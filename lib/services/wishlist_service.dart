import 'dart:async';

import 'package:wss_sports/services/api_service.dart';
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

  Map<String, dynamic>? localProduct(int productId) {
    final product = _localWishlistProducts[productId];
    return product == null ? null : Map<String, dynamic>.from(product);
  }

  bool isInLocalWishlist(int productId) {
    return _localWishlistProducts.containsKey(productId);
  }

  int _productKey(Map<String, dynamic> product) {
    return int.tryParse(product['product_id']?.toString() ?? '') ??
        ProductData.id(product);
  }

  void replaceLocalProducts(
    Iterable<Map<String, dynamic>> products, {
    bool notify = true,
  }) {
    _localWishlistProducts
      ..clear()
      ..addEntries(
        products
            .where((product) => _productKey(product) > 0)
            .map(
              (product) => MapEntry(
                _productKey(product),
                Map<String, dynamic>.from(product),
              ),
            ),
      );
    if (notify) {
      notifyWishlistChange(WishlistChangeEvent(productId: 0, isAdded: true));
    }
  }

  void clearLocalWishlist() {
    _localWishlistProducts.clear();
    notifyWishlistChange(WishlistChangeEvent(productId: 0, isAdded: false));
  }

  void addLocalProduct(Map<String, dynamic> product) {
    final productId = ProductData.id(product);
    _localWishlistProducts[productId] = Map<String, dynamic>.from(product);
    notifyWishlistChange(
      WishlistChangeEvent(productId: productId, isAdded: true),
    );
  }

  Future<bool> toggleProduct({
    required int userId,
    required Map<String, dynamic> product,
  }) async {
    final productId = ProductData.id(product);
    final ok = await ApiService.addToWishlist(
      userId: userId,
      productId: productId,
    );
    if (!ok) return false;

    if (isInLocalWishlist(productId)) {
      removeLocalProduct(productId);
    } else {
      addLocalProduct(product);
    }
    return true;
  }

  void removeLocalProduct(int productId) {
    _localWishlistProducts.remove(productId);
    notifyWishlistChange(
      WishlistChangeEvent(productId: productId, isAdded: false),
    );
  }

  Future<bool> removeProduct({
    required int userId,
    required int productId,
  }) async {
    final ok = await ApiService.removeFromWishlist(
      userId: userId,
      productId: productId,
    );
    if (ok) {
      removeLocalProduct(productId);
    }
    return ok;
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
