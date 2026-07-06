import 'package:flutter/material.dart';
import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';

Future<bool> showWriteReviewSheet(
  BuildContext context, {
  required int productId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WriteReviewSheet(productId: productId),
  );
  return result ?? false;
}

class _WriteReviewSheet extends StatefulWidget {
  final int productId;
  const _WriteReviewSheet({required this.productId});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 0;
  final _controller = TextEditingController();
  bool _submitting = false;

  // ── Eligibility state ──
  bool _checkingEligibility = true;
  bool _eligible = false;
  String? _ineligibleMessage;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    final result = await ApiService.canReviewProduct(widget.productId);
    if (!mounted) return;
    setState(() {
      _checkingEligibility = false;
      _eligible = result['canReview'] == true;
      _ineligibleMessage = _eligible
          ? null
          : (result['error']?.toString() ??
                'Only verified buyers of a delivered order can review this product.');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_eligible) return; // guard, in case UI is somehow bypassed

    if (_rating == 0) {
      showAppSnackBar(
        context,
        title: 'Select a rating',
        message: 'Please tap a star to rate this product.',
        type: AppSnackBarType.error,
      );
      return;
    }
    if (_controller.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        title: 'Write a review',
        message: 'Please share a few words about the product.',
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await ApiService.addReview(
      productId: widget.productId,
      rating: _rating,
      review: _controller.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      showAppSnackBar(
        context,
        title: 'Thank you!',
        message: 'Your review has been submitted.',
        type: AppSnackBarType.success,
      );
      Navigator.pop(context, true);
    } else {
      showAppSnackBar(
        context,
        title: 'Could not submit review',
        message: result['error']?.toString() ?? 'Something went wrong.',
        type: AppSnackBarType.error,
      );
      if (result['statusCode'] == 403 || result['statusCode'] == 422) {
        // Backend disagrees with the client-side eligibility check
        // (e.g. already reviewed, or order status changed) — lock the form.
        setState(() {
          _eligible = false;
          _ineligibleMessage = result['error']?.toString() ??
              'You are not eligible to review this product.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Write a Review',
              style: TextStyle(color: kTextDark, fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Only verified buyers of a delivered order can review.',
              style: TextStyle(color: kTextMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 18),

            if (_checkingEligibility) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ] else if (!_eligible) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: kTextMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _ineligibleMessage ??
                            'Only verified buyers of a delivered order can review this product.',
                        style: const TextStyle(color: kTextMuted, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ] else ...[
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final filled = i < _rating;
                    return IconButton(
                      onPressed: () => setState(() => _rating = i + 1),
                      icon: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: filled ? const Color(0xFF1DB954) : kTextMuted,
                        size: 34,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this product...',
                  hintStyle: const TextStyle(color: kTextMuted, fontSize: 13.5),
                  filled: true,
                  fillColor: kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Submit Review',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}