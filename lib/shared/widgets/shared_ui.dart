import 'dart:ui';
import 'package:flutter/material.dart';

// ── Global Brand Colors ─────────────────────────────────────────────────────
const Color kBrandRed = Color(0xFFE4252A);
const Color kBrandRedDark = Color(0xFFB81E22);
const Color kBrandRedSoft = Color(0xFFFFE5E6);

const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);

const Color kBackground = Colors.white;
const Color kBg = Color(0xFFF5F5F5);
const Color kCard = Colors.white;
const Color kSurface = Color(0xFFF7F7F9);
const Color kCardBorder = Color(0xFFEDEDF0);
const Color kBorder = Color(0xFFEAEAEA);
const Color kBgLight = Color(0xFFFDF7F7);

// ── Status colors (used for chips, badges, payment states) ──────────────────
const Color kStatusPlaced = Color(0xFF1565C0);
const Color kStatusConfirmed = Color(0xFF6A1B9A);
const Color kStatusShipped = Color(0xFFF57C00);
const Color kStatusOutForDelivery = Color(0xFF00838F);
const Color kStatusDelivered = Color(0xFF1DB954);
const Color kStatusPending = Color(0xFFE9A100);

// ── Reusable Widgets (from GlassScaffold file) ───────────────────────────────

enum AppSnackBarType { success, error, info, alert }

void showAppSnackBar(
  BuildContext context, {
  required String title,
  required String message,
  AppSnackBarType type = AppSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final style = _snackBarStyle(type);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: style.color.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: style.color.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            gradient: LinearGradient(
              colors: [style.softColor, Colors.white.withValues(alpha: 0.98)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, color: style.color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      style: const TextStyle(
                        color: kTextMuted,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

_AppSnackBarStyle _snackBarStyle(AppSnackBarType type) {
  switch (type) {
    case AppSnackBarType.success:
      return const _AppSnackBarStyle(
        color: Color(0xFF12B76A),
        softColor: Color(0xFFEAFBF1),
        icon: Icons.check_circle_outline_rounded,
      );
    case AppSnackBarType.error:
      return const _AppSnackBarStyle(
        color: Color(0xFFFF3B00),
        softColor: Color(0xFFFFF0EA),
        icon: Icons.error_outline_rounded,
      );
    case AppSnackBarType.alert:
      return const _AppSnackBarStyle(
        color: Color(0xFFE66A12),
        softColor: Color(0xFFFFF4E8),
        icon: Icons.warning_amber_rounded,
      );
    case AppSnackBarType.info:
      return const _AppSnackBarStyle(
        color: Color(0xFF12A8E8),
        softColor: Color(0xFFEAFBFF),
        icon: Icons.info_outline_rounded,
      );
  }
}

class _AppSnackBarStyle {
  final Color color;
  final Color softColor;
  final IconData icon;

  const _AppSnackBarStyle({
    required this.color,
    required this.softColor,
    required this.icon,
  });
}

class GlassScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  const GlassScaffold({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F7),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBrandRed.withOpacity(0.35),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            right: -80,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBrandRed.withOpacity(0.20),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBrandRedSoft.withOpacity(0.8),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: kBrandRed.withOpacity(0.08),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;

  const GlassTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: kTextDark),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
        prefixIcon: Icon(icon, color: kBrandRed),
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kBrandRed, width: 1.5),
        ),
      ),
    );
  }
}

class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> {
  bool _isShimmering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isShimmering = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _isShimmering ? -1 : 2, end: _isShimmering ? 2 : -1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + value, 0),
              end: Alignment(value, 0),
              colors: const [
                Color(0xFFEDEDF0),
                Color(0xFFF8F8FA),
                Color(0xFFEDEDF0),
              ],
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() => _isShimmering = !_isShimmering);
        }
      },
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _ProductCardSkeleton(),
          childCount: itemCount,
        ),
      ),
    );
  }
}

class ListContentSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsets padding;

  const ListContentSkeleton({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kCardBorder),
        ),
        child: const Row(
          children: [
            SkeletonBox(
              width: 76,
              height: 76,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: double.infinity, height: 14),
                  SizedBox(height: 10),
                  SkeletonBox(width: 140, height: 12),
                  SizedBox(height: 14),
                  SkeletonBox(width: 86, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddressSkeleton extends StatelessWidget {
  const AddressSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 150, height: 16),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 8),
          SkeletonBox(width: 220, height: 12),
        ],
      ),
    );
  }
}

class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(
            width: double.infinity,
            height: 320,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          SizedBox(height: 24),
          SkeletonBox(width: double.infinity, height: 22),
          SizedBox(height: 12),
          SkeletonBox(width: 130, height: 18),
          SizedBox(height: 24),
          SkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 10),
          SkeletonBox(width: 240, height: 12),
          SizedBox(height: 28),
          SkeletonBox(
            width: double.infinity,
            height: 54,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ],
      ),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kCardBorder),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SkeletonBox(
                width: double.infinity,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
            SizedBox(height: 12),
            SkeletonBox(width: double.infinity, height: 14),
            SizedBox(height: 8),
            SkeletonBox(width: 90, height: 12),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 64, height: 16),
                SkeletonBox(
                  width: 34,
                  height: 34,
                  borderRadius: BorderRadius.all(Radius.circular(17)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showCancelOrderDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kBrandRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: kBrandRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Cancel Order',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: kTextDark,
              fontSize: 17,
            ),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to cancel this order?',
        style: TextStyle(color: kTextMuted, fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'No',
            style: TextStyle(color: kTextMuted, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandRed,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Yes, Cancel',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Shows a cancel result snackbar.
void showCancelSnackBar(
  BuildContext context, {
  required bool success,
  required String orderId,
}) {
  showAppSnackBar(
    context,
    title: success ? 'Success' : 'Error',
    message: success ? 'Order #$orderId cancelled' : 'Could not cancel order',
    type: success ? AppSnackBarType.success : AppSnackBarType.error,
  );
}

// shared_ui.dart
Future<bool> showRemoveCartItemDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kBrandRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline, color: kBrandRed, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Remove Item',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: kTextDark,
              fontSize: 17,
            ),
          ),
        ],
      ),
      content: const Text(
        'Remove this item from your cart?',
        style: TextStyle(color: kTextMuted, fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'No',
            style: TextStyle(color: kTextMuted, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandRed,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Remove',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Shows a branded logout confirmation dialog.
/// Returns [true] if the user confirmed, [false] otherwise.
Future<bool?> showLogoutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (ctx) => const _LogoutDialog(),
  );
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    // ← use this 'context' everywhere below
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [kBrandRed, kBrandRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kBrandRed.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Log Out?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out\nof your account?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(false), // ← context, not ctx
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [kBrandRed, kBrandRedDark],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kBrandRed.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(true), // ← context, not ctx
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a save profile confirmation dialog.
/// Returns [true] if the user confirmed, [false] otherwise.
Future<bool?> showSaveProfileDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon badge ──────────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [kBrandRed, kBrandRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kBrandRed.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ───────────────────────────────────────────────
            const Text(
              'Save Changes?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: kTextDark,
              ),
            ),

            const SizedBox(height: 8),

            // ── Subtitle ────────────────────────────────────────────
            const Text(
              'Are you sure you want to save\nyour profile changes?',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextMuted, fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 28),

            // ── Buttons ─────────────────────────────────────────────
            Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: kCardBorder),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kTextMuted,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Confirm Save
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [kBrandRed, kBrandRedDark],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kBrandRed.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
