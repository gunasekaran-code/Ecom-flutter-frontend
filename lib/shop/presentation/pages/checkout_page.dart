import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/services/cart_service.dart';
import 'package:wss_sports/pages/payment_failed_page.dart';
import 'package:wss_sports/pages/payment_success_page.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutPage extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> selectedItems;
  final bool promoApplied;
  final double deliveryFee;
  final double discountPercent;

  const CheckoutPage({
    super.key,
    required this.userId,
    required this.selectedItems,
    required this.promoApplied,
    required this.deliveryFee,
    required this.discountPercent,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<Map<String, dynamic>> _savedAddresses = [];
  bool _isLoadingAddresses = true;
  int? _selectedAddressId;
  bool _showAddressForm = false;
  late final Razorpay _razorpay;
  Map<String, dynamic>? _pendingRazorpayData;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  static const List<String> _countries = ['India', 'United States', 'Canada'];
  static const Map<String, List<String>> _statesByCountry = {
    'India': [
      'Tamil Nadu',
      'Karnataka',
      'Kerala',
      'Maharashtra',
      'Delhi',
      'Telangana',
    ],
    'United States': [
      'California',
      'Texas',
      'New York',
      'Florida',
      'Washington',
    ],
    'Canada': ['Ontario', 'British Columbia', 'Quebec', 'Alberta'],
  };
  static const List<String> _addressTypes = ['home', 'office', 'other'];

  String _selectedCountry = 'India';
  String? _selectedState = 'Tamil Nadu';
  String _selectedAddressType = 'home';
  String _paymentMethod = 'upi';
  bool _isPlacingOrder = false;
  bool _isSavingAddress = false;

  int? _addressId(Map<String, dynamic> address) {
    final id = address['id'] ?? address['address_id'];
    return id is int ? id : int.tryParse(id?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
    _prefillFromUserProfile();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  // ─── Submit Order to Backend ─────────────────────────────────────────────

  Future<void> _submitOrderToBackend() async {
    setState(() => _isPlacingOrder = true);

    final result = await ApiService.placeOrder(
      userId: widget.userId,
      items: widget.selectedItems,
      paymentMethod: _paymentMethod,
      totalAmount: total,
      shippingAddress: _selectedAddress!,
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    if (result['success'] != true) {
      showAppSnackBar(
        context,
        title: 'Error',
        message: result['error']?.toString() ?? 'Could not place order',
        type: AppSnackBarType.error,
      );
      return;
    }

    final data = result['data'] as Map<String, dynamic>? ?? {};
    final orderId = data['order_id'];
    final orderCode = data['order_code'];

    CartService().removeLocalProducts(
      widget.selectedItems
          .map<int?>((item) => item['product_id'] as int?)
          .whereType<int>(),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessPage(
          title: _paymentMethod == 'cod'
              ? 'Order Confirmed'
              : 'Payment Successful',
          subtitle: _paymentMethod == 'cod'
              ? 'Pay at your doorstep'
              : 'Successfully Paid',
          amount: total,
          itemPrice: subtotal,
          deliveryFee: widget.deliveryFee,
          discount: widget.promoApplied
              ? (subtotal * widget.discountPercent / 100)
              : 0.0,
          itemsCount: _itemsCount,
          paymentMethodLabel: _paymentMethodLabel,
          orderId: orderId?.toString() ?? orderCode?.toString(),
          address: _selectedAddress!,
          selectedItems: widget.selectedItems,
          onContinueShopping: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  // ─── Place Order Entry Point ──────────────────────────────────────────────

  Future<void> _placeOrder() async {
    if (_showAddressForm) {
      await _saveNewAddress();
      if (_selectedAddressId == null) return;
    }
    if (_selectedAddress == null) {
      showAppSnackBar(
        context,
        title: 'Alert',
        message: 'Please select or add a delivery address',
        type: AppSnackBarType.alert,
      );
      return;
    }

    if (_paymentMethod == 'upi') {
      await _startRazorpayPayment();
    } else {
      await _submitOrderToBackend(); // COD stays on the direct /orders/place flow
    }
  }
  // ─── Address ─────────────────────────────────────────────────────────────

  Future<void> _loadSavedAddresses() async {
    setState(() => _isLoadingAddresses = true);

    List<Map<String, dynamic>> list = [];

    // ── Try backend first ──
    final result = await ApiService.getUserAddresses(widget.userId);
    if (result['success'] == true) {
      final data = result['data'];
      final rawList = data is List ? data : const [];
      list = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    // ── Fallback to local cache if backend returned nothing ──
    if (list.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('saved_addresses_${widget.userId}');
      if (raw != null) {
        list = List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoadingAddresses = false;
      _savedAddresses = list;
      if (_savedAddresses.isNotEmpty) {
        final defaultAddress = _savedAddresses.firstWhere(
          (addr) => addr['is_default'] == true,
          orElse: () => _savedAddresses.first,
        );
        _selectedAddressId = _addressId(defaultAddress);
        _showAddressForm = false;
      } else {
        _showAddressForm = true;
      }
    });
  }

  // ── NEW: prefill name/email/phone from the logged-in user's profile ──
  Future<void> _prefillFromUserProfile() async {
    final user = await ApiService.getUser();
    if (!mounted || user == null) return;
    if (_firstNameController.text.isNotEmpty)
      return; // don't clobber user edits

    final fullName = (user['full_name'] ?? '').toString().trim();
    if (fullName.isNotEmpty) {
      final parts = fullName.split(RegExp(r'\s+'));
      _firstNameController.text = parts.first;
      _lastNameController.text = parts.length > 1
          ? parts.sublist(1).join(' ')
          : '';
    }
    _emailController.text = (user['email'] ?? '').toString();
    _phoneController.text = (user['phone'] ?? '').toString();
  }

  Future<void> _startRazorpayPayment() async {
    setState(() => _isPlacingOrder = true);

    final result = await ApiService.createRazorpayOrder(
      items: widget.selectedItems,
      address: _selectedAddress!,
    );

    if (!mounted) return;

    if (result['success'] != true) {
      setState(() => _isPlacingOrder = false);
      showAppSnackBar(
        context,
        title: 'Error',
        message: result['error']?.toString() ?? 'Could not start payment',
        type: AppSnackBarType.error,
      );
      return;
    }

    final data = result['data'] as Map<String, dynamic>;
    _pendingRazorpayData = data; // keep local_order_id for verify step

    final options = {
      'key': data['key'],
      'amount': data['amount'],
      'currency': data['currency'] ?? 'INR',
      'name': data['name'] ?? 'WSS Sports',
      'description': data['description'] ?? 'Order Payment',
      'order_id': data['razorpay_order_id'],
      'prefill': {
        'contact':
            data['prefill']?['contact'] ?? _selectedAddress?['phone'] ?? '',
        'email': data['prefill']?['email'] ?? _selectedAddress?['email'] ?? '',
      },
    };

    try {
      print("Opening Razorpay with options:");
      print(options);
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      showAppSnackBar(
        context,
        title: 'Error',
        message: 'Could not open payment screen: $e',
        type: AppSnackBarType.error,
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isPlacingOrder = false);
    _goToFailedPage(
      message: response.message ?? 'Payment could not be completed.',
      isCancelled: response.code == Razorpay.PAYMENT_CANCELLED,
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isPlacingOrder = false);
    showAppSnackBar(
      context,
      title: 'Info',
      message: 'Selected wallet: ${response.walletName}',
      type: AppSnackBarType.info,
    );
  }

  void _goToFailedPage({
    required String message,
    required bool isCancelled,
    String? paymentId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentFailedPage(
          title: isCancelled ? 'Payment Cancelled' : 'Payment Failed',
          message: message,
          amount: total,
          itemsCount: _itemsCount,
          paymentMethodLabel: _paymentMethodLabel,
          paymentId: paymentId,
          address: _selectedAddress,
          selectedItems: widget.selectedItems,
          isCancelled: isCancelled,
          onTryAgain: () => Navigator.of(context).pop(),
          onBack: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final localOrderId = _pendingRazorpayData?['local_order_id'];
    if (localOrderId == null) {
      setState(() => _isPlacingOrder = false);
      _goToFailedPage(
        message: 'Missing order reference. Please contact support.',
        isCancelled: false,
      );
      return;
    }

    final verifyResult = await ApiService.verifyRazorpayOrder(
      localOrderId: int.tryParse(localOrderId.toString()) ?? 0,
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    if (verifyResult['success'] != true) {
      _goToFailedPage(
        message:
            verifyResult['error']?.toString() ?? 'Payment verification failed',
        isCancelled: false,
        paymentId: response.paymentId,
      );
      return;
    }

    CartService().removeLocalProducts(
      widget.selectedItems
          .map<int?>((item) => item['product_id'] as int?)
          .whereType<int>(),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessPage(
          title: 'Payment Successful',
          subtitle: 'Successfully Paid',
          amount: total,
          itemPrice: subtotal,
          deliveryFee: widget.deliveryFee,
          discount: widget.promoApplied
              ? (subtotal * widget.discountPercent / 100)
              : 0.0,
          itemsCount: _itemsCount,
          paymentMethodLabel: _paymentMethodLabel,
          paymentId: response.paymentId,
          orderId: _pendingRazorpayData?['local_order_id']?.toString(),
          address: _selectedAddress,
          selectedItems: widget.selectedItems,
          onContinueShopping: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  Future<void> _persistAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'saved_addresses_${widget.userId}',
      jsonEncode(_savedAddresses),
    );
  }

  List<String> get _stateOptions =>
      _statesByCountry[_selectedCountry] ?? const <String>[];

  double get subtotal => widget.selectedItems.fold(
    0.0,
    (sum, item) => sum + ((item['price'] as num) * (item['quantity'] as num)),
  );

  double get total =>
      subtotal + widget.deliveryFee - (subtotal * widget.discountPercent / 100);

  Future<void> _saveNewAddress() async {
    if (!_formKey.currentState!.validate() || _selectedState == null) {
      if (_selectedState == null) {
        showAppSnackBar(
          context,
          title: 'Alert',
          message: 'Please select a state / province',
          type: AppSnackBarType.alert,
        );
      }
      return;
    }
    setState(() => _isSavingAddress = true);

    final addressData = {
      'address_type': _selectedAddressType,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address_line_1': _addressLine1Controller.text.trim(),
      'address_line_2': _addressLine2Controller.text.trim(),
      'city': _cityController.text.trim(),
      'state': _selectedState,
      'postal_code': _postalCodeController.text.trim(),
      'country': _selectedCountry,
      'is_default': _savedAddresses.isEmpty,
    };

    final result = await ApiService.createAddress(
      userId: widget.userId,
      addressData: addressData,
    );

    Map<String, dynamic> newAddress;
    if (result['success'] == true && result['data'] is Map) {
      final data = result['data'] as Map;
      final saved = Map<String, dynamic>.from(data);
      newAddress = {...addressData, ...saved};
      newAddress['id'] ??= DateTime.now().millisecondsSinceEpoch;
    } else {
      newAddress = {
        ...addressData,
        'id': DateTime.now().millisecondsSinceEpoch,
      };
    }

    setState(() {
      _savedAddresses.add(newAddress);
      _selectedAddressId = _addressId(newAddress);
      _isSavingAddress = false;
      _showAddressForm = false;
    });
    await _persistAddresses(); // local cache stays as offline fallback

    if (!mounted) return;
    showAppSnackBar(
      context,
      title: 'Success',
      message: 'Address saved',
      type: AppSnackBarType.success,
    );
    _clearForm();
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _cityController.clear();
    _postalCodeController.clear();
    setState(() {
      _selectedCountry = 'India';
      _selectedState = 'Tamil Nadu';
      _selectedAddressType = 'home';
    });
  }

  Map<String, dynamic>? get _selectedAddress {
    if (_selectedAddressId == null) return null;
    for (final address in _savedAddresses) {
      if (_addressId(address) == _selectedAddressId) {
        return Map<String, dynamic>.from(address);
      }
    }
    return null;
  }

  int get _itemsCount => widget.selectedItems.fold<int>(
    0,
    (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
  );

  String get _paymentMethodLabel =>
      _paymentMethod == 'cod' ? 'Cash on Delivery' : 'UPI';

  // double _readAmount(dynamic value) =>
  //     double.tryParse(value?.toString() ?? '') ?? total;

  // int _readCount(dynamic value) =>
  //     int.tryParse(value?.toString() ?? '') ?? _itemsCount;

  Future<void> _confirmDeleteAddress(int addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() {
      _savedAddresses.removeWhere(
        (address) => _addressId(address) == addressId,
      );
      if (_selectedAddressId == addressId) {
        _selectedAddressId = _savedAddresses.isEmpty
            ? null
            : _addressId(_savedAddresses.first);
      }
      _showAddressForm = _savedAddresses.isEmpty;
    });
    await _persistAddresses();

    showAppSnackBar(
      context,
      title: 'Success',
      message: 'Address deleted',
      type: AppSnackBarType.success,
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: kBrandRed,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAddressSection(),
                  const SizedBox(height: 16),
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 16),
                  _buildPaymentSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _buildPlaceOrderBar(),
          ],
        ),
      ),
    );
  }

  // ─── Order Summary Card ───────────────────────────────────────────────────

  Widget _buildOrderSummaryCard() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBrandRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: kBrandRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    color: kTextDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...widget.selectedItems.map((item) => _buildItemRow(item)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const Divider(color: kBorder),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                _summaryRow(
                  'Delivery Fee',
                  '₹${widget.deliveryFee.toStringAsFixed(2)}',
                ),
                if (widget.promoApplied)
                  _summaryRow(
                    'Discount',
                    '-${widget.discountPercent.toInt()}%',
                    isDiscount: true,
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: kBrandRed.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: kTextDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
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
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item['image'],
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_outlined, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${item['quantity']}',
                  style: const TextStyle(color: kTextMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '₹${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: kTextDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Payment Section ──────────────────────────────────────────────────────

  Widget _buildPaymentSection() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    color: kTextDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            value: 'upi',
            title: 'UPI',
            subtitle: 'Pay online and confirm your order',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF6C63FF),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Divider(color: kBorder, height: 1),
          ),
          _buildPaymentOption(
            value: 'cod',
            title: 'Cash on Delivery',
            subtitle: 'Pay when the order arrives',
            icon: Icons.local_shipping_rounded,
            iconColor: Colors.green,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? iconColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? iconColor : kTextDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: kTextMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? iconColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? iconColor : kBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Place Order Bar ──────────────────────────────────────────────────────

  Widget _buildPlaceOrderBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isPlacingOrder
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _paymentMethod == 'cod'
                          ? Icons.local_shipping_rounded
                          : Icons.lock_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _paymentMethod == 'cod'
                          ? 'Place Order • ₹${total.toStringAsFixed(2)}'
                          : 'Pay Online • ₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Address Section ──────────────────────────────────────────────────────

  Widget _buildAddressSection() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    color: kTextDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _isLoadingAddresses
                ? const AddressSkeleton()
                : Column(
                    children: [
                      if (_savedAddresses.isNotEmpty && !_showAddressForm)
                        ..._savedAddresses.map(_buildAddressCard),
                      if (!_showAddressForm)
                        InkWell(
                          onTap: () => setState(() {
                            _showAddressForm = true;
                            _selectedAddressId = null;
                          }),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: kBrandRed.withOpacity(0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              color: kBrandRed.withOpacity(0.02),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: kBrandRed,
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add New Address',
                                  style: TextStyle(
                                    color: kBrandRed,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_showAddressForm) _buildAddressForm(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final addressId = _addressId(address);
    final isSelected = _selectedAddressId == addressId;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? kBrandRed : kBorder,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
        color: isSelected ? kBrandRed.withOpacity(0.04) : Colors.white,
      ),
      child: InkWell(
        onTap: () => setState(() {
          _selectedAddressId = addressId;
          _showAddressForm = false;
        }),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? kBrandRed : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? kBrandRed : kBorder,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _tag(
                          address['address_type'].toString().toUpperCase(),
                          kBrandRed,
                        ),
                        if (address['is_default'] == true) ...[
                          const SizedBox(width: 6),
                          _tag('DEFAULT', Colors.green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${address['first_name']} ${address['last_name']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${address['address_line_1']}, ${address['city']}, ${address['state']}',
                      style: const TextStyle(fontSize: 12, color: kTextMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: addressId == null
                    ? null
                    : () => _confirmDeleteAddress(addressId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAddressForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              if (_savedAddresses.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    _showAddressForm = false;
                    _clearForm();
                    if (_savedAddresses.isNotEmpty) {
                      _selectedAddressId = _addressId(_savedAddresses.first);
                    }
                  }),
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppDropdownField<String>(
            value: _selectedAddressType,
            label: 'Address Type',
            items: _addressTypes,
            onChanged: (value) {
              if (value != null) setState(() => _selectedAddressType = value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'Required',
                  validator: _requiredValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Required',
                  validator: _requiredValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            validator: _emailValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '10-digit mobile number',
            validator: _phoneValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressLine1Controller,
            label: 'Address Line 1',
            hint: 'Street address, P.O. box',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressLine2Controller,
            label: 'Address Line 2',
            hint: 'Apartment, suite, unit',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _cityController,
            label: 'City',
            hint: 'Required',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppDropdownField<String>(
                  value: _selectedState,
                  label: 'State / Province',
                  items: _stateOptions,
                  onChanged: (value) => setState(() => _selectedState = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _postalCodeController,
                  label: 'Postal Code',
                  hint: 'Required',
                  validator: _requiredValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppDropdownField<String>(
            value: _selectedCountry,
            label: 'Country',
            items: _countries,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCountry = value;
                  final nextStates =
                      _statesByCountry[_selectedCountry] ?? const [];
                  _selectedState = nextStates.isNotEmpty
                      ? nextStates.first
                      : null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSavingAddress ? null : _saveNewAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSavingAddress
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Address',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBrandRed, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget AppDropdownField<T>({
    required T? value,
    required String label,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBrandRed, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kTextMuted, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isDiscount ? Colors.green : kTextDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) return 'Enter a valid phone number';
    return null;
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }
}
