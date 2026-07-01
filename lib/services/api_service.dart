import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.10:8000/api';
  static final String _assetBaseUrl = Uri.parse(baseUrl).origin;

  static const bool debugMode = true;
  static const Duration _requestTimeout = Duration(seconds: 30);
  static String? lastCartError;

  static void _log(String message) {
    if (debugMode) print('🔵 [API] $message');
  }

  static void _logError(String message) {
    if (debugMode) print('🔴 [API ERROR] $message');
  }

  static Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body);
  }

  static String _errorMessage(dynamic data, String fallback) {
    if (data is Map) {
      return (data['error'] ?? data['detail'] ?? data['message'] ?? fallback)
          .toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return fallback;
  }

  // ─── NEW: headers with Bearer token ───────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static bool _isSuccessStatus(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  static String? _firstStringValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  static String? _absoluteAssetUrl(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) return trimmed;

    final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$_assetBaseUrl$normalized';
  }

  static Map<String, dynamic> _normalizeCategory(
    Map<String, dynamic> category,
  ) {
    final normalized = Map<String, dynamic>.from(category);
    normalized['id'] ??= normalized['category_id'];
    normalized['name'] ??= _firstStringValue(normalized, [
      'category_name',
      'title',
      'slug',
    ]);
    normalized['display_name'] ??= _firstStringValue(normalized, [
      'displayName',
      'display_name',
      'category_name',
      'name',
      'title',
    ]);
    return normalized;
  }

  static Map<String, dynamic> _normalizeProduct(Map<String, dynamic> product) {
    final normalized = Map<String, dynamic>.from(product);

    normalized['id'] ??= normalized['product_id'];
    normalized['name'] ??= _firstStringValue(normalized, [
      'product_name',
      'title',
    ]);
    normalized['description'] ??= _firstStringValue(normalized, [
      'product_description',
      'details',
      'short_description',
    ]);
    normalized['price'] ??= _firstStringValue(normalized, [
      'selling_price',
      'sale_price',
      'mrp',
      'amount',
    ]);
    normalized['stock'] ??= normalized['available_stock'] ?? normalized['qty'];

    final category = normalized['category'];
    if (category is Map<String, dynamic>) {
      final parsedCategory = _normalizeCategory(category);
      normalized['category_id'] ??= parsedCategory['id'];
      normalized['category_name'] ??= parsedCategory['display_name'];
    } else {
      normalized['category_name'] ??= _firstStringValue(normalized, [
        'categoryName',
        'category_name',
        'category_title',
      ]);
    }

    final image = _firstStringValue(normalized, [
      'image_url',
      'image',
      'product_image',
      'productImage',
      'image_path',
      'imagePath',
      'image_name',
      'product_img',
      'productImageUrl',
      'product_image_url',
      'thumbnail',
      'thumbnail_url',
      'thumb',
      'photo',
      'photo_url',
      'main_image',
      'main_image_url',
    ]);
    normalized['image_url'] = _absoluteAssetUrl(image);

    final images = normalized['images'];
    if (images is List) {
      normalized['images'] = images.map((item) {
        if (item is Map<String, dynamic>) {
          final parsed = Map<String, dynamic>.from(item);
          parsed['image_url'] = _absoluteAssetUrl(
            _firstStringValue(parsed, [
              'image_url',
              'image',
              'product_image',
              'image_path',
              'image_name',
              'url',
              'path',
            ]),
          );
          return parsed;
        }
        return _absoluteAssetUrl(item?.toString());
      }).toList();
    }

    return normalized;
  }

  static List<dynamic> _listFromDecoded(dynamic decoded, List<String> keys) {
    if (decoded is List) return decoded;
    if (decoded is! Map<String, dynamic>) return const <dynamic>[];

    for (final key in keys) {
      final value = decoded[key];
      if (value is List) return value;
      if (value is Map<String, dynamic>) {
        final nested = _listFromDecoded(value, keys);
        if (nested.isNotEmpty) return nested;
      }
    }

    return const <dynamic>[];
  }

  static List<dynamic> _cartListFromDecoded(dynamic decoded) =>
      _listFromDecoded(decoded, [
        'data',
        'cart',
        'items',
        'cart_items',
        'cartitems',
      ]);

  static List<dynamic> _wishlistListFromDecoded(dynamic decoded) =>
      _listFromDecoded(decoded, ['data', 'wishlist', 'items', 'products']);

  static Future<http.Response> _postJson(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false, // pass true for protected POSTs
  }) async {
    final uri = Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}');
    _log('POST $uri');
    _log('Request body: ${jsonEncode(body)}');
    final headers = authenticated ? await _authHeaders() : _jsonHeaders;
    return http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(_requestTimeout);
  }

  // ─── UPDATED: accepts optional `authenticated` flag ───────────────────────
  static Future<http.Response> _getJson(
    String path, {
    Map<String, String>? queryParams,
    bool authenticated = true, // true by default — most GETs are protected
  }) async {
    final uri = Uri.parse(
      '$baseUrl${path.startsWith('/') ? path : '/$path'}',
    ).replace(queryParameters: queryParams);
    _log('GET $uri');
    final headers = authenticated ? await _authHeaders() : _jsonHeaders;
    return http.get(uri, headers: headers).timeout(_requestTimeout);
  }

  // ─────────────────────────────────────────────
  //  SERVER HEALTH
  // ─────────────────────────────────────────────

  static Future<bool> pingServer() async {
    try {
      _log('Pinging server...');
      final response = await http
          .get(Uri.parse('$baseUrl/user/products/'))
          .timeout(const Duration(seconds: 30));
      _log('Ping: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      _logError('Ping failed: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  //  USER APIs
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      _log('Login: $email');
      // login is unauthenticated
      final response = await _postJson('/login/', {
        'email': email,
        'password': password,
      }, authenticated: false);
      _log('Status: ${response.statusCode}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'error': 'Empty response. Status: ${response.statusCode}',
        };
      }

      final data = _decodeBody(response);
      if (_isSuccessStatus(response.statusCode)) {
        // ─── Save token on successful login ────────────────────────────────
        final token = data['token'] ?? data['access'] ?? data['access_token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token.toString());
          _log('Token saved');
        }
        // ───────────────────────────────────────────────────────────────────
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': _errorMessage(
          data,
          'Login failed. Status: ${response.statusCode}',
        ),
        'errors': data['errors'],
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _log('Token cleared');
  }

  static Future<Map<String, dynamic>> loginUserWithWakeUp({
    required String email,
    required String password,
  }) async {
    await pingServer();
    await Future.delayed(const Duration(seconds: 2));
    return loginUser(email: email, password: password);
  }

  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _postJson('/register/', {
        'name': fullName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      if (response.body.isEmpty) {
        return {'success': false, 'error': 'Empty response from server'};
      }
      final data = _decodeBody(response);
      if (_isSuccessStatus(response.statusCode)) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': data};
    } on TimeoutException {
      return {'success': false, 'error': 'Request timed out.'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _postJson('/forgot-password/', {'email': email});
      final data = _decodeBody(response);
      if (_isSuccessStatus(response.statusCode)) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': _errorMessage(data, 'Unable to send reset request.'),
      };
    } on TimeoutException {
      return {'success': false, 'error': 'Request timed out.'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _postJson('/reset-password/', {
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      final data = _decodeBody(response);
      if (_isSuccessStatus(response.statusCode)) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': _errorMessage(data, 'Reset failed.')};
    } on TimeoutException {
      return {'success': false, 'error': 'Request timed out.'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> getUser({required int id}) async {
    try {
      _log('Fetching user ID: $id');
      final response = await _getJson('/user', authenticated: true);
      _log('Get user: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : null;
      }
      _logError('Get user failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      _logError('Error fetching user: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required int id,
    String? fullName,
    String? email,
    String? phone,
    XFile? imageFile,
  }) async {
    try {
      _log('Updating user ID: $id');
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/user/partial'),
      );
      if (fullName != null) request.fields['full_name'] = fullName;
      if (email != null) request.fields['email'] = email;
      if (phone != null) request.fields['phone'] = phone;
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ),
        );
      }
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      _log('Update user: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(responseData)};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: $responseData',
      };
    } catch (e) {
      _logError('Error updating user: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ─────────────────────────────────────────────
  //  PRODUCT APIs
  // ─────────────────────────────────────────────

  /// Fetch all products, optionally filtered by [category].
  // static Future<List<Map<String, dynamic>>> getProducts({
  //   String? category,
  // }) async {
  //   try {
  //     final response = await _getJson(
  //       '/user/products/',
  //       queryParams: (category != null && category.isNotEmpty)
  //           ? {'category': category}
  //           : null,
  //     );
  //     _log('Products: ${response.statusCode}');
  //     if (response.statusCode == 200) {
  //       final decoded = jsonDecode(response.body);
  //       final data = decoded is List
  //           ? decoded
  //           : decoded is Map<String, dynamic> && decoded['results'] is List
  //           ? decoded['results'] as List
  //           : const <dynamic>[];
  //       _log('Retrieved ${data.length} products');
  //       return data.whereType<Map<String, dynamic>>().toList();
  //     }
  //     _logError('Failed to fetch products: ${response.statusCode}');
  //     return [];
  //   } catch (e) {
  //     _logError('Error fetching products: $e');
  //     return [];
  //   }
  // }

  static Future<List<Map<String, dynamic>>> getProducts({
    String? category,
  }) async {
    try {
      final response = await _getJson(
        '/user/products/',
        queryParams: (category != null && category.isNotEmpty)
            ? {'category': category}
            : null,
      );
      _log('Products: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = _listFromDecoded(decoded, [
          'data',
          'results',
          'products',
          'items',
        ]);
        _log('Retrieved ${data.length} products');
        return data
            .whereType<Map<String, dynamic>>()
            .map(_normalizeProduct)
            .toList();
      }
      _logError('Failed to fetch products: ${response.statusCode}');
      return [];
    } catch (e) {
      _logError('Error fetching products: $e');
      return [];
    }
  }

  /// Fetch a single product by [id].
  static Future<Map<String, dynamic>?> getProductDetail(int id) async {
    try {
      _log('Fetching product detail ID: $id');
      final products = await getProducts();
      for (final product in products) {
        final productId = int.tryParse(product['id']?.toString() ?? '');
        if (productId == id) return product;
      }
      _logError('Product detail not found: $id');
      return null;
    } catch (e) {
      _logError('Error fetching product detail: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  //  CART APIs
  // ─────────────────────────────────────────────

  static Future<bool> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    try {
      lastCartError = null;
      if (productId <= 0) {
        lastCartError = 'Invalid product selected.';
        _logError('Invalid product id for add to cart: $productId');
        return false;
      }

      final response = await _postJson('/user/cart/add', {
        'product_id': productId,
        'quantity': quantity,
      }, authenticated: true);
      if (_isSuccessStatus(response.statusCode)) {
        return true;
      }

      final decoded = _decodeBody(response);
      final message = _errorMessage(decoded, 'Could not add item to cart');
      if (response.statusCode == 400 && _isAlreadyInCartMessage(message)) {
        return true;
      }

      if (response.statusCode == 400 && message.toLowerCase().contains('qty')) {
        final qtyResponse = await _postJson('/user/cart/add', {
          'product_id': productId,
          'qty': quantity,
        }, authenticated: true);
        if (_isSuccessStatus(qtyResponse.statusCode)) {
          return true;
        }

        final qtyDecoded = _decodeBody(qtyResponse);
        final qtyMessage = _errorMessage(
          qtyDecoded,
          'Could not add item to cart',
        );
        if (qtyResponse.statusCode == 400 &&
            _isAlreadyInCartMessage(qtyMessage)) {
          return true;
        }
        _logError(
          'Add to cart failed: ${qtyResponse.statusCode} ${qtyResponse.body}',
        );
        lastCartError = qtyMessage;
        return false;
      }

      _logError('Add to cart failed: ${response.statusCode} ${response.body}');
      lastCartError = message;
      return false;
    } catch (e) {
      lastCartError = 'Could not add item to cart.';
      _logError('Error adding to cart: $e');
      return false;
    }
  }

  static bool _isAlreadyInCartMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('already') &&
        (normalized.contains('cart') || normalized.contains('exist'));
  }

  static Future<List<dynamic>> getCart(int userId) async {
    try {
      final response = await _getJson('/user/cart');
      // final response = await _getJson('/user/cart/$userId', authenticated: true);
      if (response.statusCode == 200) {
        final decoded = _decodeBody(response);
        final items = _cartListFromDecoded(decoded);
        return items.map((item) {
          if (item is Map<String, dynamic>) {
            final normalized = Map<String, dynamic>.from(item);
            if (normalized['product'] is Map<String, dynamic>) {
              normalized['product'] = _normalizeProduct(
                Map<String, dynamic>.from(normalized['product']),
              );
            }
            return normalized;
          }
          return item;
        }).toList();
      }
    } catch (e) {
      _logError('Error fetching cart: $e');
    }
    return [];
  }

  static Future<bool> updateCartItem({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    try {
      final response = await _postJson('/user/cart/update', {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
      }, authenticated: true);
      return _isSuccessStatus(response.statusCode);
    } catch (e) {
      _logError('Error updating cart item: $e');
      return false;
    }
  }

  static Future<http.Response> _deleteJson(
    String path, {
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}');

    final headers = authenticated ? await _authHeaders() : _jsonHeaders;

    _log('DELETE $uri');

    return http.delete(uri, headers: headers).timeout(_requestTimeout);
  }

  static Future<bool> removeFromCart({
    required int userId,
    required int productId,
    int? cartItemId,
  }) async {
    try {
      final id = cartItemId ?? productId;
      final response = await _deleteJson(
        // '/cart/remove/$id',
        '/user/cart/remove/$id',
        authenticated: true,
      );

      if (_isSuccessStatus(response.statusCode)) {
        return true;
      }

      _logError('Remove cart failed: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      _logError('Error removing from cart: $e');
      return false;
    }
  }

  // static Future<bool> removeFromCart({
  //   required int userId,
  //   required int productId,
  // }) async {
  //   try {
  //     final response = await _postJson('user/cart/remove/{$id}', {
  //       'user_id': userId,
  //       'product_id': productId,
  //     }, authenticated: true);
  //     return _isSuccessStatus(response.statusCode);
  //   } catch (e) {
  //     _logError('Error removing from cart: $e');
  //     return false;
  //   }
  // }

  static Future<int> getCartCount(int userId) async {
    final cart = await getCart(userId);
    return cart.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
  }

  static Future<Map<String, dynamic>> checkoutCart({
    required int userId,
    required List<int> productIds,
    int? addressId,
    Map<String, dynamic>? shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'product_ids': productIds,
        'payment_method': paymentMethod,
      };
      if (addressId != null) {
        body['address_id'] = addressId;
      } else if (shippingAddress != null) {
        body['shipping_address'] = shippingAddress;
      }
      _log('Checkout body: ${jsonEncode(body)}');
      final response = await _postJson(
        '/user/orders/place',
        body,
        authenticated: true,
      );
      final data = _decodeBody(response);
      if (_isSuccessStatus(response.statusCode)) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': _errorMessage(data, 'Checkout failed.'),
      };
    } catch (e) {
      _logError('Checkout exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> placeOrder({
    required int userId,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required double totalAmount,
    Map<String, dynamic>? shippingAddress,
    int? addressId,
  }) {
    return checkoutCart(
      userId: userId,
      productIds: items
          .map<int?>((item) => int.tryParse(item['product_id'].toString()))
          .whereType<int>()
          .toList(),
      addressId: addressId,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
    );
  }

  static Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    String currency = 'INR',
    Map<String, dynamic>? notes,
  }) async {
    try {
      final response = await _postJson('/razorpay/create-order', {
        'amount': amount,
        'currency': currency,
        if (notes != null) 'notes': notes,
      }, authenticated: true);
      final data = _decodeBody(response);
      return _isSuccessStatus(response.statusCode)
          ? {'success': true, 'data': data}
          : {
              'success': false,
              'error': _errorMessage(data, 'Could not create Razorpay order.'),
            };
    } catch (e) {
      _logError('Razorpay create-order exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyRazorpayOrder({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _postJson('/razorpay/verify-order', {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      }, authenticated: true);
      final data = _decodeBody(response);
      return _isSuccessStatus(response.statusCode)
          ? {'success': true, 'data': data}
          : {
              'success': false,
              'error': _errorMessage(
                data,
                'Could not verify Razorpay payment.',
              ),
            };
    } catch (e) {
      _logError('Razorpay verify-order exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  //  WISHLIST APIs
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getWishlist(int userId) async {
    try {
      final response = await _getJson('/user/wishlist');
      if (response.statusCode == 200) {
        final decoded = _decodeBody(response);
        final items = _wishlistListFromDecoded(decoded);
        return items.map((item) {
          if (item is Map<String, dynamic>) {
            final normalized = Map<String, dynamic>.from(item);
            if (normalized['product'] is Map<String, dynamic>) {
              normalized['product'] = _normalizeProduct(
                Map<String, dynamic>.from(normalized['product']),
              );
            }
            return normalized;
          }
          return item;
        }).toList();
      }
    } catch (e) {
      _logError('Error fetching wishlist: $e');
    }
    return [];
  }

  static Future<bool> addToWishlist({
    required int userId,
    required int productId,
  }) async {
    try {
      final response = await _postJson('/user/wishlist/add', {
        'user_id': userId,
        'product_id': productId,
      }, authenticated: true);
      return _isSuccessStatus(response.statusCode);
    } catch (e) {
      _logError('Error adding to wishlist: $e');
      return false;
    }
  }

  static Future<bool> removeFromWishlist({
    required int userId,
    required int productId,
  }) async {
    try {
      final response = await _postJson('/user/wishlist/add', {
        'user_id': userId,
        'product_id': productId,
      }, authenticated: true);
      return _isSuccessStatus(response.statusCode);
    } catch (e) {
      _logError('Error removing from wishlist: $e');
      return false;
    }
  }

  static Future<bool> isProductInWishlist({
    required int userId,
    required int productId,
  }) async {
    try {
      final response = await _getJson('/wishlist/check/$userId/$productId/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_in_wishlist'] ?? false;
      }
    } catch (e) {
      _logError('Error checking wishlist: $e');
    }
    return false;
  }

  // ─────────────────────────────────────────────
  //  CATEGORY APIs
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await _getJson('/user/categories/');
      _log('Categories: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = _listFromDecoded(decoded, [
          'data',
          'results',
          'categories',
          'items',
        ]);
        return {
          'success': true,
          'data': data
              .whereType<Map<String, dynamic>>()
              .map(_normalizeCategory)
              .toList(),
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'Categories endpoint not found. Deploy the latest backend.',
        };
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      _logError('Error fetching categories: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createCategory({
    required String name,
    required String displayName,
    String? description,
  }) async {
    try {
      final response = await _postJson('/categories/create/', {
        'name': name,
        'display_name': displayName,
        'description': description ?? '',
      });
      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      _logError('Error creating category: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/categories/delete/$categoryId/'))
          .timeout(_requestTimeout);
      if (response.statusCode == 200) return {'success': true};
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      _logError('Error deleting category: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ─────────────────────────────────────────────
  //  ADDRESS APIs
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUserAddresses(int userId) async {
    try {
      final response = await _getJson(
        '/addresses/',
        queryParams: {'user_id': userId.toString()},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createAddress({
    required int userId,
    required Map<String, dynamic> addressData,
  }) async {
    try {
      final response = await _postJson('/addresses/create/', {
        'user_id': userId,
        ...addressData,
      });
      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteAddress({
    required int addressId,
    required int userId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/addresses/$addressId/delete/?user_id=$userId'),
          )
          .timeout(_requestTimeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  //  EXCHANGE RATE
  // ─────────────────────────────────────────────

  static Future<double> getExchangeRate() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'))
          .timeout(_requestTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['rates']['INR'] as num?)?.toDouble() ?? 83.0;
      }
    } catch (e) {
      _logError('Error fetching exchange rate: $e');
    }
    return 83.0;
  }
}
