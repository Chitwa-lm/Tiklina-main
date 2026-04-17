import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiklini/screens/admin/admin_dashboard_screen.dart';
import 'package:tiklini/screens/company/company_dashboard_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String role;

  const ProfileSetupScreen({super.key, required this.role});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  File? _marketImage;
  bool _pickingImage = false;

  bool get _isAdmin => widget.role == 'Admin';

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() => _marketImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDADDDF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Upload Market Photo',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2C2F30),
                ),
              ),
              const SizedBox(height: 20),
              _sheetOption(
                icon: Icons.photo_camera,
                label: 'Take a photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _sheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_marketImage != null) ...[
                const SizedBox(height: 12),
                _sheetOption(
                  icon: Icons.delete_outline,
                  label: 'Remove photo',
                  color: const Color(0xFFB02500),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _marketImage = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF176A21),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onContinue() {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }

    if (_isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(
            marketName: name,
            location: location,
            marketImage: _marketImage,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CompanyDashboardScreen(companyName: name, location: location),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F7).withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF595C5D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.eco, color: Color(0xFF176A21)),
            SizedBox(width: 8),
            Text(
              'Profile Setup',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF176A21),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 16.0,
              bottom: 120.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete your profile',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                    height: 1.1,
                    letterSpacing: -0.5,
                    color: Color(0xFF2C2F30),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isAdmin
                      ? 'Tell us about your market so we can set up your admin profile.'
                      : 'Tell us about your company so collectors can find your jobs.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    color: Color(0xFF595C5D),
                  ),
                ),
                const SizedBox(height: 32),

                // Market photo — admin only
                if (_isAdmin) ...[
                  const Text(
                    'MARKET PHOTO',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.5,
                      color: Color(0xFF595C5D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickingImage ? null : _showImageSourceSheet,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _marketImage != null
                              ? const Color(0xFF176A21)
                              : const Color(0xFFDADDDF),
                          width: _marketImage != null ? 2 : 1,
                        ),
                      ),
                      child: _pickingImage
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF176A21),
                              ),
                            )
                          : _marketImage != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(19),
                                  child: Image.file(
                                    _marketImage!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: _showImageSourceSheet,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF9DF197),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: Color(0xFF005C15),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap to upload a photo',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2C2F30),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Camera or gallery',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Color(0xFF595C5D),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                Text(
                  _isAdmin ? 'MARKET NAME' : 'COMPANY NAME',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                    color: Color(0xFF595C5D),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: _isAdmin ? 'e.g. Soweto Market' : 'e.g. GreenHaul Ltd',
                ),

                const SizedBox(height: 24),
                const Text(
                  'LOCATION / SERVICE AREA',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                    color: Color(0xFF595C5D),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _locationController,
                  hint: 'e.g. Lusaka, Zambia',
                ),

                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'Your data is stored securely and used only for waste collection logistics.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: Color(0xFF595C5D),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky bottom button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFF5F6F7),
                    const Color(0xFFF5F6F7).withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF176A21), Color(0xFF025D16)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF176A21).withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Save and Continue',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFFD1FFC8),
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward, color: Color(0xFFD1FFC8)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Color(0xFF2C2F30),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFFABACAE).withValues(alpha: 0.8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF176A21), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}
