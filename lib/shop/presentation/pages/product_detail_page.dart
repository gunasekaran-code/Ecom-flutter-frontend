import 'package:flutter/material.dart';
import 'package:ecom_app/models/product_model.dart';
import 'package:ecom_app/services/api_service.dart';
import 'package:ecom_app/services/cart_service.dart';
import 'package:ecom_app/shop/presentation/pages/cart_page.dart';

const Color kBrandRed = Color(0xFFE4252A);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);
const Color kBackground = Colors.white;
const Color kSurface = Color(0xFFF7F7F7);
const Color kBorder = Color(0xFFEAEAEA);

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final Product? initialProduct;
  final Map<String, dynamic> userData;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.initialProduct,
    required this.userData,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? product;
  bool isLoading = true;
  bool isAddingToCart = false;
  int currentImageIndex = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    product = widget.initialProduct;
    fetchData();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    if (widget.initialProduct != null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    product = await ApiService.getProductDetail(widget.productId);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _addToCart() async {
    final currentProduct = product;
    if (currentProduct == null || isAddingToCart) {
      return;
    }

    setState(() => isAddingToCart = true);

    CartService().addLocalProduct(currentProduct);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart!'),
        backgroundColor: Color(0xFF1DB954),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(userId: widget.userData['id']),
      ),
    );

    setState(() => isAddingToCart = false);

    final synced = await ApiService.addToCart(
      userId: widget.userData['id'],
      productId: currentProduct.id,
    ).timeout(const Duration(seconds: 2), onTimeout: () => false);

    if (synced && CartService().isInLocalCart(currentProduct.id)) {
      CartService().removeLocalProduct(currentProduct.id);
      CartService().notifyCartChange(
        CartChangeEvent(productId: currentProduct.id, isAdded: true),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kBackground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: kBackground,
      iconTheme: const IconThemeData(color: kTextDark),
      title: const Text(
        'Product Details',
        style: TextStyle(
          color: kBrandRed,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: kBackground,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: kBrandRed, strokeWidth: 2.5),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        backgroundColor: kBackground,
        appBar: _buildAppBar(),
        body: const Center(
          child: Text(
            'Product not found',
            style: TextStyle(color: kTextMuted, fontSize: 16),
          ),
        ),
      );
    }

    final imageList = product!.images.isNotEmpty
        ? product!.images
        : [if (product!.imageUrl != null) product!.imageUrl!];

    return Scaffold(
      backgroundColor: kBackground,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            if (imageList.isNotEmpty)
              Column(
                children: [
                  Container(
                    color: kSurface,
                    child: SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: imageList.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Image.network(
                              imageList[index],
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  color: kSurface,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 64,
                                    color: kTextMuted,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Page indicator dots
                  if (imageList.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imageList.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: currentImageIndex == index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: currentImageIndex == index
                                ? kBrandRed
                                : kBorder,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Thumbnails
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageList.length,
                        itemBuilder: (context, index) {
                          final isSelected = currentImageIndex == index;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? kBrandRed : kBorder,
                                    width: isSelected ? 1.6 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.network(
                                    imageList[index],
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 68,
                                        height: 68,
                                        color: kSurface,
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 24,
                                          color: kTextMuted,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                height: 340,
                color: kSurface,
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: kTextMuted,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kBrandRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product!.category.toUpperCase(),
                      style: const TextStyle(
                        color: kBrandRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Product Name
                  Text(
                    product!.name,
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product!.rating.toString(),
                        style: const TextStyle(
                          color: kTextDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '· Rating',
                        style: TextStyle(color: kTextMuted, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${product!.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: kTextDark,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Stock Status
                  Row(
                    children: [
                      Icon(
                        product!.isInStock
                            ? Icons.check_circle
                            : Icons.cancel_outlined,
                        color: product!.isInStock
                            ? const Color(0xFF1DB954)
                            : kBrandRed,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        product!.isInStock
                            ? 'In Stock (${product!.stock} units)'
                            : 'Out of Stock',
                        style: const TextStyle(
                          color: kTextMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  const Divider(color: kBorder, height: 1),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: kTextDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product!.description,
                    style: const TextStyle(
                      color: kTextMuted,
                      fontSize: 14.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: product!.isInStock ? _addToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: kBorder,
                        disabledForegroundColor: kTextMuted,
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                      label: Text(
                        product!.isInStock
                            ? isAddingToCart
                                  ? 'Adding...'
                                  : 'Add to Cart'
                            : 'Out of Stock',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
