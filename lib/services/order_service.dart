import 'dart:async';

class OrderService {
  static final OrderService _instance = OrderService._internal();

  final _orderChangeController = StreamController<void>.broadcast();
  final List<Map<String, dynamic>> _orders = [];
  int _nextOrderId = 1001;

  OrderService._internal();

  factory OrderService() => _instance;

  Stream<void> get orderChangeStream => _orderChangeController.stream;

  List<Map<String, dynamic>> ordersForUser(int userId) {
    return _orders
        .where((order) => order['user_id'] == userId)
        .map((order) => Map<String, dynamic>.from(order))
        .toList()
      ..sort(
        (a, b) =>
            b['created_at'].toString().compareTo(a['created_at'].toString()),
      );
  }

  Map<String, dynamic> createOrder({
    required int userId,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required double totalAmount,
    required int totalItems,
    Map<String, dynamic>? address,
  }) {
    final now = DateTime.now();
    final order = <String, dynamic>{
      'id': _nextOrderId++,
      'user_id': userId,
      'status': 'placed',
      'payment_method': paymentMethod,
      'total_amount': totalAmount,
      'total_items': totalItems,
      'first_name': address?['first_name'] ?? '',
      'last_name': address?['last_name'] ?? '',
      'address_line_1': address?['address_line_1'] ?? '',
      'address_line_2': address?['address_line_2'] ?? '',
      'city': address?['city'] ?? '',
      'state': address?['state'] ?? '',
      'postal_code': address?['postal_code'] ?? '',
      'country': address?['country'] ?? '',
      'tracking_number': 'LOCAL-${now.millisecondsSinceEpoch}',
      'current_location': 'Order placed',
      'estimated_delivery': now.add(const Duration(days: 5)).toIso8601String(),
      'created_at': now.toIso8601String(),
      'items': items.map(_toOrderItem).toList(),
    };

    _orders.add(order);
    _notifyOrderChanged();
    return Map<String, dynamic>.from(order);
  }

  bool cancelOrder(int orderId, int userId) {
    return updateOrderStatus(
      orderId: orderId,
      userId: userId,
      status: 'cancelled',
      currentLocation: 'Order cancelled',
    );
  }

  bool deliverOrder(int orderId, int userId) {
    return updateOrderStatus(
      orderId: orderId,
      userId: userId,
      status: 'delivered',
      currentLocation: 'Delivered',
    );
  }

  bool updateOrderStatus({
    required int orderId,
    required int userId,
    required String status,
    String? currentLocation,
  }) {
    final index = _orders.indexWhere(
      (order) => order['id'] == orderId && order['user_id'] == userId,
    );
    if (index == -1) {
      return false;
    }
    _orders[index] = {
      ..._orders[index],
      'status': status,
      if (currentLocation != null) 'current_location': currentLocation,
    };
    _notifyOrderChanged();
    return true;
  }

  void _notifyOrderChanged() {
    _orderChangeController.add(null);
  }

  Map<String, dynamic> _toOrderItem(Map<String, dynamic> item) {
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    return {
      'id': item['product_id'] ?? item['id'] ?? 0,
      'product_name': item['product_name'] ?? item['name'] ?? '',
      'product_price': price,
      'quantity': quantity,
      'image_url': item['image'] ?? item['image_url'],
    };
  }
}
