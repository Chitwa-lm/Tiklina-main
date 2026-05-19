import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  final bool embedded;

  const VerificationScreen({
    super.key,
    required this.job,
    this.embedded = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  int _rating = 4;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitVerification() async {
    setState(() => _isSubmitting = true);

    try {
      // Here you would typically create a verification record
      // For now, we'll just show success message

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2C2F30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            behavior: SnackBarBehavior.floating,
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF9DF197),
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Verification submitted successfully',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.pop(
            context, true); // Return true to indicate verification completed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit verification: $e'),
            backgroundColor: const Color(0xFFB02500),
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: const Color(0xFFF5F6F7).withValues(alpha: 0.9),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2F30)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Verify Job',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2C2F30),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Row(
                    children: const [
                      Icon(Icons.eco, color: Color(0xFF176A21)),
                      SizedBox(width: 4),
                      Text(
                        'Tiklina',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          letterSpacing: -1.0,
                          color: Color(0xFF176A21),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF9DF197).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, size: 18, color: Color(0xFF005C15)),
                  SizedBox(width: 8),
                  Text(
                    'COLLECTION COMPLETED',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                      color: Color(0xFF005C15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Job Details Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C2F30).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job['market_name'] ?? 'Unknown Location',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2C2F30),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.scale_outlined,
                          size: 16, color: Color(0xFF176A21)),
                      const SizedBox(width: 6),
                      Text(
                        'Volume: ${widget.job['est_volume'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF595C5D),
                        ),
                      ),
                    ],
                  ),
                  if (widget.job['description'] != null &&
                      widget.job['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 16, color: Color(0xFF176A21)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.job['description'],
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Color(0xFF595C5D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Rating Section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C2F30).withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Rate the Collection',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.5,
                      color: Color(0xFF2C2F30),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        iconSize: 40,
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: index < _rating
                              ? const Color(0xFF8B4B00)
                              : const Color(0xFF8B4B00).withValues(alpha: 0.3),
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Optional Comments',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF595C5D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF1F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tell us about the service...',
                        hintStyle: TextStyle(
                          color: const Color(0xFFABACAE).withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Impact Created Stat
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10EAFE).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFF10EAFE).withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10EAFE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco, color: Color(0xFF005159)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IMPACT CREATED',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                            color: Color(0xFF005159),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Help keep the environment clean',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF2C2F30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Container(
              width: double.infinity,
              height: 56,
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
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        color: Color(0xFFD1FFC8),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Submit Verification',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFD1FFC8),
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.send, color: Color(0xFFD1FFC8)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Report an Issue',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF176A21),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
