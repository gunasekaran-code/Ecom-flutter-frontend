import 'dart:async';

import 'package:ecom_app/models/product_model.dart';

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

  void addLocalProduct(Product product, {int quantity = 1}) {
    final existingItem = _localCartItems[product.id];
    if (existingItem != null) {
      final currentQuantity = (existingItem['quantity'] as num?)?.toInt() ?? 1;
      final availableStock = product.stock;
      existingItem['quantity'] = (currentQuantity + quantity)
          .clamp(1, availableStock)
          .toInt();
    } else {
      _localCartItems[product.id] = product.toCartItem(quantity: quantity);
    }

    notifyCartChange(
      CartChangeEvent(
        productId: product.id,
        isAdded: true,
        quantity: _localCartItems[product.id]?['quantity'] ?? quantity,
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
