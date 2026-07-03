import 'package:wss_sports/utils/product_data.dart';

class ReviewData {
  ReviewData._();

  // ── Aggregate (product-level) helpers ─────────────────────────────

  static double averageRating(Map<String, dynamic> product) {
    final v = double.tryParse(product['average_rating']?.toString() ?? '');
    if (v != null) return v;
    return ProductData.rating(product);
  }

  static int totalReviews(Map<String, dynamic> product) {
    final v = int.tryParse(
      product['total_reviews']?.toString() ??
          product['reviews_count']?.toString() ??
          '',
    );
    if (v != null) return v;
    return reviewsOf(product).length;
  }

  static List<Map<String, dynamic>> reviewsOf(Map<String, dynamic> product) {
    final raw = product['reviews'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Star -> count map (5 down to 1). Uses backend breakdown if present,
  /// otherwise computes it from the review list.
  static Map<int, int> ratingBreakdown(Map<String, dynamic> product) {
    final breakdown = product['rating_breakdown'];
    if (breakdown is Map) {
      final Map<int, int> result = {for (var i = 5; i >= 1; i--) i: 0};
      breakdown.forEach((k, v) {
        final star = int.tryParse(k.toString());
        final count = int.tryParse(v.toString()) ?? 0;
        if (star != null && star >= 1 && star <= 5) result[star] = count;
      });
      return result;
    }

    final Map<int, int> result = {for (var i = 5; i >= 1; i--) i: 0};
    for (final r in reviewsOf(product)) {
      final star = rating(r).round().clamp(1, 5);
      result[star] = (result[star] ?? 0) + 1;
    }
    return result;
  }

  /// Flattened list of all review image URLs — used for the photo strip.
  static List<String> allReviewImages(Map<String, dynamic> product) {
    final List<String> urls = [];
    for (final r in reviewsOf(product)) {
      urls.addAll(images(r));
    }
    return urls;
  }

  static String ratingLabel(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.0) return 'Good';
    if (rating >= 2.0) return 'Fair';
    return 'Poor';
  }

  // ── Per-review helpers ──────────────────────────────────────────────

  static int id(Map<String, dynamic> r) =>
      int.tryParse(r['id']?.toString() ?? '') ?? 0;

  static double rating(Map<String, dynamic> r) =>
      double.tryParse(
        r['rating']?.toString() ?? r['star']?.toString() ?? '',
      ) ??
      0;

  static String title(Map<String, dynamic> r) =>
      r['title']?.toString() ?? r['heading']?.toString() ?? '';

  static String comment(Map<String, dynamic> r) =>
      r['comment']?.toString() ??
      r['review']?.toString() ??
      r['text']?.toString() ??
      r['description']?.toString() ??
      '';

  static String reviewerName(Map<String, dynamic> r) {
    final user = r['user'];
    if (user is Map && user['name'] != null) return user['name'].toString();
    return r['reviewer_name']?.toString() ??
        r['user_name']?.toString() ??
        r['name']?.toString() ??
        'Anonymous';
  }

  static bool isVerified(Map<String, dynamic> r) =>
      r['is_verified'] == true ||
      r['verified_purchase'] == true ||
      r['is_verified_buyer'] == true;

  static String date(Map<String, dynamic> r) =>
      r['created_at']?.toString() ??
      r['date']?.toString() ??
      r['review_date']?.toString() ??
      '';

  /// e.g. "Color White" — the variation the reviewer purchased.
  static String? variationLabel(Map<String, dynamic> r) =>
      r['variation']?.toString() ?? r['variation_label']?.toString();

  static int helpfulCount(Map<String, dynamic> r) =>
      int.tryParse(
        r['helpful_count']?.toString() ?? r['likes']?.toString() ?? '',
      ) ??
      0;

  static int notHelpfulCount(Map<String, dynamic> r) =>
      int.tryParse(
        r['not_helpful_count']?.toString() ?? r['dislikes']?.toString() ?? '',
      ) ??
      0;

  static List<String> images(Map<String, dynamic> r) {
    final raw = r['images'] ?? r['photos'];
    if (raw is List) {
      return raw
          .map((e) => ProductData.assetUrl(e?.toString()))
          .whereType<String>()
          .toList();
    }
    return [];
  }
}