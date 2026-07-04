import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';

// ── Models ───────────────────────────────────────────────────────────────
class OrderItemModel {
  final int id;
  final String productName;
  final double productPrice;
  final int quantity;
  final String? imageUrl;

  OrderItemModel({
    required this.id,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
    id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
    productName: j['product_name']?.toString() ?? '',
    productPrice: double.tryParse(j['product_price']?.toString() ?? '') ?? 0,
    quantity: int.tryParse(j['quantity']?.toString() ?? '') ?? 1,
    imageUrl: j['image_url']?.toString(),
  );
}

class OrderModel {
  final int id;
  final String status;
  final String paymentMethod;
  final double totalAmount;
  final int totalItems;
  final String firstName, lastName;
  final String addressLine1, addressLine2;
  final String city, state, postalCode, country;
  final String trackingNumber;
  final String currentLocation;
  final String? estimatedDelivery;
  final String createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.totalAmount,
    required this.totalItems,
    required this.firstName,
    required this.lastName,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.trackingNumber,
    required this.currentLocation,
    this.estimatedDelivery,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
    status: (j['status'] ?? j['order_status'] ?? 'pending').toString(),
    paymentMethod: (j['payment_method'] ?? 'cod').toString(),
    totalAmount: double.tryParse(j['total_amount']?.toString() ?? '') ?? 0,
    totalItems: int.tryParse(j['total_items']?.toString() ?? '') ?? 0,
    firstName: j['first_name']?.toString() ?? '',
    lastName: j['last_name']?.toString() ?? '',
    addressLine1: j['address_line_1']?.toString() ?? '',
    addressLine2: j['address_line_2']?.toString() ?? '',
    city: j['city']?.toString() ?? '',
    state: j['state']?.toString() ?? '',
    postalCode: j['postal_code']?.toString() ?? '',
    country: j['country']?.toString() ?? '',
    trackingNumber: j['tracking_number']?.toString() ?? '',
    currentLocation: j['current_location']?.toString() ?? '',
    estimatedDelivery: j['estimated_delivery']?.toString(),
    createdAt: j['created_at']?.toString() ?? '',
    items: (j['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => OrderItemModel.fromJson(e))
        .toList(),
  );

  // Treat DB's default "pending" the same as your old "placed".
  bool get canCancel =>
      status == 'pending' || status == 'placed' || status == 'confirmed';

  bool get isPending => paymentMethod == 'cod' && canCancel;

  bool get isApproved => paymentMethod != 'cod' && status != 'cancelled';
}

// ── API ──────────────────────────────────────────────────────────────────
Future<List<OrderModel>> fetchOrders(int userId) async {
  final raw = await ApiService.getOrders();
  return raw.map((order) => OrderModel.fromJson(order)).toList();
}

Future<bool> cancelOrder(int orderId, int userId) {
  return ApiService.cancelOrderRequest(orderId);
}

Future<bool> deliverOrder(int orderId, int userId) {
  return ApiService.deliverOrderRequest(orderId);
}

// ── Page ──────────────────────────────────────────────────────────────────────
class OrderPage extends StatefulWidget {
  final int userId;
  const OrderPage({super.key, required this.userId});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Future<List<OrderModel>> _future;
  late final StreamSubscription<void> _orderSubscription;

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 OrderPage initState called');
    _tab = TabController(length: 3, vsync: this);
    _future = fetchOrders(widget.userId);
    _orderSubscription = ApiService.orderEvents.stream.listen((event) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _orderSubscription.cancel();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _future = fetchOrders(widget.userId);
    });
    await _future;
  }

  List<OrderModel> _filter(List<OrderModel> all, int tab) {
    if (tab == 1) return all.where((o) => o.status == 'cancelled').toList();
    if (tab == 2) return all.where((o) => o.status == 'delivered').toList();
    return all
        .where((o) => o.status != 'cancelled' && o.status != 'delivered')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      // Using the Wishlist style AppBar structure
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          color: kCard,
          child: AppBar(
            toolbarHeight: 90,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            centerTitle: false, // Left-aligned like Wishlist
            iconTheme: const IconThemeData(color: kTextDark),
            title: Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Orders',
                    style: TextStyle(
                      color: kBrandRed,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Check the status of your orders", // Subtitle style matching Wishlist
                    style: TextStyle(
                      fontSize: 13,
                      color: kTextMuted,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const ListContentSkeleton(itemCount: 4);
          }
          if (snap.hasError) {
            debugPrint(
              '🔴 Order fetch error: ${snap.error}\n${snap.stackTrace}',
            );
            return _EmptyState(
              icon: Icons.wifi_off_rounded,
              label: 'Could not load orders',
              sub:
                  '${snap.error}', // <-- shows the real error on screen instead of hiding it
            );
          }
          final all = snap.data ?? [];

          return Column(
            children: [
              // Custom segmented tab control
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder, width: 1),
                ),
                child: TabBar(
                  controller: _tab,
                  isScrollable: false,
                  labelColor: Colors.white,
                  unselectedLabelColor: kTextMuted,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: kBrandRed,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Active'),
                    Tab(text: 'Cancelled'),
                    Tab(text: 'Delivered'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: List.generate(3, (i) {
                    final list = _filter(all, i);
                    if (list.isEmpty) {
                      return _EmptyState(
                        icon: Icons.receipt_long_outlined,
                        label: 'No orders here',
                        sub: i == 0
                            ? 'Your active orders will appear here'
                            : i == 1
                            ? 'No cancelled orders'
                            : 'No delivered orders yet',
                      );
                    }
                    return RefreshIndicator(
                      color: kBrandRed,
                      onRefresh: () async => _load(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: list.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (_, idx) => _OrderCard(
                          userId: widget.userId,
                          order: list[idx],
                          onRefresh: _load,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final int userId;
  final VoidCallback onRefresh;
  const _OrderCard({
    required this.order,
    required this.userId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          _paymentBadge(),
          Container(height: 1, color: kBorder),
          ...order.items.map((item) => _ItemRow(item: item)),
          Container(height: 1, color: kBorder),
          _addressRow(),
          Container(height: 1, color: kBorder),
          _footer(context),
        ],
      ),
    );
  }

  // ── Header
  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: kBrandRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: kBrandRed,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.id}',
                style: const TextStyle(
                  color: kTextDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _fmtDate(order.createdAt),
                style: const TextStyle(color: kTextMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        _StatusChip(status: order.status),
      ],
    ),
  );

  // ── Payment badge
  Widget _paymentBadge() {
    final isCod = order.paymentMethod == 'cod';
    final color = isCod ? const Color(0xFFE9A100) : const Color(0xFF1DB954);
    final label = isCod ? 'Payment Pending' : 'Payment Approved';
    final icon = isCod ? Icons.access_time_rounded : Icons.verified_rounded;
    final sub = isCod ? 'Cash on Delivery' : 'Paid via UPI';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    color: color.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Delivery address
  Widget _addressRow() {
    final full = '${order.firstName} ${order.lastName}'.trim();
    final line2 = order.addressLine2.isNotEmpty
        ? ', ${order.addressLine2}'
        : '';
    final addr =
        '${order.addressLine1}$line2, ${order.city}, ${order.state} - ${order.postalCode}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kBrandRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: kBrandRed,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (full.isNotEmpty)
                  Text(
                    full,
                    style: const TextStyle(
                      color: kTextDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  addr,
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer
  Widget _footer(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${order.totalItems} item${order.totalItems != 1 ? 's' : ''}',
              style: const TextStyle(color: kTextMuted, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              '₹${order.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: kTextDark,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (order.status != 'cancelled' && order.status != 'delivered')
                _PillBtn(
                  label: 'Track',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFF1565C0),
                  filled: true,
                  onTap: () => _showTracking(context),
                ),
              if (order.canCancel)
                _PillBtn(
                  label: 'Cancel',
                  icon: Icons.cancel_outlined,
                  color: kBrandRed,
                  filled: false,
                  onTap: () => _confirmCancel(context),
                ),
              _PillBtn(
                label: 'Details',
                icon: Icons.list_alt_rounded,
                color: kTextDark,
                filled: false,
                onTap: () => _showDetails(context),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _showTracking(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrackingSheet(order: order),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailsSheet(order: order),
    );
  }

  Future<void> _markDelivered(BuildContext context) async {
    final success = await deliverOrder(order.id, userId);
    if (context.mounted) {
      showAppSnackBar(
        context,
        title: success ? 'Success' : 'Error',
        message: success
            ? 'Order #${order.id} delivered'
            : 'Could not update order',
        type: success ? AppSnackBarType.success : AppSnackBarType.error,
      );
      if (success) onRefresh();
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showCancelOrderDialog(context);
    if (!confirmed || !context.mounted) return;

    final success = await cancelOrder(order.id, userId);
    if (context.mounted) {
      showCancelSnackBar(
        context,
        success: success,
        orderId: order.id.toString(),
      );
      if (success) onRefresh();
    }
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}  •  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  final OrderModel order;
  const _OrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final isCod = order.paymentMethod == 'cod';
    final fullName = '${order.firstName} ${order.lastName}'.trim();
    final addressLine2 = order.addressLine2.isNotEmpty
        ? ', ${order.addressLine2}'
        : '';
    final address =
        '${order.addressLine1}$addressLine2, ${order.city}, ${order.state} - ${order.postalCode}, ${order.country}';

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kBrandRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: kBrandRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          color: kTextDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.totalItems} item${order.totalItems != 1 ? 's' : ''}',
                        style: const TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 18),
            _DetailInfoTile(
              icon: isCod ? Icons.payments_rounded : Icons.verified_rounded,
              title: isCod ? 'Payment Pending' : 'Payment Approved',
              value: isCod ? 'Cash on Delivery' : 'Paid via UPI',
              color: isCod ? const Color(0xFFE9A100) : const Color(0xFF1DB954),
            ),
            const SizedBox(height: 12),
            _DetailInfoTile(
              icon: Icons.location_on_outlined,
              title: fullName.isEmpty ? 'Delivery Address' : fullName,
              value: address,
              color: kBrandRed,
            ),
            const SizedBox(height: 18),
            const Text(
              'Products',
              style: TextStyle(
                color: kTextDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: _ItemRow(item: item),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kBrandRed.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      color: kTextDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: kBrandRed,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _DetailInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: kTextDark,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Item Row ──────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final OrderItemModel item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Qty ${item.quantity}',
                        style: const TextStyle(
                          color: kTextDark,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '₹${item.productPrice.toStringAsFixed(0)} each',
                      style: const TextStyle(color: kTextMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${(item.productPrice * item.quantity).toStringAsFixed(0)}',
            style: const TextStyle(
              color: kTextDark,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 56,
    height: 56,
    color: kSurface,
    child: const Icon(
      Icons.image_not_supported_outlined,
      color: kTextMuted,
      size: 22,
    ),
  );
}

// ── Status Chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'placed' => (const Color(0xFF1565C0), 'Placed'),
      'confirmed' => (const Color(0xFF6A1B9A), 'Confirmed'),
      'shipped' => (const Color(0xFFF57C00), 'Shipped'),
      'out_for_delivery' => (const Color(0xFF00838F), 'On the way'),
      'delivered' => (const Color(0xFF1DB954), 'Delivered'),
      'cancelled' => (kBrandRed, 'Cancelled'),
      _ => (kTextMuted, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pill Button ───────────────────────────────────────────────────────────────
class _PillBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _PillBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: filled ? Colors.transparent : color.withOpacity(0.5),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Tracking Bottom Sheet ─────────────────────────────────────────────────────
class _TrackingSheet extends StatelessWidget {
  final OrderModel order;
  const _TrackingSheet({required this.order});

  static const _steps = [
    ('placed', 'Order Placed', Icons.receipt_outlined),
    ('confirmed', 'Order Confirmed', Icons.thumb_up_outlined),
    ('shipped', 'Shipped', Icons.local_shipping_outlined),
    ('out_for_delivery', 'Out for Delivery', Icons.delivery_dining),
    ('delivered', 'Delivered', Icons.check_circle_outline),
  ];

  int get _currentStep {
    for (int i = _steps.length - 1; i >= 0; i--) {
      if (_steps[i].$1 == order.status) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cur = _currentStep;
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kBrandRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: kBrandRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Track Order',
                  style: TextStyle(
                    color: kTextDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (order.trackingNumber.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorder),
                  ),
                  child: Text(
                    '#${order.trackingNumber}',
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Text(
              'Order #${order.id}',
              style: const TextStyle(color: kTextMuted, fontSize: 12.5),
            ),
          ),

          if (order.currentLocation.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kBrandRed.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBrandRed.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: kBrandRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT LOCATION',
                          style: TextStyle(
                            color: kBrandRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.currentLocation,
                          style: const TextStyle(
                            color: kTextDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (order.estimatedDelivery != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: kTextMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated Delivery: ${order.estimatedDelivery}',
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          ...List.generate(_steps.length, (i) {
            final done = i <= cur;
            final current = i == cur;
            final isLast = i == _steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: done ? kBrandRed : kSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: done ? kBrandRed : kBorder,
                            width: 1.5,
                          ),
                          boxShadow: current
                              ? [
                                  BoxShadow(
                                    color: kBrandRed.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _steps[i].$3,
                          size: 17,
                          color: done ? Colors.white : kTextMuted,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: i < cur ? kBrandRed : kBorder,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 9, bottom: isLast ? 0 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _steps[i].$2,
                            style: TextStyle(
                              color: done ? kTextDark : kTextMuted,
                              fontWeight: current
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (current && order.currentLocation.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                order.currentLocation,
                                style: const TextStyle(
                                  color: kBrandRed,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (current)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: kBrandRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  const _EmptyState({
    required this.icon,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: kBrandRed.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 44, color: kBrandRed),
        ),
        const SizedBox(height: 20),
        Text(
          label,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(color: kTextMuted, fontSize: 13.5)),
      ],
    ),
  );
}
