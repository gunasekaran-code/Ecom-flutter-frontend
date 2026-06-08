// import 'dart:math' as math;
// import 'package:flutter/material.dart';

// const Color _kTextDark = Color(0xFF1A1A1A);
// const Color _kTextMuted = Color(0xFF6B6B6B);
// const Color _kBorder = Color(0xFFEAEAEA);
// const Color _kBrandRed = Color(0xFFE4252A);

// class PaymentFailedPage extends StatefulWidget {
//   final String title;
//   final String message;
//   final double amount;
//   final int itemsCount;
//   final String paymentMethodLabel;
//   final String? paymentId;
//   final Map<String, dynamic>? address;
//   final List<Map<String, dynamic>> selectedItems;
//   final bool isCancelled;
//   final VoidCallback onTryAgain;
//   final VoidCallback onBack;

//   const PaymentFailedPage({
//     super.key,
//     required this.title,
//     required this.message,
//     required this.amount,
//     required this.itemsCount,
//     required this.paymentMethodLabel,
//     required this.address,
//     required this.selectedItems,
//     required this.isCancelled,
//     required this.onTryAgain,
//     required this.onBack,
//     this.paymentId,
//   });

//   @override
//   State<PaymentFailedPage> createState() => _PaymentFailedPageState();
// }

// class _PaymentFailedPageState extends State<PaymentFailedPage>
//     with TickerProviderStateMixin {
//   late AnimationController _heroController;
//   late AnimationController _shakeController;
//   late AnimationController _cardController;
//   late AnimationController _pulseController;
//   late AnimationController _particleController;

//   late Animation<double> _iconScale;
//   late Animation<double> _iconFade;
//   late Animation<double> _shake;
//   late Animation<double> _cardSlide;
//   late Animation<double> _cardFade;
//   late Animation<double> _pulse;
//   late Animation<double> _particle;

//   @override
//   void initState() {
//     super.initState();

//     _heroController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );

//     _shakeController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );

//     _cardController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//     );

//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400),
//     )..repeat(reverse: true);

//     _particleController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 2500),
//     )..repeat();

//     _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _heroController,
//         curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
//       ),
//     );

//     _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _heroController,
//         curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
//       ),
//     );

//     _shake = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _shakeController,
//         curve: Curves.elasticOut,
//       ),
//     );

//     _cardSlide = Tween<double>(begin: 80.0, end: 0.0).animate(
//       CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
//     );

//     _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _cardController, curve: Curves.easeIn),
//     );

//     _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );

//     _particle = Tween<double>(begin: 0.0, end: 1.0).animate(_particleController);

//     // Sequence
//     _heroController.forward();
//     Future.delayed(const Duration(milliseconds: 500), () {
//       if (mounted) _shakeController.forward();
//     });
//     Future.delayed(const Duration(milliseconds: 600), () {
//       if (mounted) _cardController.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _heroController.dispose();
//     _shakeController.dispose();
//     _cardController.dispose();
//     _pulseController.dispose();
//     _particleController.dispose();
//     super.dispose();
//   }

//   Color get _accentColor =>
//       widget.isCancelled ? const Color(0xFFF59E0B) : _kBrandRed;

//   Color get _bgColor =>
//       widget.isCancelled ? const Color(0xFFFFFBEB) : const Color(0xFFFFF5F5);

//   IconData get _icon =>
//       widget.isCancelled ? Icons.cancel_outlined : Icons.close_rounded;

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         widget.onBack();
//         return false;
//       },
//       child: Scaffold(
//         backgroundColor: _bgColor,
//         body: Stack(
//           children: [
//             // Floating particles background
//             AnimatedBuilder(
//               animation: _particleController,
//               builder: (context, child) {
//                 return CustomPaint(
//                   painter: _FloatingParticlesPainter(
//                     progress: _particle.value,
//                     color: _accentColor,
//                   ),
//                   size: Size(
//                     MediaQuery.of(context).size.width,
//                     MediaQuery.of(context).size.height,
//                   ),
//                 );
//               },
//             ),

//             SafeArea(
//               child: Column(
//                 children: [
//                   Expanded(
//                     child: SingleChildScrollView(
//                       physics: const BouncingScrollPhysics(),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 20),
//                         child: Column(
//                           children: [
//                             const SizedBox(height: 40),
//                             _buildHeroSection(),
//                             const SizedBox(height: 28),
//                             AnimatedBuilder(
//                               animation: _cardController,
//                               builder: (context, child) {
//                                 return Transform.translate(
//                                   offset: Offset(0, _cardSlide.value),
//                                   child: Opacity(
//                                     opacity: _cardFade.value,
//                                     child: child,
//                                   ),
//                                 );
//                               },
//                               child: Column(
//                                 children: [
//                                   _buildErrorCard(),
//                                   const SizedBox(height: 16),
//                                   _buildOrderSummaryCard(),
//                                   if (widget.selectedItems.isNotEmpty) ...[
//                                     const SizedBox(height: 16),
//                                     _buildItemsCard(),
//                                   ],
//                                   const SizedBox(height: 100),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   _buildBottomBar(context),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ─── Hero Section ─────────────────────────────────────────────────────────

//   Widget _buildHeroSection() {
//     return AnimatedBuilder(
//       animation: Listenable.merge([_heroController, _shakeController]),
//       builder: (context, child) {
//         // Shake animation using sine wave
//         final shakeOffset = _shakeController.isCompleted
//             ? 0.0
//             : math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value);

//         return Column(
//           children: [
//             Transform.translate(
//               offset: Offset(shakeOffset, 0),
//               child: SizedBox(
//                 width: 160,
//                 height: 160,
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     // Outer glow rings
//                     for (int i = 0; i < 3; i++)
//                       AnimatedBuilder(
//                         animation: _pulseController,
//                         builder: (context, child) {
//                           final scale = 1.0 + i * 0.15 +
//                               (_pulse.value - 1.0) * (i + 1) * 0.3;
//                           final opacity = (0.12 - i * 0.04) *
//                               (_pulse.value - 0.5) * 2;
//                           return Transform.scale(
//                             scale: scale,
//                             child: Opacity(
//                               opacity: opacity.clamp(0.0, 0.15),
//                               child: Container(
//                                 width: 100,
//                                 height: 100,
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: _accentColor,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     // Main circle
//                     Opacity(
//                       opacity: _iconFade.value,
//                       child: Transform.scale(
//                         scale: _iconScale.value,
//                         child: AnimatedBuilder(
//                           animation: _pulseController,
//                           builder: (context, child) => Transform.scale(
//                             scale: _pulse.value,
//                             child: child,
//                           ),
//                           child: Container(
//                             width: 100,
//                             height: 100,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               gradient: LinearGradient(
//                                 colors: widget.isCancelled
//                                     ? const [
//                                         Color(0xFFD97706),
//                                         Color(0xFFF59E0B),
//                                         Color(0xFFFBBF24),
//                                       ]
//                                     : const [
//                                         Color(0xFFB91C1C),
//                                         Color(0xFFDC2626),
//                                         Color(0xFFEF4444),
//                                       ],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               ),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: _accentColor.withOpacity(0.5),
//                                   blurRadius: 30,
//                                   spreadRadius: 4,
//                                   offset: const Offset(0, 8),
//                                 ),
//                                 BoxShadow(
//                                   color: _accentColor.withOpacity(0.2),
//                                   blurRadius: 60,
//                                   spreadRadius: 10,
//                                 ),
//                               ],
//                             ),
//                             child: Icon(
//                               _icon,
//                               color: Colors.white,
//                               size: 52,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Opacity(
//               opacity: _iconFade.value,
//               child: Column(
//                 children: [
//                   Text(
//                     widget.title,
//                     style: TextStyle(
//                       color: _kTextDark,
//                       fontSize: 28,
//                       fontWeight: FontWeight.w900,
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 20),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 10),
//                     decoration: BoxDecoration(
//                       color: _accentColor.withOpacity(0.08),
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(
//                         color: _accentColor.withOpacity(0.2),
//                       ),
//                     ),
//                     child: Text(
//                       widget.message,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: _accentColor.withOpacity(0.85),
//                         fontSize: 13.5,
//                         height: 1.5,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ─── Error Card ───────────────────────────────────────────────────────────

//   Widget _buildErrorCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: _accentColor.withOpacity(0.12),
//             blurRadius: 30,
//             offset: const Offset(0, 8),
//           ),
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 20,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Colored header
//           Container(
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: widget.isCancelled
//                     ? const [Color(0xFFD97706), Color(0xFFF59E0B)]
//                     : const [Color(0xFFB91C1C), Color(0xFFEF4444)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   widget.isCancelled
//                       ? Icons.info_outline_rounded
//                       : Icons.error_outline_rounded,
//                   color: Colors.white,
//                   size: 22,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   widget.isCancelled
//                       ? 'Payment Cancelled'
//                       : 'Payment Failed',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const Spacer(),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     widget.isCancelled ? 'Cancelled' : 'Failed',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Dashed divider
//           _DashedDivider(bgColor: _bgColor),
//           // Details
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
//             child: Column(
//               children: [
//                 _detailRow(
//                   icon: Icons.currency_rupee_rounded,
//                   label: 'Amount',
//                   value: '₹${widget.amount.toStringAsFixed(2)}',
//                 ),
//                 const SizedBox(height: 10),
//                 _detailRow(
//                   icon: Icons.shopping_bag_outlined,
//                   label: 'Items',
//                   value:
//                       '${widget.itemsCount} item${widget.itemsCount == 1 ? '' : 's'}',
//                 ),
//                 const SizedBox(height: 10),
//                 _detailRow(
//                   icon: Icons.account_balance_wallet_outlined,
//                   label: 'Payment Mode',
//                   value: widget.paymentMethodLabel,
//                 ),
//                 if (widget.paymentId != null &&
//                     widget.paymentId!.isNotEmpty) ...[
//                   const SizedBox(height: 10),
//                   _detailRow(
//                     icon: Icons.verified_outlined,
//                     label: 'Payment ID',
//                     value: widget.paymentId!,
//                   ),
//                 ],
//                 const SizedBox(height: 14),
//                 // Status badge
//                 Container(
//                   padding: const EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: _accentColor.withOpacity(0.06),
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(
//                       color: _accentColor.withOpacity(0.15),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         widget.isCancelled
//                             ? Icons.replay_rounded
//                             : Icons.support_agent_rounded,
//                         color: _accentColor,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: Text(
//                           widget.isCancelled
//                               ? 'No amount was deducted from your account'
//                               : 'If your amount was deducted, it will be refunded in 5-7 business days',
//                           style: TextStyle(
//                             color: _accentColor,
//                             fontSize: 12.5,
//                             fontWeight: FontWeight.w600,
//                             height: 1.4,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _detailRow({
//     required IconData icon,
//     required String label,
//     required String value,
//   }) {
//     return Row(
//       children: [
//         Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             color: _accentColor.withOpacity(0.08),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(icon, color: _accentColor, size: 18),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Text(
//             label,
//             style: const TextStyle(color: _kTextMuted, fontSize: 13.5),
//           ),
//         ),
//         Flexible(
//           child: Text(
//             value,
//             textAlign: TextAlign.right,
//             style: const TextStyle(
//               color: _kTextDark,
//               fontSize: 14,
//               fontWeight: FontWeight.w700,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }

//   // ─── Order Summary Card ───────────────────────────────────────────────────

//   Widget _buildOrderSummaryCard() {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(Icons.receipt_outlined,
//                     color: Colors.grey, size: 18),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Order Summary',
//                 style: TextStyle(
//                   color: _kTextDark,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           _summaryRow('Amount Attempted',
//               '₹${widget.amount.toStringAsFixed(2)}'),
//           _summaryRow('Payment Mode', widget.paymentMethodLabel),
//           _summaryRow(
//               'Items', '${widget.itemsCount} item(s)'),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: Colors.red.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Status',
//                   style: TextStyle(
//                     color: _kTextMuted,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: _accentColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: _accentColor.withOpacity(0.3),
//                     ),
//                   ),
//                   child: Text(
//                     widget.isCancelled ? 'Cancelled' : 'Failed',
//                     style: TextStyle(
//                       color: _accentColor,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _summaryRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: const TextStyle(color: _kTextMuted, fontSize: 13)),
//           Text(value,
//               style: const TextStyle(
//                   color: _kTextDark,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600)),
//         ],
//       ),
//     );
//   }

//   // ─── Items Card ───────────────────────────────────────────────────────────

//   Widget _buildItemsCard() {
//     final previewItems = widget.selectedItems.take(3).toList();
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Order Items',
//             style: TextStyle(
//               color: _kTextDark,
//               fontSize: 16,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(height: 12),
//           ...previewItems.map(
//             (item) => Padding(
//               padding: const EdgeInsets.only(bottom: 10),
//               child: Opacity(
//                 opacity: 0.6, // Dimmed since payment failed
//                 child: Row(
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: Container(
//                         width: 52,
//                         height: 52,
//                         color: const Color(0xFFF4F5F7),
//                         child: item['image'] != null
//                             ? Image.network(item['image'],
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (_, __, ___) => const Icon(
//                                       Icons.image_outlined,
//                                       color: _kTextMuted,
//                                     ))
//                             : const Icon(Icons.image_outlined,
//                                 color: _kTextMuted),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             item['product_name']?.toString() ?? 'Product',
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               color: _kTextDark,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                           Text('Qty ${item['quantity']}',
//                               style: const TextStyle(
//                                   color: _kTextMuted, fontSize: 12)),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       '₹${(((item['price'] as num?) ?? 0) * ((item['quantity'] as num?) ?? 0)).toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         color: _kTextDark,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           if (widget.selectedItems.length > 3)
//             Text(
//               '+${widget.selectedItems.length - 3} more item(s)',
//               style: TextStyle(
//                 color: _accentColor,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ─── Bottom Bar ───────────────────────────────────────────────────────────

//   Widget _buildBottomBar(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 20,
//             offset: const Offset(0, -4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           SizedBox(
//             width: double.infinity,
//             height: 56,
//             child: ElevatedButton(
//               onPressed: widget.onTryAgain,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _accentColor,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(18),
//                 ),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     widget.isCancelled
//                         ? Icons.replay_rounded
//                         : Icons.refresh_rounded,
//                     size: 20,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     widget.isCancelled ? 'Try Again' : 'Retry Payment',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w800,
//                       letterSpacing: 0.3,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           SizedBox(
//             width: double.infinity,
//             height: 52,
//             child: OutlinedButton(
//               onPressed: widget.onBack,
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: _kTextDark,
//                 side: const BorderSide(color: _kBorder),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(18),
//                 ),
//               ),
//               child: const Text(
//                 'Back to Cart',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Dashed Divider ───────────────────────────────────────────────────────────

// class _DashedDivider extends StatelessWidget {
//   final Color bgColor;
//   const _DashedDivider({required this.bgColor});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 24,
//       child: Row(
//         children: [
//           Container(
//             width: 20,
//             height: 24,
//             decoration: BoxDecoration(
//               color: bgColor,
//               borderRadius:
//                   const BorderRadius.horizontal(right: Radius.circular(12)),
//             ),
//           ),
//           Expanded(child: CustomPaint(painter: _DashedLinePainter())),
//           Container(
//             width: 20,
//             height: 24,
//             decoration: BoxDecoration(
//               color: bgColor,
//               borderRadius:
//                   const BorderRadius.horizontal(left: Radius.circular(12)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DashedLinePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFFEAEAEA)
//       ..strokeWidth = 1.5
//       ..style = PaintingStyle.stroke;
//     const dashWidth = 8.0;
//     const dashSpace = 5.0;
//     double startX = 0;
//     final y = size.height / 2;
//     while (startX < size.width) {
//       canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
//       startX += dashWidth + dashSpace;
//     }
//   }

//   @override
//   bool shouldRepaint(_DashedLinePainter oldDelegate) => false;
// }

// // ─── Floating Particles Painter ───────────────────────────────────────────────

// class _FloatingParticlesPainter extends CustomPainter {
//   final double progress;
//   final Color color;

//   _FloatingParticlesPainter({required this.progress, required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..style = PaintingStyle.fill;
//     final positions = [
//       const Offset(0.1, 0.2),
//       const Offset(0.85, 0.15),
//       const Offset(0.2, 0.7),
//       const Offset(0.9, 0.6),
//       const Offset(0.5, 0.1),
//       const Offset(0.7, 0.85),
//       const Offset(0.05, 0.5),
//     ];

//     for (int i = 0; i < positions.length; i++) {
//       final phase = (progress + i * 0.14) % 1.0;
//       final floatY = math.sin(phase * math.pi * 2) * 15;
//       final opacity = (math.sin(phase * math.pi * 2) * 0.5 + 0.5) * 0.07;

//       paint.color = color.withOpacity(opacity);

//       final cx = positions[i].dx * size.width;
//       final cy = positions[i].dy * size.height + floatY;
//       final radius = 20.0 + i * 8.0;

//       canvas.drawCircle(Offset(cx, cy), radius, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(_FloatingParticlesPainter oldDelegate) =>
//       oldDelegate.progress != progress;
// }

import 'dart:math' as math;
import 'package:flutter/material.dart';

const Color _kTextDark = Color(0xFF1A1A1A);
const Color _kTextMuted = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFEAEAEA);
const Color _kBrandRed = Color(0xFFE4252A);

class PaymentFailedPage extends StatefulWidget {
  final String title;
  final String message;
  final double amount;
  final int itemsCount;
  final String paymentMethodLabel;
  final String? paymentId;
  final Map<String, dynamic>? address;
  final List<Map<String, dynamic>> selectedItems;
  final bool isCancelled;
  final VoidCallback onTryAgain;
  final VoidCallback onBack;

  const PaymentFailedPage({
    super.key,
    required this.title,
    required this.message,
    required this.amount,
    required this.itemsCount,
    required this.paymentMethodLabel,
    required this.address,
    required this.selectedItems,
    required this.isCancelled,
    required this.onTryAgain,
    required this.onBack,
    this.paymentId,
  });

  @override
  State<PaymentFailedPage> createState() => _PaymentFailedPageState();
}

class _PaymentFailedPageState extends State<PaymentFailedPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _shakeController;
  late AnimationController _cardController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _iconScale;
  late Animation<double> _iconFade;
  late Animation<double> _shake;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _pulse;
  late Animation<double> _particle;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _shake = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _cardSlide = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _cardFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeIn));

    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _particle = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);

    // Sequence
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _shakeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _shakeController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Color get _accentColor =>
      widget.isCancelled ? const Color(0xFFF59E0B) : _kBrandRed;

  Color get _bgColor =>
      widget.isCancelled ? const Color(0xFFFFFBEB) : const Color(0xFFFFF5F5);

  IconData get _icon =>
      widget.isCancelled ? Icons.cancel_outlined : Icons.close_rounded;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Stack(
          children: [
            // Floating particles background
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FloatingParticlesPainter(
                    progress: _particle.value,
                    color: _accentColor,
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
                                  _buildErrorCard(),
                                  const SizedBox(height: 16),
                                  _buildOrderSummaryCard(),
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

  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_heroController, _shakeController]),
      builder: (context, child) {
        // Shake animation using sine wave
        final shakeOffset = _shakeController.isCompleted
            ? 0.0
            : math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value);

        return Column(
          children: [
            Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow rings
                    for (int i = 0; i < 3; i++)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale =
                              1.0 +
                              i * 0.15 +
                              (_pulse.value - 1.0) * (i + 1) * 0.3;
                          final opacity =
                              (0.12 - i * 0.04) * (_pulse.value - 0.5) * 2;
                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity.clamp(0.0, 0.15),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _accentColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    // Main circle
                    Opacity(
                      opacity: _iconFade.value,
                      child: Transform.scale(
                        scale: _iconScale.value,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) => Transform.scale(
                            scale: _pulse.value,
                            child: child,
                          ),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: widget.isCancelled
                                    ? const [
                                        Color(0xFFD97706),
                                        Color(0xFFF59E0B),
                                        Color(0xFFFBBF24),
                                      ]
                                    : const [
                                        Color(0xFFB91C1C),
                                        Color(0xFFDC2626),
                                        Color(0xFFEF4444),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentColor.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: _accentColor.withOpacity(0.2),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(_icon, color: Colors.white, size: 52),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: _iconFade.value,
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: _kTextDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _accentColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _accentColor.withOpacity(0.85),
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
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

  // ─── Error Card ───────────────────────────────────────────────────────────

  Widget _buildErrorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Colored header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isCancelled
                    ? const [Color(0xFFD97706), Color(0xFFF59E0B)]
                    : const [Color(0xFFB91C1C), Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isCancelled
                      ? Icons.info_outline_rounded
                      : Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isCancelled ? 'Payment Cancelled' : 'Payment Failed',
                  style: const TextStyle(
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
                  child: Text(
                    widget.isCancelled ? 'Cancelled' : 'Failed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Dashed divider
          _DashedDivider(bgColor: _bgColor),
          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                _detailRow(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Amount',
                  value: '₹${widget.amount.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 10),
                _detailRow(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Items',
                  value:
                      '${widget.itemsCount} item${widget.itemsCount == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 10),
                _detailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payment Mode',
                  value: widget.paymentMethodLabel,
                ),
                if (widget.paymentId != null &&
                    widget.paymentId!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailRow(
                    icon: Icons.verified_outlined,
                    label: 'Payment ID',
                    value: widget.paymentId!,
                  ),
                ],
                const SizedBox(height: 14),
                // Status badge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accentColor.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isCancelled
                            ? Icons.replay_rounded
                            : Icons.support_agent_rounded,
                        color: _accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.isCancelled
                              ? 'No amount was deducted from your account'
                              : 'If your amount was deducted, it will be refunded in 5-7 business days',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
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

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _accentColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _kTextMuted, fontSize: 13.5),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Order Summary Card ───────────────────────────────────────────────────

  Widget _buildOrderSummaryCard() {
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  color: Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Order Summary',
                style: TextStyle(
                  color: _kTextDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow(
            'Amount Attempted',
            '₹${widget.amount.toStringAsFixed(2)}',
          ),
          _summaryRow('Payment Mode', widget.paymentMethodLabel),
          _summaryRow('Items', '${widget.itemsCount} item(s)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    color: _kTextMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accentColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.isCancelled ? 'Cancelled' : 'Failed',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _kTextMuted, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
              color: _kTextDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...previewItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Opacity(
                opacity: 0.6, // Dimmed since payment failed
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
                                  color: _kTextMuted,
                                ),
                              )
                            : const Icon(
                                Icons.image_outlined,
                                color: _kTextMuted,
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
                              color: _kTextDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Qty ${item['quantity']}',
                            style: const TextStyle(
                              color: _kTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${(((item['price'] as num?) ?? 0) * ((item['quantity'] as num?) ?? 0)).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: _kTextDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.selectedItems.length > 3)
            Text(
              '+${widget.selectedItems.length - 3} more item(s)',
              style: TextStyle(
                color: _accentColor,
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
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onTryAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isCancelled
                        ? Icons.replay_rounded
                        : Icons.refresh_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isCancelled ? 'Try Again' : 'Retry Payment',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: widget.onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kTextDark,
                side: const BorderSide(color: _kBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Back to Cart',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dashed Divider ───────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  final Color bgColor;
  const _DashedDivider({required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 24,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
            ),
          ),
          Expanded(child: CustomPaint(painter: _DashedLinePainter())),
          Container(
            width: 20,
            height: 24,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
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

// ─── Floating Particles Painter ───────────────────────────────────────────────

class _FloatingParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;

  _FloatingParticlesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final positions = [
      const Offset(0.1, 0.2),
      const Offset(0.85, 0.15),
      const Offset(0.2, 0.7),
      const Offset(0.9, 0.6),
      const Offset(0.5, 0.1),
      const Offset(0.7, 0.85),
      const Offset(0.05, 0.5),
    ];

    for (int i = 0; i < positions.length; i++) {
      final phase = (progress + i * 0.14) % 1.0;
      final floatY = math.sin(phase * math.pi * 2) * 15;
      final opacity = (math.sin(phase * math.pi * 2) * 0.5 + 0.5) * 0.07;

      paint.color = color.withOpacity(opacity);

      final cx = positions[i].dx * size.width;
      final cy = positions[i].dy * size.height + floatY;
      final radius = 20.0 + i * 8.0;

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_FloatingParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
