import 'package:flutter/material.dart';
import 'package:wss_sports/core/localization/app_strings.dart';
import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/services/wishlist_service.dart';
import 'package:wss_sports/services/cart_service.dart';
import 'package:wss_sports/shop/presentation/pages/product_detail_page.dart';
import 'package:wss_sports/shop/presentation/pages/cart_page.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';
import 'package:wss_sports/utils/product_data.dart';
import 'dart:async';

const List<Map<String, dynamic>> fallbackCategories = [
  {'id': 0, 'name': 'all', 'display_name': 'All'},
  {'id': null, 'name': 'weapons', 'display_name': 'Weapons'},
  {'id': null, 'name': 'sports', 'display_name': 'Uniforms'},
  {'id': null, 'name': 'accessories', 'display_name': 'Accessories'},
];

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  String selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int cartCount = 0;

  final PageController _carouselController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  late StreamSubscription<CartChangeEvent> _cartSubscription;

  List<Map<String, dynamic>> categories = [];

  String _categoryQueryValue(Map<String, dynamic> category) {
    if ((category['name']?.toString() ?? '').toLowerCase() == 'all') {
      return 'all';
    }

    // Always use category ID for API filtering
    final categoryId = category['id'];
    if (categoryId != null) {
      return categoryId.toString();
    }

    // Fallback (should not happen if categories are loaded correctly)
    return category['name']?.toString().trim() ?? '';
  }

  String _categoryLabel(Map<String, dynamic> category) {
    final displayName = category['display_name']?.toString().trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    return category['name']?.toString().trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchCartCount();
    _fetchCategories();
    _searchController.addListener(_onSearchChanged);
    _startCarouselTimer();
    _cartSubscription = CartService().cartChangeStream.listen((event) {
      fetchCartCount();
    });
  }

  Future<void> _fetchCategories() async {
    // Keep static categories as a fallback while the API loads.
    setState(() {
      categories = fallbackCategories;
    });

    final result = await ApiService.getCategories();
    if (!mounted || result['success'] != true) return;

    final data = result['data'];
    final apiCategories = data is List
        ? data.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    if (apiCategories.isEmpty) return;

    setState(() {
      categories = [
        {'id': 0, 'name': 'all', 'display_name': 'All'},
        ...apiCategories,
      ];
    });
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_carouselController.hasClients) return;
      final nextPage = (_currentCarouselIndex + 1) % 4;
      _carouselController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _cartSubscription.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    filteredProducts = products.where((product) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          ProductData.name(product).toLowerCase().contains(_searchQuery) ||
          ProductData.description(product).toLowerCase().contains(_searchQuery);
      return matchesSearch;
    }).toList();
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    final categoryFilter = selectedCategory.trim();
    final fetchedProducts = await ApiService.getProducts(
      category: categoryFilter == 'all' || categoryFilter.isEmpty
          ? null
          : categoryFilter,
    );

    if (!mounted) return;

    setState(() {
      products = fetchedProducts;
      _applyFilters();
      isLoading = false;
    });
  }

  Future<void> fetchCartCount() async {
    setState(() => cartCount = CartService().localCartCount);
  }

  Future<void> _showAllProducts() async {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    setState(() {
      selectedCategory = 'all';
      _searchQuery = '';
    });

    await fetchProducts();
  }

  Widget _buildHomePage() {
    final strings = context.strings;

    return Column(
      children: [
        // Fixed Header (doesn't scroll)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.discover,
                    style: TextStyle(
                      color: kBrandRed,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    strings.welcomeUser(
                      widget.userData['full_name']?.toString() ?? '',
                    ),
                    style: const TextStyle(fontSize: 13, color: kTextMuted),
                  ),
                ],
              ),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: kBrandRed,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CartPage(userId: widget.userData['id']),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kBrandRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        cartCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Scrollable Content
        Expanded(
          child: RefreshIndicator(
            color: kBrandRed,
            onRefresh: fetchProducts,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carousel
                      SizedBox(
                        height: 160,
                        child: PageView(
                          controller: _carouselController,
                          onPageChanged: (index) =>
                              setState(() => _currentCarouselIndex = index),
                          children: [
                            _buildCarouselItem(
                              'assets/images/image1.jpg',
                              'Mardani Khel',
                              'Maharashtra Weapon Art',
                            ),
                            _buildCarouselItem(
                              'assets/images/image2.jpg',
                              'Gatka',
                              'Traditional Sikh ',
                            ),
                            _buildCarouselItem(
                              'assets/images/image3.jpg',
                              'Thang-Ta',
                              'Manipuri Sword & Spear Art',
                            ),
                            _buildCarouselItem(
                              'assets/images/image4.jpg',
                              'Kalaripayattu',
                              'Ancient Kerala ',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final isActive = _currentCarouselIndex == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: isActive ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? kBrandRed
                                  : kBrandRed.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.02),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kBrandRed.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: kTextDark),
                            decoration: InputDecoration(
                              hintText: strings.searchProducts,
                              hintStyle: const TextStyle(color: kTextMuted),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: kBrandRed,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: kTextMuted,
                                      ),
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Categories
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              strings.categories,
                              style: TextStyle(
                                color: kTextDark,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showAllProducts,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    strings.seeAll,
                                    style: TextStyle(
                                      color: kBrandRed.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final categoryQueryValue = _categoryQueryValue(
                              category,
                            );
                            final isSelected =
                                selectedCategory == categoryQueryValue;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  onTap: () {
                                    setState(
                                      () =>
                                          selectedCategory = categoryQueryValue,
                                    );
                                    fetchProducts();
                                  },
                                  splashColor: kBrandRed.withOpacity(0.3),
                                  highlightColor: kBrandRed.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? kBrandRed
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? kBrandRed
                                            : Colors.black.withOpacity(0.08),
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: kBrandRed.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      child: Center(
                                        child: Text(
                                          categoryQueryValue == 'all'
                                              ? strings.allCategory
                                              : _categoryLabel(category),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : kTextDark,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Products Grid
                isLoading
                    ? const ProductGridSkeleton()
                    : filteredProducts.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: kBrandRed.withOpacity(0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? strings.noResultsFor(_searchQuery)
                                    : strings.noProductsFound,
                                style: const TextStyle(
                                  color: kTextMuted,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return ProductCard(
                              product: filteredProducts[index],
                              userData: widget.userData,
                            );
                          }, childCount: filteredProducts.length),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(String imagePath, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: kBrandRedSoft),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(0, 0, 0, 0),
                    const Color.fromARGB(255, 0, 0, 0).withOpacity(0.10),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              left: 18,
              right: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kBrandRed,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: SafeArea(child: _buildHomePage()),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic> userData;

  const ProductCard({super.key, required this.product, required this.userData});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isInWishlist = false;
  late StreamSubscription<WishlistChangeEvent> _wishlistSubscription;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
    _wishlistSubscription = WishlistService().wishlistChangeStream.listen((
      event,
    ) {
      if (event.productId == ProductData.id(widget.product)) {
        setState(() {
          _isInWishlist = event.isAdded;
        });
      }
    });
  }

  Future<void> _checkWishlistStatus() async {
    setState(() {
      _isInWishlist = WishlistService().isInLocalWishlist(
        ProductData.id(widget.product),
      );
    });
  }

  Future<void> _toggleWishlist() async {
    if (_isInWishlist) {
      WishlistService().removeLocalProduct(ProductData.id(widget.product));
      setState(() => _isInWishlist = false);
      if (mounted) {
        showAppSnackBar(
          context,
          title: 'Info',
          message: context.strings.removedFromWishlist,
          type: AppSnackBarType.info,
          duration: const Duration(seconds: 1),
        );
      }

      return;
    }

    WishlistService().addLocalProduct(widget.product);
    setState(() => _isInWishlist = true);
    if (mounted) {
      showAppSnackBar(
        context,
        title: 'Success',
        message: context.strings.addedToWishlist,
        type: AppSnackBarType.success,
        duration: const Duration(seconds: 1),
      );
    }
  }

  @override
  void dispose() {
    _wishlistSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productId: ProductData.id(widget.product),
              initialProduct: widget.product,
              userData: widget.userData,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: kBrandRed.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: ProductData.image(widget.product) != null
                      ? Image.network(
                          ProductData.image(widget.product)!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                          errorBuilder: (_, _, _) => Container(
                            height: 160,
                            width: double.infinity,
                            color: kBrandRedSoft,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: kBrandRed,
                              size: 36,
                            ),
                          ),
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: kBrandRedSoft,
                          child: const Icon(
                            Icons.shopping_bag,
                            color: kBrandRed,
                            size: 36,
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _toggleWishlist,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: kBrandRed,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ProductData.name(widget.product),
                      style: const TextStyle(
                        color: kTextDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${ProductData.price(widget.product).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: kBrandRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              ProductData.rating(widget.product).toString(),
                              style: const TextStyle(
                                color: kTextMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
