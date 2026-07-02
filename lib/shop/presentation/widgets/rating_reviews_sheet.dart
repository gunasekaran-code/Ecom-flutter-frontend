import 'package:flutter/material.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';
import 'package:wss_sports/shop/presentation/pages/all_reviews_page.dart';
import 'package:wss_sports/utils/review_data.dart';

const Color _kRatingGreen = Color(0xFF1DB954);
const Color _kRatingGreenSoft = Color(0xFFE9FBF1);

/// Bottom-sheet popup shown when the user taps the rating row on the
/// product detail page. Mirrors the "Ratings and reviews" sheet design.
Future<void> showRatingReviewsSheet(
  BuildContext context,
  Map<String, dynamic> product,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RatingReviewsSheet(product: product),
  );
}

class _RatingReviewsSheet extends StatelessWidget {
  final Map<String, dynamic> product;
  const _RatingReviewsSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final rating = ReviewData.averageRating(product);
    final total = ReviewData.totalReviews(product);
    final reviews = ReviewData.reviewsOf(product);
    final images = ReviewData.allReviewImages(product);
    final label = ReviewData.ratingLabel(rating);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ratings and reviews',
                      style: TextStyle(
                        color: kTextDark,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: kTextDark),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: kTextDark,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          color: _kRatingGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _kRatingGreenSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: _kRatingGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'based on $total ratings by ',
                          style: const TextStyle(
                            color: kTextMuted,
                            fontSize: 13,
                          ),
                        ),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: kTextMuted,
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          'Verified Buyers',
                          style: TextStyle(color: kTextMuted, fontSize: 13),
                        ),
                      ],
                    ),

                    if (images.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 84,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length > 8 ? 8 : images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final isLast = index == 7 && images.length > 8;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  Image.network(
                                    images[index],
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 84,
                                      height: 84,
                                      color: kSurface,
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: kTextMuted,
                                      ),
                                    ),
                                  ),
                                  if (isLast)
                                    Container(
                                      width: 84,
                                      height: 84,
                                      color: Colors.black.withOpacity(0.45),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '+${images.length - 7}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    const Divider(color: kBorder, height: 1),
                    const SizedBox(height: 12),

                    ...reviews.take(2).map((r) => _ReviewPreviewTile(review: r)),

                    if (reviews.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text(
                            'No reviews yet',
                            style: TextStyle(color: kTextMuted),
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AllReviewsPage(product: product),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: kBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Show all reviews',
                              style: TextStyle(
                                color: kTextDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right,
                              color: kTextDark,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewPreviewTile extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewPreviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = ReviewData.rating(review);
    final title = ReviewData.title(review);
    final comment = ReviewData.comment(review);
    final name = ReviewData.reviewerName(review);
    final helpful = ReviewData.helpfulCount(review);
    final notHelpful = ReviewData.notHelpfulCount(review);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _kRatingGreen,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ],
                ),
              ),
              if (title.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: kTextDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kTextMuted,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(name, style: const TextStyle(color: kTextMuted, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.thumb_up_outlined, size: 14, color: kTextMuted),
              const SizedBox(width: 3),
              Text('$helpful', style: const TextStyle(color: kTextMuted, fontSize: 12)),
              const SizedBox(width: 10),
              const Icon(Icons.thumb_down_outlined, size: 14, color: kTextMuted),
              const SizedBox(width: 3),
              Text('$notHelpful', style: const TextStyle(color: kTextMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}