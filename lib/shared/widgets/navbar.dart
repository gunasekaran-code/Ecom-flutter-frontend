import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:wss_sports/core/localization/app_strings.dart';
import 'package:wss_sports/shop/presentation/pages/home_page.dart';
import 'package:wss_sports/shop/presentation/pages/order_page.dart';
import 'package:wss_sports/shop/presentation/pages/wishlist_page.dart';
import 'package:wss_sports/profile/presentation/pages/profile_page.dart';

class UserHomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserHomePage({super.key, required this.userData});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Helper widget to handle the unselected text labels and selected icon scaling
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF6B6B6B),
          size: isSelected ? 30 : 26, // Make the active icon slightly larger
        ),
        // Only show the label if the item is NOT selected
        if (!isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B6B6B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F7),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(userData: widget.userData),
            OrderPage(userId: widget.userData['id']),
            WishlistPage(
              userData: widget.userData,
              onContinueShopping: () => _onItemTapped(0),
            ),
            ProfilePage(userData: widget.userData),
          ],
        ),
      ),
      // Use CurvedNavigationBar instead of the standard BottomNavigationBar
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: const Color(
          0xFFFDF7F7,
        ), // Must match Scaffold background for transparent effect
        color: Colors.white, // The white pill background
        buttonBackgroundColor: const Color(
          0xFFE4252A,
        ), // The Trending Red floating circle
        height: 65, // Slightly taller to accommodate labels
        animationDuration: const Duration(milliseconds: 350),
        animationCurve: Curves.easeOutCubic,
        onTap: _onItemTapped,
        items: [
          _buildNavItem(Icons.home_outlined, strings.home, 0),
          _buildNavItem(Icons.local_shipping_outlined, strings.orders, 1),
          _buildNavItem(Icons.favorite_outline, strings.wishlist, 2),
          _buildNavItem(Icons.person_outline, strings.profile, 3),
        ],
      ),
    );
  }
}
