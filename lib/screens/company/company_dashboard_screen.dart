import 'package:flutter/material.dart';
import 'package:tiklini/services/database_service.dart';
import 'package:tiklini/services/supabase_service.dart';
import 'package:tiklini/screens/auth/login_screen.dart';
import 'package:tiklini/screens/company/job_execution_screen.dart';

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
  int _selectedIndex = 0;

  late String _companyName;
  late String _location;

  // Reports loaded from database
  List<Map<String, dynamic>> _availableReports = [];
  List<Map<String, dynamic>> _acceptedReports = [];
  bool _isLoadingReports = false;

  @override
  void initState() {
    super.initState();
    _companyName = widget.companyName;
    _location = widget.location;
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get all reports for market tab (available to all collectors)
      final allReports = await DatabaseService.instance.getAllWasteReports();

      // Get reports accepted by this specific collector
      final myAcceptedReports =
          await DatabaseService.instance.getWasteReportsByCollector(userId);

      setState(() {
        // Available reports: Submitted status only (not accepted by anyone)
        _availableReports =
            allReports.where((r) => r['status'] == 'Submitted').toList();

        // Accepted reports: Only reports accepted by this collector
        _acceptedReports = myAcceptedReports
            .where((r) =>
                r['status'] == 'Accepted' ||
                r['status'] == 'In Progress' ||
                r['status'] == 'Completed')
            .toList();
        _isLoadingReports = false;
      });

      // Reports loaded successfully
    } catch (e) {
      setState(() => _isLoadingReports = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: const Color(0xFFB02500),
          ),
        );
      }
    }
  }

  Future<void> _acceptJob(String reportId) async {
    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await DatabaseService.instance.acceptWasteReportJob(
        reportId: reportId,
        collectorId: userId,
      );
      await _loadReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job accepted! Check Activity tab to manage it.'),
            backgroundColor: Color(0xFF176A21),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept job: $e'),
            backgroundColor: Color(0xFFB02500),
          ),
        );
      }
    }
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
    final availableCount = _availableReports.length;
    final inProgressReports = _acceptedReports
        .where((r) => r['status'] == 'Accepted' || r['status'] == 'In Progress')
        .toList();
    final completedReports =
        _acceptedReports.where((r) => r['status'] == 'Completed').toList();
    final inProgressCount = inProgressReports.length;
    final completedCount = completedReports.length;
    final totalJobs = inProgressCount + completedCount;

    final efficiency = totalJobs > 0
        ? ((completedCount / totalJobs) * 100).toStringAsFixed(0)
        : '0';

    final earnings = completedCount * 50;

    final volumeMap = {
      'Small Bag': 5,
      'Car Trunk': 30,
      'Pickup': 80,
      'Truck Load': 200,
      'Multiple': 400,
    };
    final totalKg = completedReports.fold<int>(
      0,
      (sum, r) {
        final volume = r['est_volume'] as String? ?? '';
        return sum + (volumeMap[volume] ?? 0);
      },
    );

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
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  label: 'Available',
                  value: '$availableCount',
                  icon: Icons.map_outlined,
                  color: const Color(0xFF176A21),
                  bgColor: const Color(0xFF9DF197).withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  label: 'In Progress',
                  value: '$inProgressCount',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFF005159),
                  bgColor: const Color(0xFF10EAFE).withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  label: 'Completed',
                  value: '$completedCount',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF005C15),
                  bgColor: const Color(0xFF9DF197).withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  label: 'Efficiency',
                  value: '$efficiency%',
                  icon: Icons.trending_up,
                  color: const Color(0xFF6E3A00),
                  bgColor: const Color(0xFFFFC698).withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  label: 'Waste Collected',
                  value: '${totalKg}kg',
                  icon: Icons.delete_sweep_outlined,
                  color: const Color(0xFF00656F),
                  bgColor: const Color(0xFF10EAFE).withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  label: 'Earnings',
                  value: '\$$earnings',
                  icon: Icons.attach_money,
                  color: const Color(0xFF176A21),
                  bgColor: const Color(0xFF9DF197).withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
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
                'Browse Available Jobs',
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
  }

  Widget _buildAnalyticsCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Color(0xFF595C5D),
            ),
          ),
        ],
      ),
    );
  }

  // ── Market Tab (Available Jobs from Admin) ───────────────────────────────

  Widget _buildMarketTab() {
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
              Row(
                children: [
                  if (_availableReports.isNotEmpty)
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
                        '${_availableReports.length} open',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF005C15),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _loadReports,
                    icon: const Icon(Icons.refresh),
                    color: const Color(0xFF176A21),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Waste reports from market admins',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF595C5D),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoadingReports
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: _availableReports.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(32),
                          children: [
                            Center(
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
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _loadReports,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Refresh'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF176A21),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                          itemCount: _availableReports.length,
                          itemBuilder: (context, i) {
                            final report = _availableReports[i];

                            // Safe parsing of date
                            String date = 'Unknown date';
                            try {
                              final reportedAt = report['reported_at'];
                              if (reportedAt != null) {
                                final reportDate =
                                    DateTime.parse(reportedAt.toString());
                                date =
                                    '${reportDate.day}/${reportDate.month}/${reportDate.year}';
                              }
                            } catch (e) {
                              // print('Error parsing date: $e');
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2C2F30)
                                        .withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF1F2),
                                          borderRadius:
                                              BorderRadius.circular(14),
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
                                              (report['market_name']
                                                      as String?) ??
                                                  'Unknown location',
                                              style: const TextStyle(
                                                fontFamily: 'Manrope',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF2C2F30),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              date,
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                color: Color(0xFFABACAE),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Color(0xFFEFF1F2)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildJobDetail(
                                        Icons.category_outlined,
                                        'Category',
                                        'Mixed Waste',
                                      ),
                                      const SizedBox(width: 20),
                                      _buildJobDetail(
                                        Icons.scale_outlined,
                                        'Volume',
                                        (report['est_volume'] as String?) ??
                                            'Unknown',
                                      ),
                                    ],
                                  ),
                                  if ((report['description'] as String? ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildSingleJobDetail(
                                      Icons.description_outlined,
                                      'Description',
                                      report['description'] as String,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final reportId = report['id'];
                                        if (reportId != null) {
                                          _acceptJob(reportId.toString());
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF176A21),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                      child: const Text(
                                        'Accept Job',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFFD1FFC8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildJobDetail(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF176A21)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF595C5D),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2F30),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleJobDetail(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF176A21)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF595C5D),
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2F30),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Activity Tab (Accepted Jobs) ──────────────────────────────────────────

  Widget _buildActivityTab() {
    final activeReports =
        _acceptedReports.where((r) => r['status'] != 'Completed').toList();

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
              if (activeReports.isNotEmpty)
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
                    '${activeReports.length} active',
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Update job status as you progress',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF595C5D),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoadingReports
              ? const Center(child: CircularProgressIndicator())
              : _acceptedReports.isEmpty
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
                      itemCount: _acceptedReports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final report = _acceptedReports[i];
                        final status =
                            (report['status'] as String?) ?? 'Unknown';
                        final isCompleted = status == 'Completed';

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF9DF197)
                                  : const Color(0xFF10EAFE)
                                      .withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2C2F30)
                                    .withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? const Color(0xFF9DF197)
                                              .withValues(alpha: 0.3)
                                          : const Color(0xFF10EAFE)
                                              .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      isCompleted
                                          ? Icons.check_circle
                                          : Icons.local_shipping,
                                      color: isCompleted
                                          ? const Color(0xFF005C15)
                                          : const Color(0xFF005159),
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
                                          (report['market_name'] as String?) ??
                                              'Unknown location',
                                          style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF2C2F30),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Mixed Waste · ${(report['est_volume'] as String?) ?? 'Unknown'}',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            color: Color(0xFF595C5D),
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                                      color: isCompleted
                                          ? const Color(0xFF9DF197)
                                              .withValues(alpha: 0.5)
                                          : const Color(0xFF10EAFE)
                                              .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: isCompleted
                                            ? const Color(0xFF005C15)
                                            : const Color(0xFF005159),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Color(0xFFEFF1F2)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                JobExecutionScreen(job: report),
                                          ),
                                        );
                                        // Refresh data if job was completed
                                        if (result == true) {
                                          _loadReports();
                                        }
                                      },
                                      icon: Icon(
                                        isCompleted
                                            ? Icons.visibility
                                            : Icons.work_outline,
                                        size: 18,
                                      ),
                                      label: Text(isCompleted
                                          ? 'View Details'
                                          : 'Execute Job'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF176A21),
                                        side: const BorderSide(
                                            color: Color(0xFF176A21)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
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
              onPressed: () async {
                await SupabaseService.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
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
