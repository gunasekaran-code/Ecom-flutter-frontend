import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/services/cart_service.dart';
import 'package:wss_sports/shop/presentation/pages/checkout_page.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';
import 'package:wss_sports/utils/product_data.dart';

class CartPage extends StatefulWidget {
  final int userId;
  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List cartItems = [];
  final Set<int> selectedProductIds = <int>{};
  bool loading = true;
  String promoCode = '';
  bool promoApplied = false;
  double deliveryFee = 5.00;
  double discountPercent = 0;
  late final StreamSubscription<CartChangeEvent> _cartSubscription;

  @override
  void initState() {
    super.initState();
    loadCart();
    _cartSubscription = CartService().cartChangeStream.listen((event) {
      loadCart();
    });
  }

  Future<void> loadCart() async {
    final serverItems = await ApiService.getCart(widget.userId);
    if (!mounted) return;
    final items = serverItems.isNotEmpty
        ? serverItems.map(_normalizeCartItem).toList()
        : CartService().localCartItems;
    CartService().replaceLocalProducts(items, notify: false);
    if (!mounted) return;
    _applyCartItems(items);
  }

  Map<String, dynamic> _normalizeCartItem(dynamic item) {
    final data = item is Map<String, dynamic>
        ? Map<String, dynamic>.from(item)
        : <String, dynamic>{};
    final product = data['product'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['product'])
        : data;
    final cartItem = ProductData.toCartItem(
      product,
      quantity:
          int.tryParse(
            (data['quantity'] ?? data['qty'] ?? product['quantity'] ?? 1)
                .toString(),
          ) ??
          1,
    );
    cartItem['product_id'] =
        int.tryParse(
          (data['product_id'] ?? product['id'] ?? product['product_id'] ?? 0)
              .toString(),
        ) ??
        cartItem['product_id'];
    cartItem['cart_id'] = int.tryParse(
      (data['id'] ?? data['cart_id'] ?? data['cart_item_id'] ?? '').toString(),
    );
    return cartItem;
  }

  void _applyCartItems(List items) {
    final availableIds = items
        .map<int?>((item) => item['product_id'] as int?)
        .whereType<int>()
        .toSet();

    final nextSelection = selectedProductIds
        .where(availableIds.contains)
        .toSet();

    if (nextSelection.isEmpty) {
      for (final item in items) {
        final productId = item['product_id'] as int?;
        if (productId != null && _isItemAvailable(item)) {
          nextSelection.add(productId);
        }
      }
    }

    setState(() {
      cartItems = items;
      selectedProductIds
        ..clear()
        ..addAll(nextSelection);
      loading = false;
    });
  }

  bool _isItemAvailable(Map item) {
    final availableStock = (item['available_stock'] as num?)?.toInt() ?? 0;
    return item['is_in_stock'] == true && availableStock > 0;
  }

  double get subtotal => cartItems.fold(
    0.0,
    (sum, item) => sum + ((item['price'] as num) * (item['quantity'] as num)),
  );

  List<Map<String, dynamic>> get selectedItems => cartItems
      .where((item) => selectedProductIds.contains(item['product_id']))
      .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
      .toList();

  double get selectedSubtotal => selectedItems.fold(
    0.0,
    (sum, item) => sum + ((item['price'] as num) * (item['quantity'] as num)),
  );

  double get selectedTotal =>
      selectedSubtotal +
      deliveryFee -
      (selectedSubtotal * discountPercent / 100);

  bool get hasSelectableItems =>
      cartItems.any((item) => _isItemAvailable(item));

  bool get allSelectableItemsSelected {
    final selectableIds = cartItems
        .where((item) => _isItemAvailable(item))
        .map<int>((item) => item['product_id'] as int)
        .toList();
    return selectableIds.isNotEmpty &&
        selectableIds.every(selectedProductIds.contains);
  }

  bool get hasUnavailableSelectedItems => selectedItems.any((item) {
    final availableStock = (item['available_stock'] as num?)?.toInt() ?? 0;
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    return !_isItemAvailable(item) || quantity > availableStock;
  });

  void applyPromo() {
    if (promoCode.trim().toUpperCase() == 'ADJ3AK') {
      setState(() {
        promoApplied = true;
        discountPercent = 40;
      });
    }
  }

  void toggleProductSelection(int productId, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        selectedProductIds.add(productId);
      } else {
        selectedProductIds.remove(productId);
      }
    });
  }

  void toggleSelectAll(bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        selectedProductIds
          ..clear()
          ..addAll(
            cartItems
                .where((item) => _isItemAvailable(item))
                .map<int>((item) => item['product_id'] as int),
          );
      } else {
        selectedProductIds.clear();
      }
    });
  }

  void updateQty(int index, int delta) async {
    final currentQuantity = (cartItems[index]['quantity'] as num).toInt();
    final availableStock =
        ((cartItems[index]['available_stock'] as num?)?.toInt() ?? 0);
    final productId = cartItems[index]['product_id'];
    final cartItemId = cartItems[index]['cart_id'] as int?; // ← add this

    if (availableStock < 1) {
      showAppSnackBar(
        context,
        title: 'Alert',
        message: 'This product is out of stock',
        type: AppSnackBarType.alert,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final newQuantity = (currentQuantity + delta)
        .clamp(1, availableStock)
        .toInt();

    if (delta > 0 && currentQuantity >= availableStock) {
      showAppSnackBar(
        context,
        title: 'Alert',
        message: 'Only $availableStock item(s) available in stock',
        type: AppSnackBarType.alert,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (cartItemId == null) {
      // ← guard against missing ID
      showAppSnackBar(
        context,
        title: 'Error',
        message: 'Could not update cart: missing cart item reference',
        type: AppSnackBarType.error,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final previousQuantity = currentQuantity;
    setState(() {
      cartItems[index]['quantity'] = newQuantity;
    });

    final ok = await CartService().updateQuantity(
      userId: widget.userId,
      productId: productId,
      quantity: newQuantity,
      cartItemId: cartItemId, // ← the actual missing piece
    );
    if (!ok && mounted) {
      setState(() {
        cartItems[index]['quantity'] = previousQuantity;
      });
      showAppSnackBar(
        context,
        title: 'Error',
        message: 'Could not update cart',
        type: AppSnackBarType.error,
        duration: const Duration(seconds: 1),
      );
    }
  }

  Future<void> proceedToCheckout() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          userId: widget.userId,
          selectedItems: selectedItems,
          promoApplied: promoApplied,
          deliveryFee: deliveryFee,
          discountPercent: discountPercent,
        ),
      ),
    );

    if (result == true) {
      await loadCart();
      if (!mounted) {
        return;
      }
      CartService().notifyCartChange(
        CartChangeEvent(productId: 0, isAdded: false),
      );
    }
  }

  void removeItem(int index) async {
    final productId = cartItems[index]['product_id'];
    final productName = cartItems[index]['product_name'];
    final removedItem = Map<String, dynamic>.from(cartItems[index]);
    final removedCartItemId = removedItem['cart_id'] as int?;

    setState(() {
      cartItems.removeAt(index);
      selectedProductIds.remove(productId);
    });

    final ok = await CartService().removeProduct(
      userId: widget.userId,
      productId: productId,
      cartItemId:
          removedCartItemId,
    );

    if (!ok) {
      setState(() {
        cartItems.insert(index, removedItem);
      });
      if (mounted) {
        showAppSnackBar(
          context,
          title: 'Error',
          message: 'Could not remove item from cart',
          type: AppSnackBarType.error,
          duration: const Duration(seconds: 1),
        );
      }
      return;
    }

    if (mounted) {
      showAppSnackBar(
        context,
        title: 'Info',
        message: '$productName removed from cart',
        type: AppSnackBarType.info,
        duration: const Duration(seconds: 1),
      );
    }
  }

  @override
  void dispose() {
    _cartSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: kBrandRed,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const ListContentSkeleton(itemCount: 4)
          : cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: const Color(0xFFE4252A).withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      color: kTextDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add items to get started',
                    style: TextStyle(color: kTextMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE4252A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Continue Shopping',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFFE4252A),
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 500));
                      await loadCart();
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartItems.length + 1,
                      separatorBuilder: (_, _) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: allSelectableItemsSelected,
                                  onChanged: hasSelectableItems
                                      ? toggleSelectAll
                                      : null,
                                  activeColor: kBrandRed,
                                ),
                                const Expanded(
                                  child: Text(
                                    'Select all products',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: kTextDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${selectedItems.length} selected',
                                  style: const TextStyle(
                                    color: kTextMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final item = cartItems[index - 1];
                        final productId = item['product_id'] as int;
                        final isSelected = selectedProductIds.contains(
                          productId,
                        );
                        final isAvailable = _isItemAvailable(item);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: isAvailable
                                    ? (value) => toggleProductSelection(
                                        productId,
                                        value,
                                      )
                                    : null,
                                activeColor: kBrandRed,
                              ),
                              Builder(
                                builder: (context) {
                                  final imageUrl = item['image']?.toString();
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEEEEE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child:
                                          imageUrl != null &&
                                              imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              webHtmlElementStrategy:
                                                  WebHtmlElementStrategy.prefer,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.image,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['product_name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            final confirmed =
                                                await showRemoveCartItemDialog(
                                                  context,
                                                );
                                            if (confirmed)
                                              removeItem(index - 1);
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isAvailable
                                          ? 'Stock: ${item['available_stock']}'
                                          : 'Out of stock',
                                      style: TextStyle(
                                        color: isAvailable
                                            ? Colors.grey[600]
                                            : kBrandRed,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₹${(item['price'] as num).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              _qtyButton(
                                                Icons.remove,
                                                () => updateQty(index - 1, -1),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                child: Text(
                                                  '${item['quantity']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              _qtyButton(
                                                Icons.add,
                                                () => updateQty(index - 1, 1),
                                                highlight: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (v) => promoCode = v,
                                decoration: const InputDecoration(
                                  hintText: 'Promo code',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (promoApplied)
                              Row(
                                children: [
                                  Text(
                                    'Promocode applied',
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                        255,
                                        160,
                                        67,
                                        67,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFE4252A),
                                    size: 18,
                                  ),
                                ],
                              )
                            else
                              GestureDetector(
                                onTap: applyPromo,
                                child: const Text(
                                  'Apply',
                                  style: TextStyle(
                                    color: Color(0xFFE4252A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _summaryRow(
                        'Selected subtotal:',
                        '₹${selectedSubtotal.toStringAsFixed(2)}',
                      ),
                      _summaryRow(
                        'Delivery Fee:',
                        '₹${deliveryFee.toStringAsFixed(2)}',
                      ),
                      if (promoApplied)
                        _summaryRow('Discount:', '${discountPercent.toInt()}%'),
                      const SizedBox(height: 16),
                      if (selectedItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_box_outline_blank,
                                color: kTextMuted,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Select at least one product to continue to checkout.',
                                  style: TextStyle(
                                    color: kTextMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasUnavailableSelectedItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.error_outline,
                                color: kBrandRed,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Some selected items are out of stock or exceed available stock.',
                                  style: TextStyle(
                                    color: kBrandRed,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE4252A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed:
                              selectedItems.isEmpty ||
                                  hasUnavailableSelectedItems
                              ? null
                              : () => proceedToCheckout(),
                          child: Text(
                            selectedItems.isEmpty
                                ? 'Select products to checkout'
                                : hasUnavailableSelectedItems
                                ? 'Resolve stock issue to checkout'
                                : 'Checkout for ₹ ${selectedTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _qtyButton(
    IconData icon,
    VoidCallback onTap, {
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFE4252A).withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: highlight ? const Color(0xFFE4252A) : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
