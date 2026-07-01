import 'dart:async';

import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/utils/product_data.dart';

class CartService {
  static final CartService _instance = CartService._internal();

  final _cartChangeController = StreamController<CartChangeEvent>.broadcast();
  final Map<int, Map<String, dynamic>> _localCartItems = {};

  CartService._internal();

  factory CartService() {
    return _instance;
  }

  Stream<CartChangeEvent> get cartChangeStream => _cartChangeController.stream;

  List<Map<String, dynamic>> get localCartItems => _localCartItems.values
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

  int get localCartCount {
    return _localCartItems.values.fold(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );
  }

  bool isInLocalCart(int productId) {
    return _localCartItems.containsKey(productId);
  }

  int _productKey(Map<String, dynamic> item) {
    return int.tryParse(item['product_id']?.toString() ?? '') ??
        ProductData.id(item);
  }

  void replaceLocalProducts(
    Iterable<Map<String, dynamic>> items, {
    bool notify = true,
  }) {
    _localCartItems
      ..clear()
      ..addEntries(
        items
            .where((item) => _productKey(item) > 0)
            .map(
              (item) =>
                  MapEntry(_productKey(item), Map<String, dynamic>.from(item)),
            ),
      );
    if (notify) {
      notifyCartChange(CartChangeEvent(productId: 0, isAdded: true));
    }
  }

  void clearLocalCart() {
    _localCartItems.clear();
    notifyCartChange(CartChangeEvent(productId: 0, isAdded: false));
  }

  void addLocalProduct(Map<String, dynamic> product, {int quantity = 1}) {
    final productId = ProductData.id(product);
    final existingItem = _localCartItems[productId];
    if (existingItem != null) {
      final currentQuantity = (existingItem['quantity'] as num?)?.toInt() ?? 1;
      final availableStock = ProductData.stock(product);
      final maxQuantity = availableStock < 1 ? 1 : availableStock;
      existingItem['quantity'] = (currentQuantity + quantity)
          .clamp(1, maxQuantity)
          .toInt();
    } else {
      _localCartItems[productId] = ProductData.toCartItem(
        product,
        quantity: quantity,
      );
    }

    notifyCartChange(
      CartChangeEvent(
        productId: productId,
        isAdded: true,
        quantity: _localCartItems[productId]?['quantity'] ?? quantity,
      ),
    );
  }

  Future<bool> addProduct({
    required int userId,
    required Map<String, dynamic> product,
    int quantity = 1,
  }) async {
    final ok = await ApiService.addToCart(
      userId: userId,
      productId: ProductData.id(product),
      quantity: quantity,
    );
    if (ok) {
      addLocalProduct(product, quantity: quantity);
    }
    return ok;
  }

  void updateLocalQuantity(int productId, int quantity) {
    final item = _localCartItems[productId];
    if (item == null) {
      return;
    }

    item['quantity'] = quantity;
    notifyCartChange(
      CartChangeEvent(productId: productId, isAdded: true, quantity: quantity),
    );
  }

  Future<bool> updateQuantity({
    required int userId,
    required int productId,
    required int quantity,
    required int cartItemId, // ← make required, matches ApiService now
  }) async {
    final ok = await ApiService.updateCartItem(
      userId: userId,
      productId: productId,
      quantity: quantity,
      cartItemId: cartItemId, // ← was missing entirely
    );
    if (ok) {
      updateLocalQuantity(productId, quantity);
    }
    return ok;
  }

  void removeLocalProduct(int productId) {
    _localCartItems.remove(productId);
    notifyCartChange(CartChangeEvent(productId: productId, isAdded: false));
  }

  Future<bool> removeProduct({
    required int userId,
    required int productId,
    int? cartItemId,
  }) async {
    final ok = await ApiService.removeFromCart(
      userId: userId,
      productId: productId,
      cartItemId: cartItemId,
    );
    if (ok) {
      removeLocalProduct(productId);
    }
    return ok;
  }

  void removeLocalProducts(Iterable<int> productIds) {
    for (final productId in productIds) {
      _localCartItems.remove(productId);
    }
    notifyCartChange(CartChangeEvent(productId: 0, isAdded: false));
  }

  void notifyCartChange(CartChangeEvent event) {
    _cartChangeController.add(event);
  }

  void dispose() {
    _cartChangeController.close();
  }
}

class CartChangeEvent {
  final int productId;
  final bool isAdded; // true if added, false if removed
  final int quantity; // for updates

  CartChangeEvent({
    required this.productId,
    required this.isAdded,
    this.quantity = 1,
  });
}
