import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiklini/services/auth_store.dart';
import 'package:tiklini/services/database_service.dart';
import 'package:tiklini/screens/auth/login_screen.dart';
import 'package:tiklini/screens/admin/report_waste_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String marketName;
  final String location;
  final File? marketImage;

  const AdminDashboardScreen({
    super.key,
    required this.marketName,
    required this.location,
    this.marketImage,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // Editable profile fields — seeded from setup
  late String _marketName;
  late String _location;
  File? _marketImage;

  // Real reports added by the user via ReportWasteScreen
  final List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _marketName = widget.marketName;
    _location = widget.location;
    _marketImage = widget.marketImage;
  }

  void _addReport(Map<String, dynamic> report) {
    setState(() => _reports.add(report));
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet(
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
              _sheetOption(
                icon: Icons.photo_camera,
                label: 'Take a photo',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _sheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from gallery',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null && mounted) {
        setState(() => _marketImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    }
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

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return ReportWasteScreen(embedded: true, onReportSubmitted: _addReport);
      case 2:
        return _buildHistoryTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: FloatingActionButton.extended(
                onPressed: () => setState(() => _selectedIndex = 1),
                backgroundColor: const Color(0xFF176A21),
                elevation: 4,
                icon: const Icon(Icons.photo_camera, color: Color(0xFFD1FFC8)),
                label: const Text(
                  'Report Waste',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFFD1FFC8),
                  ),
                ),
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF5F6F7).withValues(alpha: 0.9),
      elevation: 0,
      titleSpacing: 24,
      title: Row(
        children: [
          const Icon(Icons.eco, color: Color(0xFF176A21), size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tiklina',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -1.0,
                  color: Color(0xFF176A21),
                ),
              ),
              Text(
                _marketName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: Color(0xFF595C5D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2F30).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, 'Home', Icons.grid_view),
              _buildNavItem(1, 'Report', Icons.photo_camera_outlined),
              _buildNavItem(2, 'Reports', Icons.receipt_long_outlined),
              _buildNavItem(3, 'Profile', Icons.person_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF176A21).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF176A21)
                  : const Color(0xFF595C5D).withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: isSelected
                    ? const Color(0xFF176A21)
                    : const Color(0xFF595C5D).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Home Tab ──────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService.instance.getAllWasteReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data ?? [];
        final pending = reports.where((r) => r['status'] == 'Submitted').length;
        final accepted = reports
            .where((r) =>
                r['status'] == 'In Progress' || r['status'] == 'Accepted')
            .length;
        final completed =
            reports.where((r) => r['status'] == 'Completed').length;
        final recentReports = reports.take(3).toList();

        return SingleChildScrollView(
          padding:
              const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $_marketName',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  letterSpacing: -0.5,
                  color: Color(0xFF2C2F30),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Color(0xFF595C5D)),
                  const SizedBox(width: 4),
                  Text(
                    _location.isEmpty ? 'No location set' : _location,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF595C5D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Stats - Compact single row
              Row(
                children: [
                  Expanded(
                    child: _buildCompactStatCard(
                      label: 'Pending',
                      value: '$pending',
                      icon: Icons.hourglass_empty_outlined,
                      color: const Color(0xFF6E3A00),
                      bgColor: const Color(0xFFFFC698).withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatCard(
                      label: 'In Progress',
                      value: '$accepted',
                      icon: Icons.local_shipping_outlined,
                      color: const Color(0xFF005159),
                      bgColor: const Color(0xFF10EAFE).withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatCard(
                      label: 'Completed',
                      value: '$completed',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF005C15),
                      bgColor: const Color(0xFF9DF197).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Reports section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Reports',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF2C2F30),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedIndex = 2),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF176A21),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (recentReports.isEmpty)
                _buildEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No reports yet',
                  subtitle:
                      'Tap "Report Waste" below to submit your first waste report.',
                )
              else
                ...recentReports.map(
                  (report) {
                    final status = report['status'] as String;
                    final statusLabel =
                        status == 'Submitted' ? 'Pending' : status;
                    final statusColor = status == 'Submitted'
                        ? const Color(0xFF6E3A00)
                        : status == 'Completed'
                            ? const Color(0xFF005159)
                            : const Color(0xFF005C15);
                    final statusBgColor = status == 'Submitted'
                        ? const Color(0xFFFFC698)
                        : status == 'Completed'
                            ? const Color(0xFF10EAFE)
                            : const Color(0xFF9DF197);

                    final reportDate =
                        DateTime.parse(report['reported_at'] as String);
                    final date =
                        '${reportDate.day} ${_monthName(reportDate.month)} ${reportDate.year}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildReportCard(
                        title: report['market_name'] as String? ??
                            'Unknown location',
                        status: statusLabel,
                        statusColor: statusColor,
                        statusBgColor: statusBgColor,
                        date: date,
                        category: 'Mixed Waste',
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ── All Reports Tab ───────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService.instance.getAllWasteReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data ?? [];
        final total = reports.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Reports',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: Color(0xFF2C2F30),
                    ),
                  ),
                  if (total > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF176A21).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$total total',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF176A21),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Track the status of all your waste reports',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF595C5D),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: reports.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No reports yet',
                      subtitle:
                          'Your submitted reports and their status will appear here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final report = reports[i];
                        final status = report['status'] as String;
                        final statusLabel =
                            status == 'Submitted' ? 'Pending' : status;
                        final statusColor = status == 'Submitted'
                            ? const Color(0xFF6E3A00)
                            : status == 'Completed'
                                ? const Color(0xFF005159)
                                : const Color(0xFF005C15);
                        final statusBgColor = status == 'Submitted'
                            ? const Color(0xFFFFC698)
                            : status == 'Completed'
                                ? const Color(0xFF10EAFE)
                                : const Color(0xFF9DF197);

                        final reportDate =
                            DateTime.parse(report['reported_at'] as String);
                        final date =
                            '${reportDate.day} ${_monthName(reportDate.month)} ${reportDate.year}';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2C2F30,
                                ).withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF1F2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFABACAE),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report['market_name'] as String? ??
                                          'Unknown location',
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF2C2F30),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text(
                                          'Mixed Waste',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Color(0xFF595C5D),
                                          ),
                                        ),
                                        const Text(
                                          ' · ',
                                          style: TextStyle(
                                            color: Color(0xFFABACAE),
                                          ),
                                        ),
                                        Text(
                                          report['est_volume'] as String? ??
                                              'Unknown',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Color(0xFF595C5D),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: Color(0xFFABACAE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  statusLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: Color(0xFF595C5D),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  // ── Profile Tab ───────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    final nameController = TextEditingController(text: _marketName);
    final locationController = TextEditingController(text: _location);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9DF197),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: _marketImage != null
                        ? DecorationImage(
                            image: FileImage(_marketImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _marketImage == null
                      ? const Icon(
                          Icons.storefront,
                          color: Color(0xFF005C15),
                          size: 56,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF176A21),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF9DF197).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Market Admin',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF005C15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Editable fields
          const Text(
            'MARKET NAME',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
              color: Color(0xFF595C5D),
            ),
          ),
          const SizedBox(height: 8),
          _buildEditableField(
            controller: nameController,
            hint: 'e.g. Soweto Market',
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 20),
          const Text(
            'LOCATION',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
              color: Color(0xFF595C5D),
            ),
          ),
          const SizedBox(height: 8),
          _buildEditableField(
            controller: locationController,
            hint: 'e.g. Lusaka, Zambia',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                final newLocation = locationController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Market name cannot be empty.'),
                    ),
                  );
                  return;
                }
                setState(() {
                  _marketName = newName;
                  _location = newLocation;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated.'),
                    backgroundColor: Color(0xFF176A21),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF176A21),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFD1FFC8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(color: Color(0xFFDADDDF)),
          const SizedBox(height: 16),

          _buildProfileTile(
            Icons.notifications_outlined,
            'Notifications',
            onTap: () => _showInfoDialog(
              'Notifications',
              'Notification settings will be available in a future update.',
            ),
          ),
          _buildProfileTile(
            Icons.help_outline,
            'Help & Support',
            onTap: () => _showInfoDialog(
              'Help & Support',
              'For support, contact us at support@tiklina.app',
            ),
          ),
          _buildProfileTile(
            Icons.info_outline,
            'About Tiklina',
            onTap: () => _showInfoDialog(
              'About Tiklina',
              'Tiklina v1.0.0\nThe Digital Steward — connecting markets and waste collectors for a greener future.',
            ),
          ),

          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: () {
                AuthStore.instance.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFB02500),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF176A21),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDADDDF)),
      ),
      child: TextField(
        controller: controller,
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
          prefixIcon: Icon(icon, color: const Color(0xFF176A21)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF176A21), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: const Color(0xFFABACAE), size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF2C2F30),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF595C5D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String label, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF176A21)),
        title: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF2C2F30),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFABACAE)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required String date,
    required String category,
    bool isUrgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isUrgent
            ? Border.all(color: const Color(0xFFB02500), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2F30).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Color(0xFFABACAE),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF2C2F30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (category.isNotEmpty) ...[
                      const Icon(
                        Icons.category,
                        size: 13,
                        color: Color(0xFF595C5D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF595C5D),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (date.isNotEmpty) ...[
                      const Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: Color(0xFF595C5D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF595C5D),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
