import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tiklini/services/database_service.dart';

class JobExecutionScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobExecutionScreen({
    super.key,
    required this.job,
  });

  @override
  State<JobExecutionScreen> createState() => _JobExecutionScreenState();
}

class _JobExecutionScreenState extends State<JobExecutionScreen> {
  File? _proofImage;
  bool _isUploading = false;

  Future<void> _takeProofPhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image != null) {
        setState(() {
          _proofImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: const Color(0xFFB02500),
          ),
        );
      }
    }
  }

  Future<void> _markJobCompleted() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a proof photo before completing the job'),
          backgroundColor: Color(0xFFB02500),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Update job status to completed
      await DatabaseService.instance.updateWasteReportStatus(
        reportId: widget.job['id'].toString(),
        status: 'Completed',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job marked as completed!'),
            backgroundColor: Color(0xFF176A21),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate completion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete job: $e'),
            backgroundColor: const Color(0xFFB02500),
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF176A21)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Execution',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF176A21),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF176A21)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom:
                  140, // Increased to account for bottom action bar + system nav
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2C2F30).withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DESTINATION',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          color: Color(0xFF176A21),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.job['market_name'] as String? ??
                            'Unknown Location',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: Color(0xFF2C2F30),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: Color(0xFF595C5D),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.job['description'] as String? ??
                                  'No description available',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: Color(0xFF595C5D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Map View
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDADDDF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  color: const Color(0xFFDADDDF),
                                  child: const Center(
                                    child: Icon(
                                      Icons.map,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Live Traffic',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF176A21),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4ADE80),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Navigate Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF176A21), Color(0xFF025D16)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF176A21,
                              ).withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.map, color: Color(0xFFD1FFC8)),
                              SizedBox(width: 12),
                              Text(
                                'Navigate to Site',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFFD1FFC8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Current Status
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1F2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current Status',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2C2F30),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                  widget.job['status'] as String? ?? 'Unknown'),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusBorderColor(
                                    widget.job['status'] as String? ??
                                        'Unknown'),
                              ),
                            ),
                            child: Text(
                              widget.job['status'] as String? ?? 'Unknown',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _getStatusTextColor(
                                    widget.job['status'] as String? ??
                                        'Unknown'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStatusItem(
                        Icons.inventory_2,
                        'Estimated Load',
                        '${widget.job['est_volume'] as String? ?? 'Unknown'} Mixed Waste',
                      ),
                      const SizedBox(height: 12),
                      _buildStatusItem(
                        Icons.schedule,
                        'Reported',
                        _formatDate(widget.job['reported_at'] as String?),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Proof of Collection
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Job Verification',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2C2F30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: _proofImage != null
                        ? Colors.transparent
                        : const Color(0xFFEFF1F2).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFFABACAE).withValues(alpha: 0.5),
                      width: 4,
                    ),
                  ),
                  child: _proofImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.file(
                            _proofImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(32),
                            onTap: _takeProofPhoto,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo,
                                    size: 36,
                                    color: Color(0xFF025D16),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Upload Proof of Collection',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: Color(0xFF2C2F30),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '(Take Photo of Bins)',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Color(0xFF595C5D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                if (_proofImage != null) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _takeProofPhoto,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake Photo'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF176A21),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F7).withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFABACAE).withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF176A21),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF176A21).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _markJobCompleted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(
                          color: Color(0xFFD1FFC8),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFFD1FFC8),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Mark as Completed',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFD1FFC8),
                              ),
                            ),
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF9DF197).withValues(alpha: 0.5);
      case 'in progress':
        return const Color(0xFFFFC698);
      case 'accepted':
        return const Color(0xFF10EAFE).withValues(alpha: 0.2);
      default:
        return const Color(0xFFEFF1F2);
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF005C15).withValues(alpha: 0.2);
      case 'in progress':
        return const Color(0xFF8B4B00).withValues(alpha: 0.2);
      case 'accepted':
        return const Color(0xFF005159).withValues(alpha: 0.2);
      default:
        return const Color(0xFFABACAE).withValues(alpha: 0.2);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF005C15);
      case 'in progress':
        return const Color(0xFF6E3A00);
      case 'accepted':
        return const Color(0xFF005159);
      default:
        return const Color(0xFF595C5D);
    }
  }

  Widget _buildStatusItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF176A21).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF176A21)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF595C5D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2C2F30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
