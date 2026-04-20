import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiklini/services/job_store.dart';
import 'package:tiklini/services/auth_store.dart';
import 'package:tiklini/screens/auth/login_screen.dart';
import 'package:tiklini/screens/company/job_execution_screen.dart';
import 'package:tiklini/screens/company/job_details_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  final String companyName;
  final String location;

  const CompanyDashboardScreen({
    super.key,
    required this.companyName,
    required this.location,
  });

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  int _selectedIndex = 1;

  late String _companyName;
  late String _location;

  @override
  void initState() {
    super.initState();
    _companyName = widget.companyName;
    _location = widget.location;
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildMarketTab();
      case 2:
        return _buildActivityTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildMarketTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF5F6F7).withValues(alpha: 0.9),
      elevation: 0,
      titleSpacing: 24,
      title: Row(
        children: const [
          Icon(Icons.eco, color: Color(0xFF176A21), size: 28),
          SizedBox(width: 8),
          Text(
            'Tiklina',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.5,
              color: Color(0xFF2C2F30),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Color(0xFF595C5D)),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 24.0, left: 8.0),
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = 3),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF9DF197),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(0xFF005C15)),
            ),
          ),
        ),
      ],
    );
  }

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
              _buildNavItem(1, 'Market', Icons.map),
              _buildNavItem(2, 'Activity', Icons.receipt_long_outlined),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
    return Consumer<JobStore>(
      builder: (context, store, _) {
        final availableCount = store.availableJobs.length;
        final completedToday =
            store.jobs.where((j) => j.status == JobStatus.completed).length;
        final recentJobs = store.jobs.take(2).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning,',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  letterSpacing: -0.5,
                  color: Color(0xFF2C2F30),
                ),
              ),
              Text(
                _companyName,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  letterSpacing: -0.5,
                  color: Color(0xFF176A21),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2C2F30).withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('$availableCount', 'Jobs\nAvailable'),
                    _buildDivider(),
                    _buildStatItem('$completedToday', 'Completed\nToday'),
                    _buildDivider(),
                    _buildStatItem('--', 'Efficiency\nRate'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Jobs',
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
              const SizedBox(height: 12),
              if (recentJobs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF1F2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.inbox_outlined,
                            color: Color(0xFFABACAE),
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No recent jobs',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF595C5D),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentJobs.map(
                  (job) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecentJobTile(
                      job.location,
                      job.statusLabel,
                      job.statusBgColor,
                      job.statusColor,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176A21),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.map, color: Color(0xFFD1FFC8)),
                  label: const Text(
                    'Find Nearby Jobs',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFD1FFC8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 28,
            color: Color(0xFF176A21),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFF595C5D),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 48, color: const Color(0xFFDADDDF));
  }

  Widget _buildRecentJobTile(
    String title,
    String status,
    Color statusBg,
    Color statusFg,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFFABACAE),
            ),
          ),
          const SizedBox(width: 16),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: statusFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Market Tab (Available Jobs from Admin) ───────────────────────────────

  Widget _buildMarketTab() {
    return Consumer<JobStore>(
      builder: (context, store, _) {
        final available = store.availableJobs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Jobs',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: Color(0xFF2C2F30),
                    ),
                  ),
                  if (available.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9DF197),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${available.length} open',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF005C15),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: available.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF1F2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.inbox_outlined,
                                color: Color(0xFFABACAE),
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No jobs available',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF2C2F30),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'When a market admin submits a waste report, it will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Color(0xFF595C5D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                      itemCount: available.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final job = available[i];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailsScreen(job: job),
                              ),
                            );
                          },
                          child: Container(
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
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF1F2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFABACAE),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job.location,
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF2C2F30),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${job.category} · ${job.volume}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          color: Color(0xFF595C5D),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        job.date,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: Color(0xFFABACAE),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFFABACAE),
                                ),
                              ],
                            ),
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

  // ── Activity Tab (Accepted Jobs) ──────────────────────────────────────────

  Widget _buildActivityTab() {
    return Consumer<JobStore>(
      builder: (context, store, _) {
        final active = store.acceptedJobs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Jobs',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: Color(0xFF2C2F30),
                    ),
                  ),
                  if (active.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10EAFE).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${active.length} active',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF005159),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: active.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF1F2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                color: Color(0xFFABACAE),
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No active jobs',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF2C2F30),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Accept a job from the Market tab and it will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Color(0xFF595C5D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                      itemCount: active.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final job = active[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF9DF197),
                              width: 1.5,
                            ),
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
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF9DF197,
                                  ).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.local_shipping,
                                  color: Color(0xFF005C15),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.location,
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF2C2F30),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${job.category} · ${job.volume}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: Color(0xFF595C5D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9DF197),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'IN PROGRESS',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Color(0xFF005C15),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const JobExecutionScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'View →',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Color(0xFF176A21),
                                      ),
                                    ),
                                  ),
                                ],
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

  // ── Profile Tab ───────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFF9DF197),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping,
                color: Color(0xFF005C15),
                size: 48,
              ),
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
                'Waste Collector',
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
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'COMPANY NAME',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
                color: Color(0xFF595C5D),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildEditableField(
            controller: TextEditingController(text: _companyName),
            hint: 'e.g. GreenHaul Ltd',
            icon: Icons.local_shipping_outlined,
            onSaved: (val) => _companyName = val,
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'LOCATION',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
                color: Color(0xFF595C5D),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildEditableField(
            controller: TextEditingController(text: _location),
            hint: 'e.g. Lusaka, Zambia',
            icon: Icons.location_on_outlined,
            onSaved: (val) => _location = val,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                setState(() {});
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
    required void Function(String) onSaved,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDADDDF)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onSaved,
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
}
