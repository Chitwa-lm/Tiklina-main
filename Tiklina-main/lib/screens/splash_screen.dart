import 'package:flutter/material.dart';
import 'package:tiklini/screens/auth/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F7),
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              const Color(0xFF176A21).withOpacity(0.08),
              Colors.transparent,
            ],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 48.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // Logo Section
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9DF197),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Color(0xFF005C15),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tiklina',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
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
                    fontSize: 14,
                    letterSpacing: 1.5,
                    color: Color(0xFF595C5D),
                  ),
                ),
                const SizedBox(height: 64),

                // Welcome Text
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Welcome to the ecosystem.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      height: 1.2,
                      color: Color(0xFF2C2F30),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose your role to start managing waste more efficiently today.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      height: 1.5,
                      color: Color(0xFF595C5D),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Role Selection Buttons
                _buildRoleCard(
                  context: context,
                  title: 'I am a Market Admin',
                  subtitle: 'Manage stalls and waste collection schedules.',
                  icon: Icons.storefront,
                  iconBgColor: const Color(0xFFFFC698), // secondary-container
                  iconColor: const Color(0xFF6E3A00), // on-secondary-container
                  role: 'Admin',
                ),
                const SizedBox(height: 24),
                _buildRoleCard(
                  context: context,
                  title: 'I am a Waste Collector',
                  subtitle: 'Find nearby pickups and optimize your routes.',
                  icon: Icons.local_shipping,
                  iconBgColor: const Color(0xFF9DF197), // primary-container
                  iconColor: const Color(0xFF005C15), // on-primary-container
                  role: 'Company',
                ),

                const Spacer(),
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1F2), // surface-container-low
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF176A21),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CONNECTING FOR A GREENER FUTURE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: Color(0xFF595C5D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String role,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen(role: role)),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFABACAE).withOpacity(0.1)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF2C2F30),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF595C5D),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF757778)),
            ],
          ),
        ),
      ),
    );
  }
}
