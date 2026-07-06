import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.07:8000/api';
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
      if (value is Map || value is List)
        continue; // ← skip nested objects, don't stringify them
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

  static String? _profileImageUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;

    final filename = trimmed.split('/').last;

    return '$_assetBaseUrl/admin/api/profile-image/$filename';
  }

  static Map<String, dynamic> _normalizeUser(Map<String, dynamic> user) {
    final imageUrl = _profileImageUrl(
      user['profile_image']?.toString() ?? user['image_url']?.toString(),
    );
    return {
      ...user,
      'id': user['id'],
      'full_name': user['name']?.toString() ?? user['full_name']?.toString(),
      'email': user['email']?.toString(),
      'phone': user['phone_number']?.toString() ?? user['phone']?.toString(),
      'gender': user['gender']?.toString(),
      'profile_image': imageUrl,
      'image_url': imageUrl,
    };
  }

  static Future<Map<String, dynamic>?> getUser({int? id}) async {
    try {
      _log('Fetching profile');
      final response = await _getJson('/user/profile', authenticated: true);
      _log('Get profile: ${response.statusCode} — ${response.body}');
      if (response.statusCode == 200) {
        final decoded = _decodeBody(response);
        final user = decoded is Map<String, dynamic> ? decoded['user'] : null;
        if (user is Map<String, dynamic>) {
          return _normalizeUser(Map<String, dynamic>.from(user));
        }
      }
      _logError('Get profile failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      _logError('Error fetching profile: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? gender,
    XFile? imageFile,
  }) async {
    try {
      _log('Updating profile');
      final request = http.MultipartRequest(
        'POST', // Laravel route is Route::post('profile/update', ...)
        Uri.parse('$baseUrl/user/profile/update'),
      );

      final headers = await _authHeaders();
      headers.remove(
        'Content-Type',
      ); // let MultipartRequest set its own boundary
      request.headers.addAll(headers);

      if (name != null) request.fields['name'] = name;
      if (email != null) request.fields['email'] = email;
      if (phone != null) request.fields['phone_number'] = phone;
      if (gender != null && gender.isNotEmpty)
        request.fields['gender'] = gender;

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_image', // must match Laravel's validated field name
            bytes,
            filename: imageFile.name,
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      _log('Update profile: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        final user = decoded is Map<String, dynamic> ? decoded['user'] : null;
        if (user is Map<String, dynamic>) {
          return {
            'success': true,
            'data': _normalizeUser(Map<String, dynamic>.from(user)),
          };
        }
        return {'success': false, 'error': 'Unexpected response format'};
      }

      try {
        final decoded = jsonDecode(responseBody);
        return {
          'success': false,
          'error': _errorMessage(decoded, 'HTTP ${response.statusCode}'),
        };
      } catch (_) {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: $responseBody',
        };
      }
    } catch (e) {
      _logError('Error updating profile: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static String? _colorNameToHex(String label) {
    final key = label.trim().toLowerCase();
    const map = {
      'red': '#E53935',
      'blue': '#1E88E5',
      'green': '#43A047',
      'black': '#212121',
      'white': '#FAFAFA',
      'yellow': '#FDD835',
      'orange': '#FB8C00',
      'pink': '#EC407A',
      'purple': '#8E24AA',
      'grey': '#9E9E9E',
      'gray': '#9E9E9E',
      'brown': '#6D4C41',
      'navy': '#1A237E',
      'maroon': '#800000',
      'beige': '#D7C4A3',
    };
    return map[key];
  }

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

        final products = data
            .whereType<Map<String, dynamic>>()
            .map(_normalizeProduct)
            .toList();

        // ── Workaround: list endpoint has no rating data, so fetch it
        // per-product from the detail endpoint and merge it in. ──
        await Future.wait(
          products.map((product) async {
            final id = int.tryParse(product['id']?.toString() ?? '');
            if (id == null || id <= 0) return;
            try {
              final detail = await getProductDetail(id);
              if (detail != null) {
                if (detail['average_rating'] != null) {
                  product['average_rating'] = detail['average_rating'];
                }
                if (detail['total_reviews'] != null) {
                  product['total_reviews'] = detail['total_reviews'];
                }
              }
            } catch (e) {
              _logError('Rating fetch failed for product $id: $e');
            }
          }),
        );

        return products;
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
      final response = await _getJson('/user/products/$id');
      _log('Product detail: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = _decodeBody(response);
        final rawData = decoded is Map<String, dynamic>
            ? (decoded['data'] is Map<String, dynamic>
                  ? Map<String, dynamic>.from(decoded['data'])
                  : decoded)
            : null;
        if (rawData == null) return null;

        // ── Flatten nested `product` object up to the top level ──
        // Backend returns { product: {...}, price, stock, images, variations, ... }
        // but the rest of the app expects one flat product map.
        final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
        final nestedProduct = rawData['product'];
        if (nestedProduct is Map<String, dynamic>) {
          data.addAll(nestedProduct); // product fields first...
          // ...then re-apply the sibling overrides so they win (fresher price/stock/images)
          for (final key in [
            'price',
            'stock',
            'images',
            'variations',
            'average_rating',
            'total_reviews',
            'reviews',
            'related_products',
          ]) {
            if (rawData.containsKey(key)) data[key] = rawData[key];
          }
        }

        // ── Flatten variations: backend groups by type as an object ──
        // { "size": [ {variation_item_id, value, price, stock, image}, ... ],
        //   "color": [ ... ] }
        // Flutter's chip UI needs a flat list: [ {id, type, label, price, stock, image, color_hex?}, ... ]
        final rawVariations = data['variations'];
        if (rawVariations is Map<String, dynamic>) {
          final List<Map<String, dynamic>> flat = [];
          rawVariations.forEach((type, options) {
            if (options is List) {
              for (final opt in options) {
                if (opt is Map<String, dynamic>) {
                  final stock =
                      int.tryParse(opt['stock']?.toString() ?? '') ?? 0;
                  final label =
                      opt['value']?.toString() ??
                      opt['label']?.toString() ??
                      '';
                  final normalizedType = type.toString().toLowerCase();
                  flat.add({
                    'id': opt['variation_item_id'] ?? opt['id'],
                    'type': normalizedType,
                    'label': label,
                    'value': label,
                    'price': opt['price'],
                    'stock': stock,
                    'is_available': opt['is_available'] ?? (stock > 0),
                    'image': opt['image'] ?? opt['image_url'],
                    if (normalizedType == 'color')
                      'color_hex': _colorNameToHex(label),
                  });
                }
              }
            }
          });
          data['variations'] = flat;
        } else if (rawVariations is! List) {
          data['variations'] = <Map<String, dynamic>>[];
        }

        final normalized = _normalizeProduct(data);

        final variations = normalized['variations'];
        if (variations is List) {
          normalized['variations'] = variations.map((v) {
            if (v is Map<String, dynamic>) {
              final parsedVariation = Map<String, dynamic>.from(v);
              parsedVariation['image_url'] = _absoluteAssetUrl(
                _firstStringValue(parsedVariation, [
                  'image_url',
                  'image',
                  'variation_image',
                  'image_path',
                ]),
              );
              return parsedVariation;
            }
            return v;
          }).toList();
        }

        // ── Re-apply rating/review fields that _normalizeProduct may not know about ──
        for (final key in [
          'average_rating',
          'total_reviews',
          'reviews',
          'rating_breakdown',
        ]) {
          if (data.containsKey(key)) normalized[key] = data[key];
        }

        return normalized;
      }

      _logError(
        'Product detail failed: ${response.statusCode} ${response.body}',
      );
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

  static Future<http.Response> _putJson(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}');
    _log('PUT $uri');
    _log('Request body: ${jsonEncode(body)}');
    final headers = authenticated ? await _authHeaders() : _jsonHeaders;
    return http
        .put(uri, headers: headers, body: jsonEncode(body))
        .timeout(_requestTimeout);
  }

  static Future<bool> updateCartItem({
    required int userId,
    required int productId,
    required int quantity,
    required int cartItemId,
  }) async {
    try {
      final response = await _putJson('/user/cart/update/$cartItemId', {
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

  // ─────────────────────────────────────────────
  //  Orders APIs
  // ─────────────────────────────────────────────

  static Future<int> getCartCount(int userId) async {
    final cart = await getCart(userId);
    return cart.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
  }

  static Future<Map<String, dynamic>> checkoutCart({
    required int userId,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required Map<String, dynamic> address,
  }) async {
    try {
      // Backend expects a comma-separated STRING of cart_item ids (not product ids)
      final cartItemIds = items
          .map((item) => item['cart_id'])
          .where((id) => id != null)
          .map((id) => id.toString())
          .toList();

      if (cartItemIds.isEmpty) {
        return {
          'success': false,
          'error': 'Could not identify cart items for checkout.',
        };
      }

      final line2 = (address['address_line_2']?.toString() ?? '').trim();
      final combinedAddress = line2.isEmpty
          ? address['address_line_1']
          : '${address['address_line_1']}, $line2';

      final body = <String, dynamic>{
        'items': cartItemIds.join(','),
        'first_name': address['first_name'],
        'last_name': address['last_name'],
        'email': address['email'],
        'phone': address['phone'],
        'address': combinedAddress,
        'city': address['city'],
        'state': address['state'],
        'postal_code': address['postal_code'],
        'country': address['country'] ?? 'India',
        'payment_method': paymentMethod,
      };
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
    required Map<String, dynamic> shippingAddress,
  }) {
    return checkoutCart(
      userId: userId,
      items: items,
      paymentMethod: paymentMethod,
      address: shippingAddress,
    );
  }

  static Future<Map<String, dynamic>> createRazorpayOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> address,
  }) async {
    try {
      final cartItemIds = items
          .map((item) => item['cart_id'])
          .where((id) => id != null)
          .map((id) => id.toString())
          .toList();

      if (cartItemIds.isEmpty) {
        return {'success': false, 'error': 'Could not identify cart items.'};
      }

      final line2 = (address['address_line_2']?.toString() ?? '').trim();
      final combinedAddress = line2.isEmpty
          ? address['address_line_1']
          : '${address['address_line_1']}, $line2';

      final body = <String, dynamic>{
        'items': cartItemIds.join(','),
        'first_name': address['first_name'],
        'last_name': address['last_name'],
        'email': address['email'],
        'phone': address['phone'],
        'address': combinedAddress,
        'city': address['city'],
        'state': address['state'],
        'postal_code': address['postal_code'],
        'country': address['country'] ?? 'India',
        'payment_method': 'razorpay',
      };
      _log('Razorpay create body: ${jsonEncode(body)}');
      final response = await _postJson(
        'user/orders/razorpay/create',
        body,
        authenticated: true,
      );
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
    required int localOrderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _postJson('user/orders/razorpay/verify', {
        'local_order_id': localOrderId,
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
        'user/addresses/',
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
      final response = await _postJson(
        '/addresses/create/',
        {
          // fix: correct path
          'user_id': userId,
          ...addressData,
        },
        authenticated: true,
      ); // fix: add auth, since it's presumably a protected user action
      if (response.statusCode == 201 || response.statusCode == 200) {
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

  // ─────────────────────────────────────────────
  //  Order Status METHODS
  // ─────────────────────────────────────────────

  static final StreamController<void> orderEvents =
      StreamController<void>.broadcast();

  static void _notifyOrdersChanged() => orderEvents.add(null);

  // ── Normalize one order JSON object from the DB into flat keys the
  // Flutter OrderModel expects. Adjust the key lists below if your
  // controller's json() / resource output uses different names. ──
  static Map<String, dynamic> _normalizeOrder(Map<String, dynamic> order) {
    final n = Map<String, dynamic>.from(order);

    n['status'] ??= _firstStringValue(n, ['order_status', 'status']);
    n['payment_method'] ??= _firstStringValue(n, ['payment_method']);
    n['total_amount'] ??= _firstStringValue(n, [
      'total',
      'total_amount',
      'grand_total',
    ]);
    n['total_items'] ??=
        n['total_items'] ??
        n['items_count'] ??
        (n['items'] is List
            ? (n['items'] as List).length
            : (n['order_items'] is List
                  ? (n['order_items'] as List).length
                  : 0));
    n['tracking_number'] ??= _firstStringValue(n, [
      'order_code',
      'tracking_number',
    ]);
    n['created_at'] ??= _firstStringValue(n, ['created_at']);

    // Address may come flat on the order OR nested under an `address`
    // relation (since your table stores address_id).
    final addr = n['address'];
    final addrMap = addr is Map<String, dynamic> ? addr : <String, dynamic>{};
    n['first_name'] ??=
        _firstStringValue(n, ['first_name']) ??
        _firstStringValue(addrMap, ['first_name']);
    n['last_name'] ??=
        _firstStringValue(n, ['last_name']) ??
        _firstStringValue(addrMap, ['last_name']);
    n['address_line_1'] ??=
        _firstStringValue(n, ['address_line_1', 'address']) ??
        _firstStringValue(addrMap, ['address_line_1', 'address']);
    n['address_line_2'] ??=
        _firstStringValue(n, ['address_line_2']) ??
        _firstStringValue(addrMap, ['address_line_2']);
    n['city'] ??=
        _firstStringValue(n, ['city']) ?? _firstStringValue(addrMap, ['city']);
    n['state'] ??=
        _firstStringValue(n, ['state']) ??
        _firstStringValue(addrMap, ['state']);
    n['postal_code'] ??=
        _firstStringValue(n, ['postal_code']) ??
        _firstStringValue(addrMap, ['postal_code']);
    n['country'] ??=
        _firstStringValue(n, ['country']) ??
        _firstStringValue(addrMap, ['country']);

    // Items: your relation might be called `items` or `order_items`,
    // and each row might nest the product under `product`.
    final rawItems = n['items'] ?? n['order_items'] ?? [];
    if (rawItems is List) {
      n['items'] = rawItems.map((raw) {
        if (raw is! Map<String, dynamic>) return raw;
        final item = Map<String, dynamic>.from(raw);
        final product = item['product'];
        final productMap = product is Map<String, dynamic>
            ? product
            : <String, dynamic>{};

        item['product_name'] ??=
            _firstStringValue(item, ['product_name', 'name']) ??
            _firstStringValue(productMap, ['product_name', 'name']);
        item['product_price'] ??=
            _firstStringValue(item, ['product_price', 'price', 'unit_price']) ??
            _firstStringValue(productMap, ['price', 'selling_price']);
        item['quantity'] ??= item['quantity'] ?? item['qty'] ?? 1;

        // ── Widened image lookup: same key variety as _normalizeProduct,
        // checked on the item itself, then on the nested product object ──
        const imageKeys = [
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
        ];
        String? image =
            _firstStringValue(item, imageKeys) ??
            _firstStringValue(productMap, imageKeys);

        // Fallback: first entry of a product's `images` array, if present
        if (image == null) {
          final images = productMap['images'] ?? item['images'];
          if (images is List && images.isNotEmpty) {
            final first = images.first;
            if (first is Map<String, dynamic>) {
              image = _firstStringValue(first, imageKeys);
            } else if (first is String) {
              image = first;
            }
          }
        }

        item['image_url'] = _absoluteAssetUrl(image);
        return item;
      }).toList();
    }

    return n;
  }

  /// Fetch the logged-in user's orders from the database.
  static Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      _log('Fetching orders');
      final response = await _getJson('/user/orders/', authenticated: true);
      _log('Orders: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = _decodeBody(response);
        final list = _listFromDecoded(decoded, [
          'data',
          'orders',
          'results',
          'items',
        ]);
        return list
            .whereType<Map<String, dynamic>>()
            .map(_normalizeOrder)
            .toList();
      }
      _logError('Get orders failed: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      _logError('Error fetching orders: $e');
      return [];
    }
  }

  /// Cancel an order in the database.
  static Future<bool> cancelOrderRequest(int orderId) async {
    try {
      final response = await _postJson(
        '/user/orders/$orderId/cancel',
        {},
        authenticated: true,
      );
      final ok = _isSuccessStatus(response.statusCode);
      if (ok) _notifyOrdersChanged();
      return ok;
    } catch (e) {
      _logError('Error cancelling order: $e');
      return false;
    }
  }

  /// Mark an order delivered in the database (usually an admin/courier
  /// action — keep only if your backend actually exposes this to users).
  static Future<bool> deliverOrderRequest(int orderId) async {
    try {
      final response = await _postJson(
        '/user/orders/$orderId/deliver',
        {},
        authenticated: true,
      );
      final ok = _isSuccessStatus(response.statusCode);
      if (ok) _notifyOrdersChanged();
      return ok;
    } catch (e) {
      _logError('Error marking order delivered: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  //  REVIEWS APIs
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> addReview({
    required int productId,
    required int rating,
    required String review,
  }) async {
    try {
      final response = await _postJson('/user/review/add', {
        'product_id': productId,
        'rating': rating,
        'review': review,
      }, authenticated: true);
      final data = _decodeBody(response);
      if (_isSuccessStatus(response.statusCode)) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'statusCode': response.statusCode,
        'error': _errorMessage(data, 'Could not submit review.'),
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Submits a new review for a product
  static Future<Map<String, dynamic>> submitReview({
    required int productId,
    required double rating,
    required String title,
    required String comment,
  }) async {
    try {
      _log('Submitting review for product ID: $productId');

      // Use '/user/review/add' without an 's' to match your working backend route
      final response = await _postJson(
        '/user/review/add',
        {
          'product_id': productId,
          'rating': rating,
          'title': title,
          'comment': comment,
        },
        authenticated: true, // Requires bearer token validation
      );

      _log('Submit review status: ${response.statusCode}');
      final data = _decodeBody(response);

      if (_isSuccessStatus(response.statusCode)) {
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'error': _errorMessage(data, 'Failed to submit review.'),
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } catch (e) {
      _logError('Error submitting review: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Fetches all reviews for a specific product
  /// Fetches all reviews for a specific product
  static Future<List<dynamic>> getProductReviews(int productId) async {
    try {
      _log('Fetching reviews for product ID: $productId');

      // FIX: Ensure this is calling your GET helper, not POST
      final response = await _getJson(
        '/user/review/product/$productId', // String interpolation fixes the %7BproductId%7D issue
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final decoded = _decodeBody(response);
        return _listFromDecoded(decoded, ['data', 'reviews']);
      }

      _logError('Failed to load reviews: ${response.statusCode}');
      return const <dynamic>[];
    } catch (e) {
      _logError('Error fetching product reviews: $e');
      return const <dynamic>[];
    }
  }

  static Future<List<dynamic>> getUserReviews() async {
    try {
      final response = await _getJson('/user/reviews', authenticated: true);
      if (response.statusCode == 200) {
        final decoded = _decodeBody(response);
        return _listFromDecoded(decoded, ['data', 'reviews', 'results']);
      }
      _logError(
        'Get user reviews failed: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      _logError('Error fetching user reviews: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> canReviewProduct(int productId) async {
    try {
      final orders = await getOrders();
      final reviews = await getProductReviews(productId);
      final currentUser = await getUser();

      // ── 1. Purchased + delivered? ──
      bool purchased = false;
      for (final order in orders) {
        final status = (order['status'] ?? '').toString().toLowerCase();
        if (status != 'delivered') continue;

        final items = order['items'];
        if (items is! List) continue;

        for (final item in items) {
          if (item is! Map) continue;
          final nestedProduct = item['product'];
          final rawId =
              item['product_id'] ??
              (nestedProduct is Map ? nestedProduct['id'] : null);
          final itemProductId = int.tryParse(rawId?.toString() ?? '');
          if (itemProductId == productId) {
            purchased = true;
            break;
          }
        }
        if (purchased) break;
      }

      // ── 2. Already reviewed? ──
      bool alreadyReviewed = false;
      final currentUserId = currentUser?['id']?.toString();
      if (currentUserId != null) {
        for (final r in reviews) {
          if (r is! Map) continue;
          final reviewUserId =
              (r['user_id'] ??
                      r['reviewer_id'] ??
                      r['customer_id'] ??
                      (r['user'] is Map ? r['user']['id'] : null))
                  ?.toString();
          if (reviewUserId != null && reviewUserId == currentUserId) {
            alreadyReviewed = true;
            break;
          }
        }
      }

      return {
        'success': true,
        'canReview': purchased && !alreadyReviewed,
        'alreadyReviewed': alreadyReviewed,
      };
    } catch (e) {
      _logError('Error checking review eligibility: $e');
      return {
        'success': false,
        'canReview': false,
        'alreadyReviewed': false,
        'error': 'Network error: $e',
      };
    }
  }
}
