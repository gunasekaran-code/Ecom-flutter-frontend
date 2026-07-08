import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  late Map<String, dynamic> _profileData;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  String get _currentImageUrl {
  final raw = (_profileData['profile_image'] ?? '').toString();
  if (raw.isEmpty) return '';
  if (raw.startsWith('http')) return raw;
  return 'http://192.168.1.7:8000/$raw'; // or your ApiService.baseUrl constant
}

  String get _initial {
    final name = _profileData['full_name'] ?? _profileData['name'] ?? '';
    final trimmed = name.toString().trim();
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'U';
  }

  String? _selectedGender;
  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _profileData = Map<String, dynamic>.from(widget.userData);
    _fullNameController = TextEditingController(
      text: _profileData['full_name']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: _profileData['email']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: _profileData['phone']?.toString() ?? '',
    );
    _selectedGender = _profileData['gender']?.toString(); // ← add this
    if (_selectedGender != null && _selectedGender!.isEmpty) {
      _selectedGender = null;
    }
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = widget.userData['id'];
    if (userId == null) return;

    final updatedUser = await ApiService.getUser(
      id: userId is int ? userId : int.tryParse(userId.toString()) ?? 0,
    );
    if (updatedUser != null && mounted) {
      setState(() {
        _profileData = updatedUser;
        _fullNameController.text = updatedUser['full_name']?.toString() ?? '';
        _emailController.text = updatedUser['email']?.toString() ?? '';
        _phoneController.text = updatedUser['phone']?.toString() ?? '';
        _selectedGender = updatedUser['gender']?.toString();
        if (_selectedGender != null && _selectedGender!.isEmpty) {
          _selectedGender = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 00,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageFile = pickedFile;
          _selectedImageBytes = bytes;
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        title: 'Error',
        message: 'Failed to pick image: $e',
        type: AppSnackBarType.error,
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kCardBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Update profile photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose a source for your new photo',
                  style: TextStyle(fontSize: 13, color: kTextMuted),
                ),
                const SizedBox(height: 16),
                _buildSheetTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from gallery',
                  subtitle: 'Pick an existing photo',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(height: 10),
                _buildSheetTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take a photo',
                  subtitle: 'Use your camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCardBorder),
        ),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kTextDark,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: kTextMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kTextMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (fullName.isEmpty || email.isEmpty) {
      showAppSnackBar(
        context,
        title: 'Alert',
        message: 'Name and email are required.',
        type: AppSnackBarType.alert,
      );
      return;
    }

    // ── Show confirmation dialog before saving ──────────────────────
    final confirmed = await showSaveProfileDialog(context);
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    final result = await ApiService.updateUser(
      id: widget.userData['id'],
      name: fullName,
      email: email,
      phone: phone.isNotEmpty ? phone : null,
      gender: _selectedGender,
      imageFile: _selectedImageFile,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final updatedData = result['data'] as Map<String, dynamic>;
      showAppSnackBar(
        context,
        title: 'Success',
        message: 'Profile updated successfully',
        type: AppSnackBarType.success,
      );
      Navigator.pop(context, updatedData);
    } else {
      final errorText =
          result['error']?.toString() ?? 'Failed to update profile';
      showAppSnackBar(
        context,
        title: 'Error',
        message: errorText,
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Gradient header backdrop
          Container(
            height: 340,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kBrandRed, kBrandRedDark],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Avatar
                  Center(child: _buildAvatar()),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      _fullNameController.text.isNotEmpty
                          ? _fullNameController.text
                          : 'Your Profile',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Keep your information up to date',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kCardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kTextDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Update your personal details below',
                          style: TextStyle(fontSize: 12.5, color: kTextMuted),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          hintText: 'Enter your name',
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hintText: 'name@example.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hintText: 'Enter your phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildGenderDropdown(), // ← add this
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style:
                          ElevatedButton.styleFrom(
                            backgroundColor: kBrandRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: kBrandRed.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ).copyWith(
                            overlayColor: WidgetStateProperty.all(
                              kBrandRedDark.withOpacity(0.2),
                            ),
                          ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: kTextMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: kCardBorder),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            color: kTextDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: kTextMuted,
          ),
          style: const TextStyle(
            color: kTextDark,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Select gender',
            hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
            prefixIcon: const Icon(
              Icons.wc_outlined,
              color: kTextMuted,
              size: 20,
            ),
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kCardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBrandRed, width: 1.5),
            ),
          ),
          items: _genderOptions
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (value) => setState(() => _selectedGender = value),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
  Widget avatarChild;
  if (_selectedImageBytes != null) {
    avatarChild = ClipOval(
      child: Image.memory(
        _selectedImageBytes!,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
      ),
    );
  } else if (_currentImageUrl.isNotEmpty) {
    avatarChild = ClipOval(
      child: CachedNetworkImage(
        imageUrl: _currentImageUrl,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage, // ← key fix
        placeholder: (context, url) =>
            const CircularProgressIndicator(strokeWidth: 2),
        errorWidget: (context, url, error) => Text(
          _initial,
          style: const TextStyle(
            fontSize: 38,
            color: kBrandRed,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  } else {
    avatarChild = Text(
      _initial,
      style: const TextStyle(
        fontSize: 38,
        color: kBrandRed,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  return Stack(
    children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 52,
          backgroundColor: kSurface,
          child: avatarChild,
        ),
      ),
      Positioned(
        bottom: 2,
        right: 2,
        child: GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kBrandRed,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: kBrandRedDark.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
          ),
        ),
      ),
    ],
  );
}


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (_) => setState(() {}), // updates header name live
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
            prefixIcon: Icon(icon, color: kTextMuted, size: 20),
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kCardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBrandRed, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
