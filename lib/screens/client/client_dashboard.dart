import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/gig_models.dart';
import '../../services/database_service.dart';
import '../../services/realtime_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/request_card.dart';
import 'post_request_wizard.dart';

/// Main client dashboard with tabbed interface
/// 
/// Tabs:
/// - Home: Active/recent requests, quick action to post
/// - History: Past requests with filtering
/// - Wallet: Balance, transaction history
/// - Profile: User info, ratings, settings
class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseService _databaseService;
  late PaymentService _paymentService;
  late RealtimeService _realtimeService;
  late SupabaseClient _supabase;

  List<WasteRequest> _myRequests = [];
  List<WasteRequest> _completedRequests = [];
  double _walletBalance = 0;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _databaseService = DatabaseService();
    _paymentService = PaymentService();
    _realtimeService = RealtimeService();
    _supabase = Supabase.instance.client;

    _userId = _supabase.auth.currentUser?.id;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_userId == null) return;

    try {
      // Load user's waste requests
      final requests = await _databaseService.getWasteRequestsByClient(_userId!);
      
      // Load wallet balance
      final balance = await _paymentService.getBalance(_userId!);

      setState(() {
        _myRequests = requests.where((r) => r.status != 'Completed' && r.status != 'Cancelled').toList();
        _completedRequests = requests.where((r) => r.status == 'Completed' || r.status == 'Cancelled').toList();
        _walletBalance = balance;
      });

      // Subscribe to real-time updates
      _realtimeService.subscribeToRequestUpdates().listen((request) {
        if (request.clientId == _userId) {
          setState(() {
            final index = _myRequests.indexWhere((r) => r.id == request.id);
            if (index >= 0) {
              _myRequests[index] = request;
            }
          });
        }
      });
    } catch (e) {
      print('[ClientDashboard] Error loading data: $e');
    }
  }

  /// Navigate to post request wizard
  Future<void> _navigateToPostRequest() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostRequestWizardScreen()),
    );

    if (result == true) {
      _loadInitialData(); // Refresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiklina - Request Waste Collection'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.grey[100],
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.home), text: 'Home'),
                Tab(icon: Icon(Icons.history), text: 'History'),
                Tab(icon: Icon(Icons.wallet), text: 'Wallet'),
                Tab(icon: Icon(Icons.person), text: 'Profile'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeTab(),
                _buildHistoryTab(),
                _buildWalletTab(),
                _buildProfileTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Home tab - show active requests and quick action
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready to get waste collected?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take photos and request collectors',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Post request button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToPostRequest,
              icon: const Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              label: const Text('Post New Request'),
            ),
          ),

          const SizedBox(height: 24),

          // Active requests
          Text(
            'Your Active Requests',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          if (_myRequests.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No active requests',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ...List.generate(
              _myRequests.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RequestCard(
                  request: _myRequests[index],
                  onTap: () => _showRequestDetails(_myRequests[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// History tab - completed requests
  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request History',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          if (_completedRequests.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No completed requests yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ...List.generate(
              _completedRequests.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RequestCard(
                  request: _completedRequests[index],
                  onTap: () => _showRequestDetails(_completedRequests[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Wallet tab - balance and transactions
  Widget _buildWalletTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wallet Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${_walletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Add funds button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment integration coming soon'),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle),
              label: const Text('Add Funds'),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          // Transaction list placeholder
          Container(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Transaction history will appear here',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  /// Profile tab - user info
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Client User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'user@example.com',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Settings
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy & Security'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {},
          ),

          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Show request details
  void _showRequestDetails(WasteRequest request) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Request Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: Navigator.of(context).pop,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RequestCard(request: request),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _realtimeService.unsubscribeAll();
    super.dispose();
  }
}
