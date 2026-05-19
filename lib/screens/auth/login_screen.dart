import 'package:flutter/material.dart';
import 'package:tiklini/services/supabase_service.dart';
import 'package:tiklini/services/database_service.dart';
import 'package:tiklini/screens/admin/admin_dashboard_screen.dart';
import 'package:tiklini/screens/company/company_dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _err('Enter a valid email.');
      return;
    }
    if (password.isEmpty) {
      _err('Enter your password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Sign in with Supabase
      final authResponse = await SupabaseService.instance.signIn(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Login failed');
      }

      final userId = authResponse.user!.id;

      // 2. Get user profile from database
      final profile = await DatabaseService.instance.getUserProfile(userId);

      if (profile == null) {
        throw Exception('User profile not found');
      }

      final role = profile['role'] as String;
      final name = profile['market_name'] ?? profile['company_name'] ?? 'User';
      final location = profile['location'] ?? '';

      setState(() => _isLoading = false);

      // 3. Navigate based on role
      if (mounted) {
        if (role == 'Admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDashboardScreen(
                marketName: name,
                location: location,
                marketImage: null, // Can be loaded from profile if needed
              ),
            ),
            (_) => false,
          );
        } else if (role == 'Company') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => CompanyDashboardScreen(
                companyName: name,
                location: location,
              ),
            ),
            (_) => false,
          );
        } else {
          throw Exception('Invalid user role: $role');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _err('Login failed: ${e.toString()}');
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Centered logo block
              const SizedBox(height: 24),
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
                            color: const Color(
                              0xFF176A21,
                            ).withValues(alpha: 0.15),
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
              const SizedBox(height: 48),

              const Text(
                'Welcome back',
                textAlign: TextAlign.center,
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
                'Log in to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF595C5D),
                ),
              ),
              const SizedBox(height: 40),

              _label('EMAIL'),
              const SizedBox(height: 8),
              _field(
                _emailController,
                hint: 'you@example.com',
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              _label('PASSWORD'),
              const SizedBox(height: 8),
              _field(
                _passwordController,
                hint: 'Your password',
                obscure: _obscure,
                toggleObscure: () => setState(() => _obscure = !_obscure),
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
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
                          'Log In',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFFD1FFC8),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF595C5D),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    child: const Text(
                      'Sign up',
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
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.5,
            color: Color(0xFF595C5D),
          ),
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
