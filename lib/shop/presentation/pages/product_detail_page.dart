import 'package:flutter/material.dart';
import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/services/cart_service.dart';
import 'package:wss_sports/shop/presentation/pages/cart_page.dart';
import 'package:wss_sports/shop/presentation/widgets/rating_reviews_sheet.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';
import 'package:wss_sports/utils/product_data.dart';
import 'package:wss_sports/utils/review_data.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final Map<String, dynamic>? initialProduct;
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
  Map<String, dynamic>? product;
  List<Map<String, dynamic>> relatedProducts = [];
  bool isLoading = true;
  bool isAddingToCart = false;
  int currentImageIndex = 0;
  late PageController pageController;

  Map<String, dynamic>? selectedVariation;

  // ── Live price / stock / availability ─────────────────────────────
  double get _displayPrice =>
      _variationPrice(selectedVariation) ?? ProductData.price(product!);
  int get _displayStock => selectedVariation == null
      ? ProductData.stock(product!)
      : _variationStock(selectedVariation!);
  bool get _displayInStock => selectedVariation != null
      ? _variationIsAvailable(selectedVariation!) &&
            _variationStock(selectedVariation!) > 0
      : ProductData.isInStock(product!);

  // ── Image list: prepends the variation image when one is selected ──
  // This drives the carousel so it jumps to the variation's image.
  List<String> get _displayImages {
    if (product == null) return [];
    final base = ProductData.images(product!);

    final varImage = _variationImage(selectedVariation);
    if (varImage != null && !base.contains(varImage)) {
      return [varImage, ...base];
    }
    return base;
  }

  // ── Related products ───────────────────────────────────────────────
  List<Map<String, dynamic>> get _relatedProducts {
    if (product == null) return [];
    return relatedProducts
        .where(
          (p) =>
              ProductData.category(p) == ProductData.category(product!) &&
              ProductData.id(p) != ProductData.id(product!),
        )
        .toList();
  }

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
    // Show the list-item data immediately while fetching the full detail.
    final freshDetailFuture = ApiService.getProductDetail(widget.productId);
    final relatedFuture = _fetchRelatedProducts();

    final freshDetail = await freshDetailFuture;
    await relatedFuture;
    if (!mounted) return;

    setState(() {
      // Prefer the fresh detail (has variations); fall back to initialProduct if the fetch failed.
      product = freshDetail ?? widget.initialProduct ?? product;
      isLoading = false;
    });
  }

  Future<void> _fetchRelatedProducts() async {
    relatedProducts = await ApiService.getProducts();
  }

  int _variationId(Map<String, dynamic> variation) =>
      int.tryParse(variation['id']?.toString() ?? '') ?? 0;

  String _variationType(Map<String, dynamic> variation) =>
      variation['type']?.toString() ??
      variation['variation_type']?.toString() ??
      'option';

  String _variationLabel(Map<String, dynamic> variation) =>
      variation['label']?.toString() ??
      variation['name']?.toString() ??
      variation['value']?.toString() ??
      '';

  double? _variationPrice(Map<String, dynamic>? variation) {
    if (variation == null) return null;
    return double.tryParse(variation['price']?.toString() ?? '');
  }

  int _variationStock(Map<String, dynamic> variation) =>
      int.tryParse(variation['stock']?.toString() ?? '') ?? 0;

  bool _variationIsAvailable(Map<String, dynamic> variation) {
    final value = variation['is_available'];
    if (value is bool) return value;
    return _variationStock(variation) > 0;
  }

  String? _variationColorHex(Map<String, dynamic> variation) =>
      variation['color_hex']?.toString();

  String? _variationImage(Map<String, dynamic>? variation) {
    if (variation == null) return null;
    final image =
        variation['image']?.toString() ?? variation['image_url']?.toString();
    return ProductData.assetUrl(image);
  }

  // ── Select / deselect a variation ─────────────────────────────────
  // Also resets the image carousel to page 0 so the variation image is visible.
  void _selectVariation(Map<String, dynamic>? v) {
    setState(() {
      selectedVariation = v;
      currentImageIndex = 0;
    });
    if (pageController.hasClients) {
      pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _addToCart() async {
    final currentProduct = product;
    if (currentProduct == null || isAddingToCart) return;
    final productId = ProductData.id(currentProduct);
    if (CartService().isInLocalCart(productId)) {
      showAppSnackBar(
        context,
        title: 'Info',
        message: 'This item is already in your cart',
        type: AppSnackBarType.info,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartPage(userId: widget.userData['id']),
        ),
      );
      return;
    }

    setState(() => isAddingToCart = true);
    final added = await CartService().addProduct(
      userId: widget.userData['id'],
      product: currentProduct,
    );
    if (!mounted) return;
    if (!added) {
      setState(() => isAddingToCart = false);
      showAppSnackBar(
        context,
        title: 'Error',
        message: ApiService.lastCartError ?? 'Could not add this item to cart',
        type: AppSnackBarType.error,
      );
      return;
    }
    showAppSnackBar(
      context,
      title: 'Success',
      message: 'Added to cart!',
      type: AppSnackBarType.success,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(userId: widget.userData['id']),
      ),
    );
    setState(() => isAddingToCart = false);
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

  // ─────────────────────────────────────────────────────────────────
  //  Chip builders
  // ─────────────────────────────────────────────────────────────────

  /// Color swatch chip — circle filled with [v.colorHex], check when selected,
  /// ✕ overlay when unavailable.
  Widget _buildColorChip(
    Map<String, dynamic> v,
    bool isSelected,
    bool isUnavailable,
  ) {
    final colorHex = _variationColorHex(v);
    final color = colorHex != null
        ? Color(int.parse(colorHex.replaceFirst('#', '0xFF')))
        : Colors.grey.shade400;

    return GestureDetector(
      onTap: isUnavailable
          ? null
          : () => _selectVariation(isSelected ? null : v),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: isSelected ? kBrandRed : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: kBrandRed.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: isUnavailable
                ? const Icon(Icons.close_rounded, color: Colors.white, size: 18)
                : (isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null),
          ),
          const SizedBox(height: 5),
          Text(
            _variationLabel(v),
            style: TextStyle(
              color: isUnavailable
                  ? kTextMuted.withOpacity(0.4)
                  : (isSelected ? kBrandRed : kTextDark),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              decoration: isUnavailable ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Image-thumbnail chip — shows a small preview of [v.image] above the label.
  /// Used when a variation carries its own image (e.g. a colour-way or style).
  Widget _buildImageChip(
    Map<String, dynamic> v,
    bool isSelected,
    bool isUnavailable,
  ) {
    final image = _variationImage(v);
    return GestureDetector(
      onTap: isUnavailable
          ? null
          : () => _selectVariation(isSelected ? null : v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kBrandRed : kBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kBrandRed.withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
              child: Image.network(
                image!,
                width: 72,
                height: 64,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 64,
                  color: kSurface,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 22,
                    color: kTextMuted,
                  ),
                ),
              ),
            ),
            // Label bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? kBrandRed : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(11),
                ),
              ),
              child: Text(
                _variationLabel(v),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isUnavailable
                            ? kTextMuted.withOpacity(0.4)
                            : kTextDark),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  decoration: isUnavailable ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Plain text chip — the default for size, length, capacity, dpi, material.
  Widget _buildTextChip(
    Map<String, dynamic> v,
    bool isSelected,
    bool isUnavailable,
  ) {
    return GestureDetector(
      onTap: isUnavailable
          ? null
          : () => _selectVariation(isSelected ? null : v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? kBrandRed
              : (isUnavailable ? kBorder.withOpacity(0.3) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? kBrandRed : kBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kBrandRed.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          _variationLabel(v),
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isUnavailable ? kTextMuted.withOpacity(0.4) : kTextDark),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            decoration: isUnavailable ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Variation Selector
  // ─────────────────────────────────────────────────────────────────

  Widget _buildVariationSelector() {
    final variations = ProductData.variations(product ?? {});
    if (product == null || variations.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by type preserving insertion order
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final v in variations) {
      grouped.putIfAbsent(_variationType(v), () => []).add(v);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: kBorder, height: 1),
        const SizedBox(height: 20),

        ...grouped.entries.map((entry) {
          final type = entry.key;
          final options = entry.value;
          final displayLabel = type[0].toUpperCase() + type.substring(1);
          final isColorType = type == 'color';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section label row ──────────────────────────────────
              Row(
                children: [
                  Text(
                    displayLabel,
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Show selected value inline, e.g. "Size — XL"
                  if (selectedVariation != null &&
                      _variationType(selectedVariation!) == type) ...[
                    const SizedBox(width: 8),
                    Text(
                      '- ${_variationLabel(selectedVariation!)}',
                      style: const TextStyle(
                        color: kBrandRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // ── Chips ───────────────────────────────────────────────
              Wrap(
                spacing: isColorType ? 14 : 8,
                runSpacing: isColorType ? 14 : 8,
                children: options.map((v) {
                  final isSelected =
                      _variationId(selectedVariation ?? {}) == _variationId(v);
                  final isUnavailable =
                      !_variationIsAvailable(v) || _variationStock(v) == 0;

                  if (isColorType) {
                    // Always render color swatches for 'color' type
                    return _buildColorChip(v, isSelected, isUnavailable);
                  } else if (_variationImage(v) != null) {
                    // Render image-thumbnail chip when variation has its own image
                    return _buildImageChip(v, isSelected, isUnavailable);
                  } else {
                    // Default text chip
                    return _buildTextChip(v, isSelected, isUnavailable);
                  }
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          );
        }),

        // ── Info banner (shown when variation is selected) ───────────
        if (selectedVariation != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: kBrandRed.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBrandRed.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: kBrandRed, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _variationImage(selectedVariation!) != null
                        ? 'Preview updated for selected ${_variationType(selectedVariation!)}'
                        : 'Price updated for selected ${_variationType(selectedVariation!)}',
                    style: const TextStyle(
                      color: kBrandRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Related products ───────────────────────────────────────────────
  Widget _buildRelatedProducts() {
    final related = _relatedProducts;
    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: kBorder, height: 1),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You May Also Like',
                    style: TextStyle(
                      color: kTextDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'More in ${ProductData.category(product!).toUpperCase()}',
                    style: const TextStyle(color: kTextMuted, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kBrandRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${related.length} items',
                  style: const TextStyle(
                    color: kBrandRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: related.length,
            itemBuilder: (context, index) {
              final p = related[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(
                        productId: ProductData.id(p),
                        initialProduct: p,
                        userData: widget.userData,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                    boxShadow: [
                      BoxShadow(
                        color: kBrandRed.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: ProductData.image(p) != null
                            ? Image.network(
                                ProductData.image(p)!,
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.prefer,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 130,
                                  color: kBrandRedSoft,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: kBrandRed,
                                  ),
                                ),
                              )
                            : Container(
                                height: 130,
                                color: kBrandRedSoft,
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: kBrandRed,
                                  size: 32,
                                ),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ProductData.name(p),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kTextDark,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${ProductData.price(p).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: kBrandRed,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        ProductData.rating(p).toString(),
                                        style: const TextStyle(
                                          color: kTextMuted,
                                          fontSize: 11,
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
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: kBackground,
        appBar: _buildAppBar(),
        body: const ProductDetailSkeleton(),
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

    // _displayImages reacts to selectedVariation automatically.
    final imageList = _displayImages;

    // Cart button logic
    final variations = ProductData.variations(product!);
    final bool hasVariations = variations.isNotEmpty;
    final bool canAddToCart =
        _displayInStock && (!hasVariations || selectedVariation != null);

    String cartButtonLabel;
    if (!_displayInStock) {
      cartButtonLabel = 'Out of Stock';
    } else if (hasVariations && selectedVariation == null) {
      final firstType = _variationType(variations.first);
      cartButtonLabel =
          'Select ${firstType[0].toUpperCase()}${firstType.substring(1)}';
    } else if (isAddingToCart) {
      cartButtonLabel = 'Adding...';
    } else {
      cartButtonLabel = 'Add to Cart';
    }

    return Scaffold(
      backgroundColor: kBackground,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image carousel ────────────────────────────────────────
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
                        onPageChanged: (index) =>
                            setState(() => currentImageIndex = index),
                        itemBuilder: (context, index) {
                          final imageUrl = imageList[index];
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              webHtmlElementStrategy:
                                  WebHtmlElementStrategy.prefer,
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

                  // Dots indicator
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

                  // Thumbnail strip
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
                              onTap: () => pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
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
                                    webHtmlElementStrategy:
                                        WebHtmlElementStrategy.prefer,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 68,
                                      height: 68,
                                      color: kSurface,
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 24,
                                        color: kTextMuted,
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

            // ── Product info ──────────────────────────────────────────
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
                      ProductData.category(product!).toUpperCase(),
                      style: const TextStyle(
                        color: kBrandRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Product name
                  Text(
                    ProductData.name(product!),
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Price — animates when variation changes
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      '₹${_displayPrice.toStringAsFixed(2)}',
                      key: ValueKey(_displayPrice),
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Stock — animates when variation changes
                  Row(
                    children: [
                      Icon(
                        _displayInStock
                            ? Icons.check_circle
                            : Icons.cancel_outlined,
                        color: _displayInStock
                            ? const Color(0xFF1DB954)
                            : kBrandRed,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _displayInStock
                            ? 'In Stock (${_displayStock} units)'
                            : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _displayInStock
                              ? const Color(0xFF1DB954)
                              : kBrandRed,
                        ),
                      ),
                    ],
                  ),
                   const SizedBox(height: 15),

                  // ── Rating — now a tappable button that opens the
                  // "Ratings and reviews" popup. ────────────────────
                  GestureDetector(
                    onTap: () => showRatingReviewsSheet(context, product!),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ReviewData.averageRating(product!).toStringAsFixed(1),
                          style: const TextStyle(
                            color: kTextDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${ReviewData.totalReviews(product!)} Ratings',
                          style: const TextStyle(
                            color: kTextMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right,
                          color: kTextMuted,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Variation Selector ────────────────────────────
                  _buildVariationSelector(),

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
                    ProductData.description(product!),
                    style: const TextStyle(
                      color: kTextMuted,
                      fontSize: 14.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Add to Cart button ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: canAddToCart ? _addToCart : null,
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
                      icon: Icon(
                        hasVariations &&
                                selectedVariation == null &&
                                _displayInStock
                            ? Icons.touch_app_outlined
                            : Icons.shopping_cart_outlined,
                        size: 20,
                      ),
                      label: Text(
                        cartButtonLabel,
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

            // ── Related products ──────────────────────────────────────
            _buildRelatedProducts(),
          ],
        ),
      ),
    );
  }
}
