import 'package:flutter/material.dart';
import 'package:wss_sports/core/localization/app_strings.dart';
import 'package:wss_sports/core/localization/app_language.dart';
import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/profile/presentation/pages/edit_profile_page.dart';
import 'package:wss_sports/settings/presentation/pages/language_page.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfilePage({super.key, required this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AppLanguageController _languageController =
      AppLanguageController.instance;
  late Map<String, dynamic> _userData;

  String get orders => 'Orders';
  String get wishlist => 'Wishlist';
  String get reviews => 'Reviews';

  String get _fullName =>
      (_userData['full_name'] ?? _userData['name'] ?? 'User').toString();
  String get _email => (_userData['email'] ?? 'No email').toString();
  String get _phone => (_userData['phone'] ?? '+1 000 000 0000').toString();
  String get _languageLabel => _languageController.current.profileLabel;
  String? get _imageUrl =>
      (_userData['image_url'] ?? _userData['photoUrl'])?.toString();
  String get _initial =>
      _fullName.trim().isNotEmpty ? _fullName.trim()[0].toUpperCase() : 'U';

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = widget.userData['id'];
    if (userId == null) {
      return;
    }

    final updatedUser = await ApiService.getUser(
      id: userId is int ? userId : int.tryParse(userId.toString()) ?? 0,
    );
    if (updatedUser != null && mounted) {
      setState(() {
        _userData = updatedUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 0),
              _buildStatsRow(strings),
              _buildSectionTitle(strings.account),
              _buildActionGroup([
                _ActionItem(
                  icon: Icons.person_outline_rounded,
                  title: strings.editProfile,
                  subtitle: strings.updatePersonalInfo,
                  onTap: () async {
                    final updatedUser = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditProfilePage(userData: _userData),
                      ),
                    );
                    if (updatedUser is Map<String, dynamic>) {
                      setState(() {
                        _userData = updatedUser;
                      });
                    }
                  },
                ),
                _ActionItem(
                  icon: Icons.lock_outline_rounded,
                  title: strings.privacySecurity,
                  subtitle: strings.password2faSessions,
                  onTap: () {},
                ),
                _ActionItem(
                  icon: Icons.notifications_none_rounded,
                  title: strings.notifications,
                  subtitle: strings.manageAlertsSounds,
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 35),
              _buildSectionTitle(strings.preferences),
              _buildActionGroup([
                _ActionItem(
                  icon: Icons.palette_outlined,
                  title: strings.appearance,
                  subtitle: strings.themeAndDisplay,
                  onTap: () {},
                ),
                _ActionItem(
                  icon: Icons.language_rounded,
                  title: strings.language,
                  subtitle: _languageLabel,
                  onTap: () async {
                    final selectedLanguage = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguagePage(),
                      ),
                    );
                    if (selectedLanguage != null && mounted) {
                      setState(() {});
                    }
                  },
                ),
                _ActionItem(
                  icon: Icons.help_outline_rounded,
                  title: strings.helpSupport,
                  subtitle: strings.faqsAndContact,
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 28),
              _buildLogoutButton(context, strings),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Header with red gradient =====
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBrandRed, kBrandRedDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // _circleIconButton(Icons.arrow_back_ios_new_rounded, () {
                  //   Navigator.maybePop(context);
                  // }),
                  Text(
                    context.strings.myProfile,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // _circleIconButton(Icons.settings_outlined, () {}),
                ],
              ),
              const SizedBox(height: 28),
              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                      ? NetworkImage(_imageUrl!)
                      : null,
                  child: _imageUrl == null || _imageUrl!.isEmpty
                      ? Text(
                          _initial,
                          style: const TextStyle(
                            fontSize: 36,
                            color: kBrandRed,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _email,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              if (_phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone_android_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _phone,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ===== Stats card (overlapping the header) =====
  Widget _buildStatsRow(AppStrings strings) {
    return Transform.translate(
      offset: const Offset(0, -40),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _statTile(Icons.shopping_bag_outlined, '24', strings.orders),
            _divider(),
            _statTile(Icons.favorite_border_rounded, '57', strings.wishlist),
            _divider(),
            _statTile(Icons.star_border_rounded, '8', strings.reviews),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: kCardBorder);

  Widget _statTile(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: kBrandRed, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: kTextDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: kTextMuted, fontSize: 12)),
        ],
      ),
    );
  }

  // ===== Section title =====
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // ===== Action group card =====
  Widget _buildActionGroup(List<_ActionItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kCardBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i != items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: kCardBorder),
              ),
          ],
        ],
      ),
    );
  }

// ===== Logout =====
Widget _buildLogoutButton(BuildContext context, AppStrings strings) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [kBrandRed, kBrandRedDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kBrandRed.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () async {
            // ── Show the shared dialog ──────────────────────────────
            final confirmed = await showLogoutDialog(context);

            if (confirmed == true && context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/LoginPage',
                (route) => false,
              );
            }
          },
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: Text(
            strings.logout,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    ),
  );
}
}

// ===== Reusable action item =====
class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kBrandRed.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: kBrandRed, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: kTextMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: kTextMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
