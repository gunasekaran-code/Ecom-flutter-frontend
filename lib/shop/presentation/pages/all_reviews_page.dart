import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';
import 'package:wss_sports/utils/review_data.dart';

const Color _kRatingGreen = Color(0xFF1DB954);

enum _SortOption { mostHelpful, latest, positive, negative }

class AllReviewsPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const AllReviewsPage({super.key, required this.product});

  @override
  State<AllReviewsPage> createState() => _AllReviewsPageState();
}

class _AllReviewsPageState extends State<AllReviewsPage> {
  _SortOption _sort = _SortOption.mostHelpful;

  List<Map<String, dynamic>> get _sortedReviews {
    final reviews = List<Map<String, dynamic>>.from(
      ReviewData.reviewsOf(widget.product),
    );
    switch (_sort) {
      case _SortOption.mostHelpful:
        reviews.sort(
          (a, b) =>
              ReviewData.helpfulCount(b).compareTo(ReviewData.helpfulCount(a)),
        );
        break;
      case _SortOption.latest:
        reviews.sort((a, b) => ReviewData.date(b).compareTo(ReviewData.date(a)));
        break;
      case _SortOption.positive:
        reviews.sort(
          (a, b) => ReviewData.rating(b).compareTo(ReviewData.rating(a)),
        );
        break;
      case _SortOption.negative:
        reviews.sort(
          (a, b) => ReviewData.rating(a).compareTo(ReviewData.rating(b)),
        );
        break;
    }
    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final rating = ReviewData.averageRating(product);
    final total = ReviewData.totalReviews(product);
    final reviews = ReviewData.reviewsOf(product);
    final breakdown = ReviewData.ratingBreakdown(product);
    final images = ReviewData.allReviewImages(product);
    final sorted = _sortedReviews;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: kBackground,
        iconTheme: const IconThemeData(color: kTextDark),
        titleSpacing: 0,
        title: const Text(
          'All Reviews',
          style: TextStyle(
            color: kTextDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Summary row: stars + rating count | breakdown bars ─────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < rating.round();
                      return Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: filled ? _kRatingGreen : kBorder,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$total ratings and ${reviews.length} reviews',
                    style: const TextStyle(color: kTextMuted, fontSize: 12.5),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                children: [5, 4, 3, 2, 1].map((star) {
                  final count = breakdown[star] ?? 0;
                  final maxCount = breakdown.values.isEmpty
                      ? 1
                      : breakdown.values.reduce((a, b) => a > b ? a : b);
                  final ratio = maxCount == 0 ? 0.0 : count / maxCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: const TextStyle(
                            color: kTextMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: kTextMuted,
                        ),
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 110,
                            height: 6,
                            child: Stack(
                              children: [
                                Container(color: kBorder),
                                FractionallySizedBox(
                                  widthFactor: ratio.clamp(0.0, 1.0),
                                  child: Container(color: _kRatingGreen),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 34,
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: kTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          if (images.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    images[index],
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 76,
                      height: 76,
                      color: kSurface,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: kTextMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(color: kBorder, height: 1),
          const SizedBox(height: 16),

          const Text(
            'User reviews sorted by',
            style: TextStyle(
              color: kTextDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _SortChip(
                  label: 'Most Helpful',
                  selected: _sort == _SortOption.mostHelpful,
                  onTap: () => setState(() => _sort = _SortOption.mostHelpful),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Latest',
                  selected: _sort == _SortOption.latest,
                  onTap: () => setState(() => _sort = _SortOption.latest),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Positive',
                  selected: _sort == _SortOption.positive,
                  onTap: () => setState(() => _sort = _SortOption.positive),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Negative',
                  selected: _sort == _SortOption.negative,
                  onTap: () => setState(() => _sort = _SortOption.negative),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No reviews yet', style: TextStyle(color: kTextMuted)),
              ),
            )
          else
            ...sorted.map((r) => _ReviewCard(review: r)),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kBrandRedSoft : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? kBrandRed : kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? kBrandRed : kTextMuted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final rating = ReviewData.rating(r);
    final title = ReviewData.title(r);
    final comment = ReviewData.comment(r);
    final variation = ReviewData.variationLabel(r);
    final name = ReviewData.reviewerName(r);
    final verified = ReviewData.isVerified(r);
    final date = ReviewData.date(r);
    final helpful = ReviewData.helpfulCount(r);
    final notHelpful = ReviewData.notHelpfulCount(r);

    final isLong = comment.length > 160;
    final displayComment =
        (_expanded || !isLong) ? comment : '${comment.substring(0, 160)}...';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (i) {
                  final filled = i < rating.round();
                  return Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: filled ? _kRatingGreen : kBorder,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: kTextDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (title.isNotEmpty) ...[
                const Text(' · ', style: TextStyle(color: kTextMuted)),
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
          if (variation != null && variation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Review for: $variation',
              style: const TextStyle(color: kTextMuted, fontSize: 12),
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: kTextDark,
                  fontSize: 14,
                  height: 1.45,
                ),
                children: [
                  TextSpan(text: displayComment),
                  if (isLong)
                    TextSpan(
                      text: _expanded ? ' less' : ' more',
                      style: const TextStyle(
                        color: kBrandRed,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => setState(() => _expanded = !_expanded),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: kTextDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.thumb_up_alt_outlined, size: 14, color: kTextMuted),
              const SizedBox(width: 3),
              Text(
                'Helpful for $helpful',
                style: const TextStyle(color: kTextMuted, fontSize: 12),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.thumb_down_alt_outlined, size: 14, color: kTextMuted),
              const SizedBox(width: 3),
              Text('$notHelpful', style: const TextStyle(color: kTextMuted, fontSize: 12)),
              const Spacer(),
              if (verified) ...[
                const Icon(Icons.verified, size: 13, color: kTextMuted),
                const SizedBox(width: 3),
              ],
              Text(
                verified ? 'Verified Purchase · $date' : date,
                style: const TextStyle(color: kTextMuted, fontSize: 11.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}