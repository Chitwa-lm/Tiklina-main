import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiklini/services/auth_store.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Step 0 = role selection, Step 1 = credentials + profile
  int _step = 0;
  UserRole? _selectedRole;

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  File? _marketImage;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null && mounted) {
      setState(() => _marketImage = File(picked.path));
    }
  }

  void _showImageSheet() {
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
                'Market Photo',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2C2F30),
                ),
              ),
              const SizedBox(height: 20),
              _sheetTile(Icons.photo_camera, 'Take a photo', () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              }),
              const SizedBox(height: 12),
              _sheetTile(
                Icons.photo_library_outlined,
                'Choose from gallery',
                () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_marketImage != null) ...[
                const SizedBox(height: 12),
                _sheetTile(
                  Icons.delete_outline,
                  'Remove photo',
                  () {
                    Navigator.pop(context);
                    setState(() => _marketImage = null);
                  },
                  color: const Color(0xFFB02500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
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

  void _register() {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty) {
      _err('Please enter your name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _err('Enter a valid email.');
      return;
    }
    if (password.length < 6) {
      _err('Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      _err('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    final error = AuthStore.instance.register(
      AppUser(
        email: email,
        password: password,
        role: _selectedRole!,
        name: name,
        location: location,
        marketImage: _marketImage,
      ),
    );

    setState(() => _isLoading = false);

    if (error != null) {
      _err(error);
    } else {
      // Registration successful — go to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please log in.'),
          backgroundColor: Color(0xFF176A21),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFB02500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      body: SafeArea(
        child: _step == 0 ? _buildRoleStep() : _buildDetailsStep(),
      ),
    );
  }

  // ── Step 0: Role Selection ────────────────────────────────────────────────

  Widget _buildRoleStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centered logo
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9DF197),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF176A21).withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Color(0xFF005C15),
                    size: 44,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tiklina',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -1.0,
                    color: Color(0xFF176A21),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'THE DIGITAL STEWARD',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    letterSpacing: 2.0,
                    color: Color(0xFF595C5D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Create account',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 32,
              letterSpacing: -0.5,
              color: Color(0xFF2C2F30),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your role to get started.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Color(0xFF595C5D),
            ),
          ),
          const SizedBox(height: 40),

          _roleCard(
            title: 'Market Admin',
            subtitle: 'Manage stalls and submit waste reports.',
            icon: Icons.storefront,
            iconBg: const Color(0xFFFFC698),
            iconColor: const Color(0xFF6E3A00),
            role: UserRole.admin,
          ),
          const SizedBox(height: 16),
          _roleCard(
            title: 'Waste Collector',
            subtitle: 'Find and accept waste collection jobs.',
            icon: Icons.local_shipping,
            iconBg: const Color(0xFF9DF197),
            iconColor: const Color(0xFF005C15),
            role: UserRole.collector,
          ),

          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF595C5D),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text(
                  'Log in',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF176A21),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required UserRole role,
  }) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = role);
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) setState(() => _step = 1);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF176A21) : const Color(0xFFDADDDF),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C2F30).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF2C2F30),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF595C5D),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFABACAE)),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Details ───────────────────────────────────────────────────────

  Widget _buildDetailsStep() {
    final isAdmin = _selectedRole == UserRole.admin;
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2F30)),
                onPressed: () => setState(() => _step = 0),
              ),
              const SizedBox(width: 4),
              Text(
                isAdmin ? 'Market Admin' : 'Waste Collector',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2C2F30),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete your profile',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    letterSpacing: -0.5,
                    color: Color(0xFF2C2F30),
                  ),
                ),
                const SizedBox(height: 28),

                // Market photo — admin only
                if (isAdmin) ...[
                  _label('MARKET PHOTO'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showImageSheet,
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _marketImage != null
                              ? const Color(0xFF176A21)
                              : const Color(0xFFDADDDF),
                          width: _marketImage != null ? 2 : 1,
                        ),
                      ),
                      child: _marketImage != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    _marketImage!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: _showImageSheet,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 16,
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
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF9DF197),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: Color(0xFF005C15),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Tap to upload',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF2C2F30),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                _label(isAdmin ? 'MARKET NAME' : 'COMPANY NAME'),
                const SizedBox(height: 8),
                _field(
                  _nameController,
                  hint: isAdmin ? 'e.g. Soweto Market' : 'e.g. GreenHaul Ltd',
                ),
                const SizedBox(height: 16),

                _label('LOCATION / SERVICE AREA'),
                const SizedBox(height: 8),
                _field(_locationController, hint: 'e.g. Lusaka, Zambia'),
                const SizedBox(height: 16),

                _label('EMAIL'),
                const SizedBox(height: 8),
                _field(
                  _emailController,
                  hint: 'you@example.com',
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _label('PASSWORD'),
                const SizedBox(height: 8),
                _field(
                  _passwordController,
                  hint: 'Min. 6 characters',
                  obscure: _obscurePassword,
                  toggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 16),

                _label('CONFIRM PASSWORD'),
                const SizedBox(height: 8),
                _field(
                  _confirmController,
                  hint: 'Repeat password',
                  obscure: _obscureConfirm,
                  toggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176A21),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Color(0xFFD1FFC8),
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFD1FFC8),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF595C5D),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF176A21),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Manrope',
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: 1.5,
      color: Color(0xFF595C5D),
    ),
  );

  Widget _field(
    TextEditingController controller, {
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDADDDF)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Color(0xFF2C2F30),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFFABACAE).withValues(alpha: 0.8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF176A21), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          suffixIcon: toggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFFABACAE),
                  ),
                  onPressed: toggleObscure,
                )
              : null,
        ),
      ),
    );
  }
}
