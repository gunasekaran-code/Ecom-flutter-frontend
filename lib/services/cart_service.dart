import 'dart:async';

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

  void removeLocalProduct(int productId) {
    _localCartItems.remove(productId);
    notifyCartChange(CartChangeEvent(productId: productId, isAdded: false));
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
