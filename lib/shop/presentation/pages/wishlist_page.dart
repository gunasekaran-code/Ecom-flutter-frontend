import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ecom_app/models/product_model.dart';
import 'package:ecom_app/services/cart_service.dart';
import 'package:ecom_app/services/wishlist_service.dart';
import 'package:ecom_app/shop/presentation/pages/home_page.dart';
import 'package:ecom_app/shop/presentation/pages/cart_page.dart';
import 'package:ecom_app/shop/presentation/pages/product_detail_page.dart';
import 'package:ecom_app/shared/widgets/shared_ui.dart';

class WishlistPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onContinueShopping;

  const WishlistPage({
    super.key,
    required this.userData,
    this.onContinueShopping,
  });

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Map<String, dynamic>> wishlistItems = [];
  bool isLoading = true;
  late StreamSubscription<WishlistChangeEvent> _wishlistSubscription;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
    _listenToWishlistChanges();
  }

  void _listenToWishlistChanges() {
    _wishlistSubscription = WishlistService().wishlistChangeStream.listen((
      event,
    ) {
      if (!mounted) return;
      _loadWishlist();
    });
  }

  @override
  void dispose() {
    _wishlistSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadWishlist() async {
    final localItems = WishlistService().localWishlistProducts
        .map((product) => product.toWishlistItem())
        .toList();

    setState(() {
      wishlistItems = localItems;
      isLoading = false;
    });
  }

  Future<void> _removeFromWishlist(int productId) async {
    WishlistService().removeLocalProduct(productId);
    setState(() {
      wishlistItems.removeWhere((item) => item['product_id'] == productId);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kBrandRed,
          content: const Text(
            'Removed from wishlist',
            style: TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
    // } catch (e) {
    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(backgroundColor: kBrandRed, content: Text('Error: $e')),
    //     );
    //   }
    // }
  }

  Future<void> _moveToCart(Map<String, dynamic> item) async {
    final productId = item['product_id'] as int;
    try {
      final product = Product(
        id: productId,
        name: item['product_name'] ?? 'Product',
        description: item['description'] ?? '',
        price: double.tryParse(item['price'].toString()) ?? 0,
        category: item['category'] ?? 'Unknown',
        imageUrl: item['image'],
        images: [
          if (item['image'] != null && item['image'].toString().isNotEmpty)
            item['image'].toString(),
        ],
        stock: (item['stock'] as num?)?.toInt() ?? 1,
        rating: double.tryParse(item['rating'].toString()) ?? 0,
        delFlag: false,
        isInStock: item['is_in_stock'] ?? true,
        createdAt: DateTime.now().toIso8601String(),
      );

      if (!product.isInStock || product.stock < 1) {
        throw 'This product is currently out of stock.';
      }

      CartService().addLocalProduct(product);

      const removed = true;

      if (removed) {
        setState(() {
          wishlistItems.removeWhere(
            (wishlistItem) => wishlistItem['product_id'] == productId,
          );
        });
        WishlistService().removeLocalProduct(productId);
      }

      CartService().notifyCartChange(
        CartChangeEvent(productId: productId, isAdded: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green, // Success is usually green, not red!
            content: const Text(
              'Moved to cart',
              style: TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CartPage(userId: widget.userData['id']),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // 2. Clean up the error string so it doesn't say "Error: Exception: ..."
        String errorMessage = e.toString();

        // Remove the "Exception: " prefix if Dart adds it
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        } else if (errorMessage.startsWith('Error: ')) {
          errorMessage = errorMessage.replaceFirst('Error: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kBrandRed,
            content: Text(
              errorMessage,
            ), // Now it will cleanly say "This product is currently out of stock."
            duration: const Duration(
              seconds: 2,
            ), // Added a duration so it dismisses
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          color: kBgLight,
          child: AppBar(
            toolbarHeight: 90,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            iconTheme: const IconThemeData(color: kBrandRed),
            title: Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Wishlist',
                    style: TextStyle(
                      color: kBrandRed,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wishlistItems.isEmpty
                        ? "No saved items yet. Start exploring 🛍️"
                        : "You have ${wishlistItems.length} saved item${wishlistItems.length > 1 ? 's' : ''}",
                    style: const TextStyle(
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kBrandRed))
          : wishlistItems.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              color: kBrandRed,
              backgroundColor: Colors.white,
              onRefresh: _loadWishlist,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: wishlistItems.length,
                itemBuilder: (context, index) {
                  final item = wishlistItems[index];
                  return WishlistItemCard(
                    item: item,
                    userData: widget.userData,
                    onRemove: () => _removeFromWishlist(item['product_id']),
                    onMoveToCart: () => _moveToCart(item),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              color: kBrandRedSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 70,
              color: kBrandRed,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Wishlist Yet',
            style: TextStyle(
              color: kTextDark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add products to your wishlist to see them here',
              style: TextStyle(color: kTextMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandRed,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              if (widget.onContinueShopping != null) {
                widget.onContinueShopping!();
                return;
              }

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HomePage(userData: widget.userData),
                ),
              );
            },
            child: const Text(
              'Continue Shopping',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WishlistItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> userData;
  final VoidCallback onRemove;
  final VoidCallback onMoveToCart;

  const WishlistItemCard({
    super.key,
    required this.item,
    required this.userData,
    required this.onRemove,
    required this.onMoveToCart,
  });

  @override
  Widget build(BuildContext context) {
    final product = _productFromWishlistItem(item);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productId: item['product_id'],
              initialProduct: product,
              userData: userData,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBrandRed.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: kBrandRed.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
                child: item['image'] != null
                    ? Image.network(
                        item['image'],
                        width: 110,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imageFallback(icon: Icons.image_not_supported),
                      )
                    : _imageFallback(icon: Icons.shopping_bag),
              ),

              // Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title + Category
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item['product_name'] ?? 'Product',
                                  style: const TextStyle(
                                    color: kTextDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: onRemove,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: kBrandRedSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(7),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: kBrandRed,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kBgLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: kBrandRed.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              item['category'] ?? 'N/A',
                              style: const TextStyle(
                                color: kTextMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Price + Rating row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kBrandRedSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '₹${double.parse(item['price'].toString()).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: kBrandRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kBgLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: kBrandRed.withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item['rating'].toString(),
                                  style: const TextStyle(
                                    color: kTextDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Move to Cart full-width button
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: onMoveToCart,
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Move to Cart',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBrandRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback({required IconData icon}) {
    return Container(
      width: 110,
      height: 140,
      color: kBrandRedSoft,
      child: Icon(icon, color: kBrandRed, size: 32),
    );
  }

  Product? _productFromWishlistItem(Map<String, dynamic> item) {
    final productId = item['product_id'];
    if (productId is! int) {
      return null;
    }

    for (final product in WishlistService().localWishlistProducts) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }
}
