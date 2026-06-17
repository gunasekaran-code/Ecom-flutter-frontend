import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wss_sports/services/cart_service.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final double amount;
  final double itemPrice;
  final double deliveryFee;
  final double discount;
  final int itemsCount;
  final String paymentMethodLabel;
  final String? paymentId;
  final String? orderId;
  final Map<String, dynamic>? address;
  final List<Map<String, dynamic>> selectedItems;
  final VoidCallback onContinueShopping;

  const PaymentSuccessPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.itemPrice,
    required this.deliveryFee,
    required this.discount,
    required this.itemsCount,
    required this.paymentMethodLabel,
    required this.address,
    required this.selectedItems,
    required this.onContinueShopping,
    this.paymentId,
    this.orderId,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _confettiController;
  late AnimationController _cardController;
  late AnimationController _pulseController;

  late Animation<double> _checkScale;
  late Animation<double> _checkFade;
  late Animation<double> _ripple;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _pulse;

  final List<_ConfettiPiece> _confettiPieces = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Generate confetti pieces
    for (int i = 0; i < 60; i++) {
      _confettiPieces.add(
        _ConfettiPiece(
          x: _random.nextDouble(),
          y: -_random.nextDouble() * 0.5,
          color: _confettiColors[_random.nextInt(_confettiColors.length)],
          size: 6 + _random.nextDouble() * 10,
          rotation: _random.nextDouble() * math.pi * 2,
          speedX: (_random.nextDouble() - 0.5) * 0.004,
          speedY: 0.003 + _random.nextDouble() * 0.005,
          shape: _random.nextInt(3),
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
        ),
      );
    }

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _checkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _ripple = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _cardSlide = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _cardFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeIn));

    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sequence the animations
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confettiController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _cardController.forward();
    });
  }

  static const List<Color> _confettiColors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFF922B),
    Color(0xFFCC5DE8),
    Color(0xFF20C997),
    Color(0xFFFF6B9D),
  ];

  @override
  void dispose() {
    _heroController.dispose();
    _confettiController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goBackHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FFF4),
        body: Stack(
          children: [
            // Animated confetti background
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    pieces: _confettiPieces,
                    progress: _confettiController.value,
                  ),
                  size: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height,
                  ),
                );
              },
            ),

            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            _buildHeroSection(),
                            const SizedBox(height: 28),
                            AnimatedBuilder(
                              animation: _cardController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _cardSlide.value),
                                  child: Opacity(
                                    opacity: _cardFade.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  _buildReceiptCard(),
                                  const SizedBox(height: 16),
                                  if (_resolvedAddressText.isNotEmpty)
                                    _buildDeliveryCard(),
                                  if (widget.selectedItems.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildItemsCard(),
                                  ],
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottomBar(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero Section ─────────────────────────────────────────────────────────

  void _goBackHome() {
    CartService().notifyCartChange(
      CartChangeEvent(productId: 0, isAdded: false),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _heroController,
      builder: (context, child) {
        return Column(
          children: [
            // Ripple + Check icon
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple
                  Opacity(
                    opacity: (1.0 - _ripple.value).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.6 + _ripple.value * 0.8,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF22C55E).withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),
                  // Mid ripple
                  Opacity(
                    opacity: (1.0 - _ripple.value * 0.8).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.7 + _ripple.value * 0.5,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF22C55E).withOpacity(0.15),
                        ),
                      ),
                    ),
                  ),
                  // Main circle with 3D shadow
                  Opacity(
                    opacity: _checkFade.value,
                    child: Transform.scale(
                      scale: _checkScale.value,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) =>
                            Transform.scale(scale: _pulse.value, child: child),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF16A34A),
                                Color(0xFF22C55E),
                                Color(0xFF4ADE80),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFF22C55E).withOpacity(0.2),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.done_all_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: _checkFade.value,
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.subtitle} ₹${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Receipt Card (3D flip-style) ─────────────────────────────────────────

  Widget _buildReceiptCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Green header strip
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Payment Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Paid',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dashed divider with notches
          _DashedDivider(),
          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                _detailRow(
                  'Item Price',
                  '₹${widget.itemPrice.toStringAsFixed(2)}',
                ),
                _detailRow(
                  'Shipping Cost',
                  '₹${widget.deliveryFee.toStringAsFixed(2)}',
                ),
                _detailRow('VAT 0%', '- ₹0'),
                if (widget.discount > 0)
                  _detailRow(
                    'Voucher',
                    '- ₹${widget.discount.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF22C55E),
                  ),
                if (widget.paymentId != null) ...[
                  const SizedBox(height: 4),
                  _detailRow('Payment ID', widget.paymentId!, isSmall: true),
                ],
                if (widget.orderId != null)
                  _detailRow('Order ID', '#${widget.orderId}', isSmall: true),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        kBorder,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        color: kTextDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '₹${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF16A34A),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.paymentMethodLabel,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.itemsCount} item${widget.itemsCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: kTextMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isSmall = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: kTextMuted, fontSize: isSmall ? 12 : 14),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? kTextDark,
                fontSize: isSmall ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Delivery Card ────────────────────────────────────────────────────────

  Widget _buildDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivering To',
                  style: TextStyle(
                    color: kTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _resolvedAddressText,
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 12.5,
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

  // ─── Items Card ───────────────────────────────────────────────────────────

  Widget _buildItemsCard() {
    final previewItems = widget.selectedItems.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Items',
            style: TextStyle(
              color: kTextDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...previewItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 52,
                      height: 52,
                      color: const Color(0xFFF4F5F7),
                      child: item['image'] != null
                          ? Image.network(
                              item['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                color: kTextMuted,
                              ),
                            )
                          : const Icon(
                              Icons.image_outlined,
                              color: kTextMuted,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['product_name']?.toString() ?? 'Product',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kTextDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Qty ${item['quantity']}',
                          style: const TextStyle(
                            color: kTextMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${(((item['price'] as num?) ?? 0) * ((item['quantity'] as num?) ?? 0)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.selectedItems.length > 3)
            Text(
              '+${widget.selectedItems.length - 3} more item(s)',
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _goBackHome,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 20),
              SizedBox(width: 8),
              Text(
                'Back Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _resolvedAddressText {
    final address = widget.address;
    if (address == null) return '';
    final List<String> lines = [];
    final fullName = [
      address['first_name']?.toString() ?? '',
      address['last_name']?.toString() ?? '',
    ].where((p) => p.trim().isNotEmpty).join(' ');
    if (fullName.isNotEmpty) lines.add(fullName);
    for (final key in const ['address_line_1', 'address_line_2']) {
      final v = address[key]?.toString() ?? '';
      if (v.trim().isNotEmpty) lines.add(v.trim());
    }
    final cityStatePostal = [
      address['city']?.toString() ?? '',
      address['state']?.toString() ?? '',
      address['postal_code']?.toString() ?? '',
    ].where((p) => p.trim().isNotEmpty).join(', ');
    if (cityStatePostal.isNotEmpty) lines.add(cityStatePostal);
    final country = address['country']?.toString() ?? '';
    if (country.trim().isNotEmpty) lines.add(country.trim());
    return lines.join('\n');
  }
}

// ─── Dashed Divider with notches ─────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          // Left notch
          Container(
            width: 20,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF0FFF4),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
            ),
          ),
          // Dashed line
          Expanded(child: CustomPaint(painter: _DashedLinePainter())),
          // Right notch
          Container(
            width: 20,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF0FFF4),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEAEAEA)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashWidth = 8.0;
    const dashSpace = 5.0;
    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => false;
}

// ─── Confetti ─────────────────────────────────────────────────────────────────

class _ConfettiPiece {
  double x;
  double y;
  final Color color;
  final double size;
  double rotation;
  final double speedX;
  final double speedY;
  final int shape; // 0 = rect, 1 = circle, 2 = triangle
  final double rotationSpeed;

  _ConfettiPiece({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotation,
    required this.speedX,
    required this.speedY,
    required this.shape,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final x = (piece.x + piece.speedX * progress * 1000) * size.width;
      final y = (piece.y + piece.speedY * progress * 1000) * size.height;

      if (y > size.height + 20) continue;

      final paint = Paint()
        ..color = piece.color.withOpacity(
          (1.0 - progress * 0.4).clamp(0.0, 1.0),
        )
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.rotation + piece.rotationSpeed * progress * 100);

      switch (piece.shape) {
        case 0:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: piece.size,
              height: piece.size * 0.5,
            ),
            paint,
          );
          break;
        case 1:
          canvas.drawCircle(Offset.zero, piece.size * 0.4, paint);
          break;
        case 2:
          final path = Path()
            ..moveTo(0, -piece.size * 0.5)
            ..lineTo(piece.size * 0.5, piece.size * 0.5)
            ..lineTo(-piece.size * 0.5, piece.size * 0.5)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
