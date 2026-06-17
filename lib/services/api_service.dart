import 'dart:async';
import 'dart:convert';
import 'package:wss_sports/models/product_model.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.12:8000/api';

  // Enable debug mode to see detailed logs
  static const bool debugMode = true;

  // Helper method to log debug info
  static void _log(String message) {
    if (debugMode) {
      print('🔵 [API] $message');
    }
  }

  // Helper method to log errors
  static void _logError(String message) {
    if (debugMode) {
      print('🔴 [API ERROR] $message');
    }
  }

  // Ping server to wake it up (useful for Render free tier)
  static Future<bool> pingServer() async {
    try {
      _log('Pinging server to wake it up...');
      final response = await http
          .get(Uri.parse('$baseUrl/products/'))
          .timeout(const Duration(seconds: 30));
      _log('Ping response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      _logError('Ping failed: $e');
      return false;
    }
  }

  // ============= USER APIs =============

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      _log('Attempting login to: $baseUrl/login/');
      _log('Email: $email');

      final requestBody = jsonEncode({'email': email, 'password': password});
      _log('Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl/login/'),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30)); // Increased timeout

      _log('Response status: ${response.statusCode}');
      _log('Response headers: ${response.headers}');
      _log('Response body: ${response.body}');

      // Handle empty response body
      if (response.body.isEmpty) {
        _logError('Empty response body received');
        return {
          'success': false,
          'error':
              'Server returned empty response. Status: ${response.statusCode}',
        };
      }

      try {
        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          _log('Login successful');
          return {'success': true, 'data': data};
        } else {
          _logError('Login failed with status: ${response.statusCode}');
          return {
            'success': false,
            'error':
                data['error'] ??
                data['detail'] ??
                'Login failed. Status: ${response.statusCode}',
          };
        }
      } catch (jsonError) {
        _logError('JSON parsing error: $jsonError');
        _logError('Raw response: ${response.body}');
        return {
          'success': false,
          'error':
              'Server error. Status: ${response.statusCode}\n${response.body}',
        };
      }
    } on TimeoutException catch (e) {
      _logError('Request timeout: $e');
      return {
        'success': false,
        'error':
            'Request timed out. The server might be starting up. Please try again.',
      };
    } catch (e) {
      _logError('Network error: $e');
      return {
        'success': false,
        'error': 'Network error: $e\nPlease check your connection.',
      };
    }
  }

  // Login with automatic server wake-up
  static Future<Map<String, dynamic>> loginUserWithWakeUp({
    required String email,
    required String password,
  }) async {
    _log('Attempting to wake up server before login...');
    await pingServer();
    await Future.delayed(Duration(seconds: 2)); // Give server time to start
    return loginUser(email: email, password: password);
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      _log('Requesting password reset for: $email');

      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password/'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      _log('Forgot password status: ${response.statusCode}');
      _log('Forgot password body: ${response.body}');

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'error':
            data['error'] ??
            data['detail'] ??
            data['message'] ??
            'Unable to send reset request.',
      };
    } on TimeoutException catch (e) {
      return {'success': false, 'error': 'Request timeout: $e'};
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
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'data': data};
      }

      return {'success': false, 'error': data['message'] ?? 'Reset failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      _log('Attempting registration to: $baseUrl/register');

      final requestBody = jsonEncode({
        'name': fullName,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      _log('Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body}');

      if (response.body.isEmpty) {
        return {'success': false, 'error': 'Empty response from server'};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data};
      }
    } on TimeoutException catch (e) {
      return {'success': false, 'error': 'Request timeout: $e'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
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

      final uri = Uri.parse('$baseUrl/users/partial/$id/');
      final request = http.MultipartRequest('PATCH', uri);

      if (fullName != null) {
        request.fields['full_name'] = fullName;
      }
      if (email != null) {
        request.fields['email'] = email;
      }
      if (phone != null) {
        request.fields['phone'] = phone;
      }
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

      _log('Update user response: ${response.statusCode}');
      _log('Response data: $responseData');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return {'success': true, 'data': data};
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

  // ============= PRODUCT APIs =============

  static Future<List<Product>> getProducts({String? category}) async {
    try {
      final uri = Uri.parse('$baseUrl/products/').replace(
        queryParameters: category != null && category.isNotEmpty
            ? {'category': category}
            : null,
      );

      _log('Fetching products from: $uri');
      final response = await http.get(uri);

      _log('Products response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        _log('Retrieved ${data.length} products');
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        _logError('Failed to fetch products: ${response.statusCode}');
        _logError('Products response body: ${response.body}');
      }
    } catch (e) {
      _logError('Error fetching products: $e');
    }
    return [];
  }

  static Future<List<Product>> getAllProductsAdmin() async {
    try {
      _log('Fetching all admin products');
      final response = await http.get(Uri.parse('$baseUrl/admin/products/'));

      _log('Admin products response: ${response.statusCode}');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        _logError('Admin products response body: ${response.body}');
      }
    } catch (e) {
      _logError('Error fetching admin products: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getUser({required int id}) async {
    try {
      _log('Fetching user profile for ID: $id');
      final response = await http.get(Uri.parse('$baseUrl/users/$id/'));
      _log('Get user response: ${response.statusCode}');
      _log('Get user body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : null;
      }
      return null;
    } catch (e) {
      _logError('Error fetching user profile: $e');
      return null;
    }
  }

  static Future<Product?> getProductDetail(int id) async {
    try {
      _log('Fetching product detail for ID: $id');
      final response = await http.get(Uri.parse('$baseUrl/products/$id/'));

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        _logError('Failed to fetch product detail: ${response.statusCode}');
      }
    } catch (e) {
      _logError('Error fetching product detail: $e');
    }
    return null;
  }

  static Future<bool> softDeleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/products/soft-delete/$id/'),
      );
      return response.statusCode == 200;
    } catch (e) {
      _logError('Error soft deleting product: $e');
      return false;
    }
  }

  static Future<bool> restoreProduct(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/products/restore/$id/'),
      );
      return response.statusCode == 200;
    } catch (e) {
      _logError('Error restoring product: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String description,
    required double price,
    required int categoryId,
    XFile? imageFile,
    required int stock,
    double rating = 0.0,
    int? skuId,
  }) async {
    try {
      _log('Creating product: $name');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/products/create/'),
      );

      // Add text fields
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['category'] = categoryId.toString();
      request.fields['stock'] = stock.toString();
      request.fields['rating'] = rating.toString();
      if (skuId != null) {
        request.fields['sku_id'] = skuId.toString();
      }

      // Add image file if selected
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ),
        );
        _log('Image attached: ${imageFile.name}');
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      _log('Create product response: ${response.statusCode}');
      _log('Response data: $responseData');

      if (response.statusCode == 201) {
        try {
          final data = jsonDecode(responseData);
          return {'success': true, 'data': data};
        } catch (e) {
          return {'success': true, 'data': responseData};
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: $responseData',
        };
      }
    } catch (e) {
      _logError('Error creating product: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProduct({
    required int id,
    required String name,
    required String description,
    required double price,
    required int categoryId,
    XFile? imageFile,
    required int stock,
    double rating = 0.0,
    int? skuId,
    bool removeImage = false,
  }) async {
    try {
      _log('Updating product ID: $id');

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/admin/products/update/$id/'),
      );

      // Add text fields
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['category'] = categoryId.toString();
      request.fields['stock'] = stock.toString();
      request.fields['rating'] = rating.toString();
      if (skuId != null) {
        request.fields['sku_id'] = skuId.toString();
      }
      if (removeImage) {
        request.fields['remove_image'] = 'true';
      }

      // Add image file if selected
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

      _log('Update product response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(responseData);
          return {'success': true, 'data': data};
        } catch (e) {
          return {'success': true, 'data': responseData};
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: $responseData',
        };
      }
    } catch (e) {
      _logError('Error updating product: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<bool> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "product_id": productId,
          "quantity": quantity,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      _logError('Error adding to cart: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getCart(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cart/$userId/'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
      final response = await http.put(
        Uri.parse('$baseUrl/cart/update/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "product_id": productId,
          "quantity": quantity,
        }),
      );
      return response.statusCode == 200;
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
      final response = await http.post(
        Uri.parse('$baseUrl/cart/remove/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": userId, "product_id": productId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      _logError('Error removing from cart: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> checkoutCart({
    required int userId,
    required List<int> productIds,
    int? addressId,
    Map<String, dynamic>? shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      final body = {
        'user_id': userId,
        'product_ids': productIds,
        'payment_method': paymentMethod,
      };

      if (addressId != null) {
        body['address_id'] = addressId;
      } else if (shippingAddress != null) {
        body['shipping_address'] = shippingAddress;
      }

      _log('Sending Checkout Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/cart/checkout/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('Checkout Successful');
        return {'success': true, 'data': decodedResponse};
      } else {
        _logError('Checkout Failed: ${response.body}');
        return {
          'success': false,
          'error': decodedResponse['error'] ?? 'Failed to checkout',
        };
      }
    } catch (e) {
      _logError('Checkout Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============= WISHLIST APIs =============

  static Future<List<dynamic>> getWishlist(int userId) async {
    // Backend disabled for static wishlist mode.
    // try {
    //   final response = await http.get(Uri.parse('$baseUrl/wishlist/$userId/'));
    //   if (response.statusCode == 200) {
    //     return jsonDecode(response.body);
    //   }
    // } catch (e) {
    //   _logError('Error fetching wishlist: $e');
    // }
    return [];
  }

  static Future<bool> addToWishlist({
    required int userId,
    required int productId,
  }) async {
    // Backend disabled for static wishlist mode.
    // try {
    //   final response = await http.post(
    //     Uri.parse('$baseUrl/wishlist/add/'),
    //     headers: {'Content-Type': 'application/json'},
    //     body: jsonEncode({"user_id": userId, "product_id": productId}),
    //   );
    //   return response.statusCode == 200 || response.statusCode == 201;
    // } catch (e) {
    //   _logError('Error adding to wishlist: $e');
    //   return false;
    // }
    return true;
  }

  static Future<bool> removeFromWishlist({
    required int userId,
    required int productId,
  }) async {
    // Backend disabled for static wishlist mode.
    // try {
    //   final response = await http.post(
    //     Uri.parse('$baseUrl/wishlist/remove/'),
    //     headers: {'Content-Type': 'application/json'},
    //     body: jsonEncode({"user_id": userId, "product_id": productId}),
    //   );
    //   return response.statusCode == 200;
    // } catch (e) {
    //   _logError('Error removing from wishlist: $e');
    //   return false;
    // }
    return true;
  }

  static Future<bool> isProductInWishlist({
    required int userId,
    required int productId,
  }) async {
    // Backend disabled for static wishlist mode.
    // try {
    //   final response = await http.get(
    //     Uri.parse('$baseUrl/wishlist/check/$userId/$productId/'),
    //   );
    //   if (response.statusCode == 200) {
    //     final data = jsonDecode(response.body);
    //     return data['is_in_wishlist'] ?? false;
    //   }
    // } catch (e) {
    //   _logError('Error checking wishlist: $e');
    // }
    return false;
  }

  static Future<int> getCartCount(int userId) async {
    final cart = await getCart(userId);
    int count = 0;
    for (var item in cart) {
      count += item['quantity'] as int;
    }
    return count;
  }

  static Future<double> getExchangeRate() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rates']['INR'] ?? 83.0;
      }
    } catch (e) {
      _logError('Error fetching exchange rate: $e');
    }
    return 83.0;
  }

  // ================= CATEGORY APIs =================

  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/categories/');
      _log('Fetching categories from: $uri');
      final response = await http.get(uri);
      _log('Categories response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error':
              'Categories endpoint not found on the server. Deploy the latest backend changes.',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
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
      _log('Creating category: $name');
      final response = await http.post(
        Uri.parse('$baseUrl/categories/create/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'display_name': displayName,
          'description': description ?? '',
        }),
      );

      _log('Create category response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error':
              'Create category endpoint not found on the server. Deploy the latest backend changes.',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      _logError('Error creating category: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    try {
      _log('Deleting category ID: $categoryId');
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/delete/$categoryId/'),
      );

      _log('Delete category response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error':
              'Delete category endpoint not found on the server. Deploy the latest backend changes.',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      _logError('Error deleting category: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserAddresses(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/addresses/?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to fetch addresses'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createAddress({
    required int userId,
    required Map<String, dynamic> addressData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addresses/create/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, ...addressData}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to create address'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteAddress({
    required int addressId,
    required int userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/addresses/$addressId/delete/?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to delete address'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
