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