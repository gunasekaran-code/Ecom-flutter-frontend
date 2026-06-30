import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.15:8000/api';

  static const bool debugMode = true;
  static const Duration _requestTimeout = Duration(seconds: 30);

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
          .get(Uri.parse('$baseUrl/products/'))
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
      final response = await http
          .get(Uri.parse('$baseUrl/user/$id/'))
          .timeout(_requestTimeout);
      _log('Get user: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : null;
      }
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
        Uri.parse('$baseUrl/user/partial/$id/'),
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
  static Future<List<Map<String, dynamic>>> getProducts({
    String? category,
  }) async {
    try {
      final response = await _getJson(
        '/products/',
        queryParams: (category != null && category.isNotEmpty)
            ? {'category': category}
            : null,
      );
      _log('Products: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is List
            ? decoded
            : decoded is Map<String, dynamic> && decoded['results'] is List
            ? decoded['results'] as List
            : const <dynamic>[];
        _log('Retrieved ${data.length} products');
        return data.whereType<Map<String, dynamic>>().toList();
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
      final response = await _getJson('/products/$id/');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _logError('Product detail failed: ${response.statusCode}');
      return null;
    } catch (e) {
      _logError('Error fetching product detail: $e');
      return null;
    }
  }

  /// Admin — fetch all products including soft-deleted ones.
  static Future<List<Map<String, dynamic>>> getAllProductsAdmin() async {
    try {
      _log('Fetching all admin products');
      final response = await _getJson('/admin/products/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      _logError('Admin products failed: ${response.statusCode}');
      return [];
    } catch (e) {
      _logError('Error fetching admin products: $e');
      return [];
    }
  }

  /// Admin — create a new product.
  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String description,
    required double price,
    required int categoryId,
    required int stock,
    double rating = 0.0,
    int? skuId,
    XFile? imageFile,
  }) async {
    try {
      _log('Creating product: $name');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/products/create/'),
      );
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['category'] = categoryId.toString();
      request.fields['stock'] = stock.toString();
      request.fields['rating'] = rating.toString();
      if (skuId != null) request.fields['sku_id'] = skuId.toString();
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
      _log('Create product: ${response.statusCode}');
      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(responseData)};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: $responseData',
      };
    } catch (e) {
      _logError('Error creating product: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Admin — update an existing product.
  static Future<Map<String, dynamic>> updateProduct({
    required int id,
    required String name,
    required String description,
    required double price,
    required int categoryId,
    required int stock,
    double rating = 0.0,
    int? skuId,
    bool removeImage = false,
    XFile? imageFile,
  }) async {
    try {
      _log('Updating product ID: $id');
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/admin/products/update/$id/'),
      );
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['category'] = categoryId.toString();
      request.fields['stock'] = stock.toString();
      request.fields['rating'] = rating.toString();
      if (skuId != null) request.fields['sku_id'] = skuId.toString();
      if (removeImage) request.fields['remove_image'] = 'true';
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
      _log('Update product: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(responseData)};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: $responseData',
      };
    } catch (e) {
      _logError('Error updating product: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Admin — soft-delete a product.
  static Future<bool> softDeleteProduct(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/admin/products/soft-delete/$id/'))
          .timeout(_requestTimeout);
      return response.statusCode == 200;
    } catch (e) {
      _logError('Error soft deleting product: $e');
      return false;
    }
  }

  /// Admin — restore a soft-deleted product.
  static Future<bool> restoreProduct(int id) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/admin/products/restore/$id/'))
          .timeout(_requestTimeout);
      return response.statusCode == 200;
    } catch (e) {
      _logError('Error restoring product: $e');
      return false;
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
      final response = await _postJson('/cart/add/', {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
      });
      return _isSuccessStatus(response.statusCode);
    } catch (e) {
      _logError('Error adding to cart: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getCart(int userId) async {
    try {
      final response = await _getJson('/cart/$userId/');
      if (response.statusCode == 200) return jsonDecode(response.body);
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
      final response = await _postJson('/cart/update/', {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
      });
      return _isSuccessStatus(response.statusCode);
    } catch (e) {
      _logError('Error updating cart item: $e');
      return false;
    }
  }

  static Future<bool> removeFromCart({
    required int userId,
    required int productId,
  }) async {
    try {
      final response = await _postJson('/cart/remove/', {
        'user_id': userId,
        'product_id': productId,
      });
      return _isSuccessStatus(response.statusCode);
    } catch (e) {
      _logError('Error removing from cart: $e');
      return false;
    }
  }

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
      final response = await _postJson('/cart/checkout/', body);
      final data = jsonDecode(response.body);
      if (_isSuccessStatus(response.statusCode)) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': data['error'] ?? 'Checkout failed.'};
    } catch (e) {
      _logError('Checkout exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  //  WISHLIST APIs
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getWishlist(int userId) async {
    try {
      final response = await _getJson('/wishlist/$userId/');
      if (response.statusCode == 200) return jsonDecode(response.body);
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
      final response = await _postJson('/wishlist/add/', {
        'user_id': userId,
        'product_id': productId,
      });
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
      final response = await _postJson('/wishlist/remove/', {
        'user_id': userId,
        'product_id': productId,
      });
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
      final response = await _getJson('/categories/');
      _log('Categories: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
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
