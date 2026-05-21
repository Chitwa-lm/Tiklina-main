import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/gig_models.dart';
import '../../services/realtime_service.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_card.dart';

/// Collector Found screen - shows collector details and live tracking
/// 
/// Displayed when a collector accepts the waste collection request
/// Shows:
/// - Collector profile card with photo and rating
/// - Real-time location tracking on map
/// - Estimated arrival time
/// - Contact options
/// - Current pickup status
class CollectorFoundScreen extends StatefulWidget {
  final WasteRequest request;
  final WastePickup pickup;

  const CollectorFoundScreen({
    Key? key,
    required this.request,
    required this.pickup,
  }) : super(key: key);

  @override
  State<CollectorFoundScreen> createState() => _CollectorFoundScreenState();
}

class _CollectorFoundScreenState extends State<CollectorFoundScreen> {
  late DatabaseService _databaseService;
  late RealtimeService _realtimeService;
  late MapController _mapController;

  CollectorProfile? _collector;
  LatLng? _collectorLocation;
  LatLng? _requestLocation;
  int? _estimatedMinutes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _realtimeService = RealtimeService();
    _mapController = MapController();
    _requestLocation = LatLng(widget.request.locationLat, widget.request.locationLng);

    _loadCollectorData();
  }

  Future<void> _loadCollectorData() async {
    try {
      // Load collector profile
      final user = await _databaseService.getProfileById(widget.pickup.collectorId);
      if (user != null) {
        final collector = CollectorProfile(
          id: user['id'],
          userId: widget.pickup.collectorId,
          name: user['full_name'] ?? 'Collector',
          photoUrl: user['photo_url'] ?? '',
          averageRating: (user['average_rating'] as num?)?.toDouble() ?? 0,
          totalCollections: user['total_collections'] ?? 0,
          serviceRadiusKm: (user['service_radius_km'] as num?)?.toDouble() ?? 10,
          isOnline: user['is_online'] ?? false,
          lastLocationLat: (user['last_location_lat'] as num?)?.toDouble() ?? 0,
          lastLocationLng: (user['last_location_lng'] as num?)?.toDouble() ?? 0,
          onlineSince: user['online_since'] != null
              ? DateTime.parse(user['online_since'])
              : DateTime.now(),
          bankAccount: user['bank_account_number'] ?? '',
        );

        setState(() {
          _collector = collector;
          _collectorLocation = LatLng(collector.lastLocationLat, collector.lastLocationLng);
          _isLoading = false;
        });

        // Subscribe to location updates
        _subscribeToLocationUpdates();
      }
    } catch (e) {
      print('[CollectorFoundScreen] Error loading collector: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Subscribe to real-time collector location updates
  void _subscribeToLocationUpdates() {
    _realtimeService.subscribeToCollectorLocation().listen((session) {
      if (session.collectorId == widget.pickup.collectorId) {
        setState(() {
          _collectorLocation = LatLng(session.lastLocationLat, session.lastLocationLng);
          _updateEstimatedTime();
        });
      }
    });
  }

  /// Calculate estimated arrival time
  void _updateEstimatedTime() {
    if (_collectorLocation == null || _requestLocation == null) return;

    // Simple distance calculation
    final distance = _collectorLocation!.distanceTo(_requestLocation!) / 1000; // km

    // Assume average speed of 40 km/h
    final minutes = ((distance / 40) * 60).toInt();
    setState(() => _estimatedMinutes = minutes > 0 ? minutes : 1);
  }

  /// Call collector
  void _callCollector() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Call feature coming soon')),
    );
  }

  /// Message collector
  void _messageCollector() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat feature coming soon')),
    );
  }

  /// Cancel request
  void _cancelRequest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () async {
              await _databaseService.cancelWasteRequest(
                widget.request.id,
                'Client cancelled',
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collector Found')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_collector == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collector Found')),
        body: const Center(child: Text('Error loading collector details')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collector Found!'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map with live tracking
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _requestLocation,
                    zoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tiklina.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Request location
                        Marker(
                          point: _requestLocation!,
                          width: 80,
                          height: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.green, width: 3),
                            ),
                            child: const Center(
                              child: Icon(Icons.location_on, color: Colors.green, size: 24),
                            ),
                          ),
                        ),
                        // Collector location
                        if (_collectorLocation != null)
                          Marker(
                            point: _collectorLocation!,
                            width: 80,
                            height: 80,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    blurRadius: 8,
                                  )
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.person, color: Colors.blue, size: 24),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Estimated time card
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.blue),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated Arrival',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _estimatedMinutes != null
                                  ? '~${_estimatedMinutes} mins'
                                  : 'Calculating...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Collector info and actions
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collector profile snippet
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(_collector!.photoUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _collector!.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_collector!.averageRating.toStringAsFixed(1)} (${_collector!.totalCollections})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Collector Status',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                'En Route',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contact buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _messageCollector,
                          icon: const Icon(Icons.message),
                          label: const Text('Message'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _callCollector,
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _cancelRequest,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Cancel Request'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _realtimeService.unsubscribeAll();
    super.dispose();
  }
}
