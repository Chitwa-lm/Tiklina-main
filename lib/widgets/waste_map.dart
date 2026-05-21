import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/gig_models.dart';
import '../services/realtime_service.dart';
import '../services/database_service.dart';

/// Widget displaying interactive map with waste requests and live collector locations
/// 
/// Features:
/// - Display nearby waste requests as map markers
/// - Show online collectors with real-time location updates
/// - Center map on user location
/// - Tap markers to view request details
/// - Realtime sync with Supabase subscriptions
class WasteMapWidget extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final double serviceRadius; // km
  final Function(WasteRequest)? onRequestTapped;
  final Function(CollectorProfile)? onCollectorTapped;

  const WasteMapWidget({
    Key? key,
    required this.initialLatitude,
    required this.initialLongitude,
    this.serviceRadius = 10.0,
    this.onRequestTapped,
    this.onCollectorTapped,
  }) : super(key: key);

  @override
  State<WasteMapWidget> createState() => _WasteMapWidgetState();
}

class _WasteMapWidgetState extends State<WasteMapWidget> {
  late MapController _mapController;
  late RealtimeService _realtimeService;
  late DatabaseService _databaseService;

  List<WasteRequest> _nearbyRequests = [];
  List<CollectorProfile> _onlineCollectors = [];
  late LatLng _userLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _realtimeService = RealtimeService();
    _databaseService = DatabaseService();
    _userLocation = LatLng(widget.initialLatitude, widget.initialLongitude);

    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _loadNearbyRequests();
    await _subscribeToUpdates();
  }

  /// Load nearby waste requests from database
  Future<void> _loadNearbyRequests() async {
    try {
      final requests = await _databaseService.getWasteRequestsNearby(
        latitude: widget.initialLatitude,
        longitude: widget.initialLongitude,
        radiusKm: widget.serviceRadius,
      );

      setState(() {
        _nearbyRequests = requests;
      });
    } catch (e) {
      print('[WasteMapWidget] Error loading requests: $e');
    }
  }

  /// Load online collectors nearby
  Future<void> _loadOnlineCollectors() async {
    try {
      final collectors = await _databaseService.getOnlineCollectors(
        latitude: widget.initialLatitude,
        longitude: widget.initialLongitude,
        radiusKm: widget.serviceRadius,
      );

      setState(() {
        _onlineCollectors = collectors;
      });
    } catch (e) {
      print('[WasteMapWidget] Error loading collectors: $e');
    }
  }

  /// Subscribe to real-time updates
  Future<void> _subscribeToUpdates() async {
    // Subscribe to new requests
    _realtimeService.subscribeToNewRequests().listen((request) {
      if (!_nearbyRequests.any((r) => r.id == request.id)) {
        setState(() {
          _nearbyRequests.add(request);
        });
      }
    });

    // Subscribe to collector location updates
    // This would need to be enhanced in RealtimeService to support multiple collectors
    _realtimeService.subscribeToCollectorLocation().listen((session) {
      setState(() {
        final index = _onlineCollectors.indexWhere(
          (c) => c.id == session.collectorId,
        );
        if (index >= 0) {
          _onlineCollectors[index] = _onlineCollectors[index].copyWith(
            lastLocationLat: session.lastLocationLat,
            lastLocationLng: session.lastLocationLng,
          );
        }
      });
    });
  }

  /// Center map on user location
  Future<void> _centerOnUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final newLocation = LatLng(position.latitude, position.longitude);

      _mapController.move(newLocation, 16.0);
      setState(() {
        _userLocation = newLocation;
      });

      await _loadNearbyRequests();
      await _loadOnlineCollectors();
    } catch (e) {
      print('[WasteMapWidget] Error centering map: $e');
    }
  }

  /// Build request markers
  List<Marker> _buildRequestMarkers() {
    return _nearbyRequests.map((request) {
      return Marker(
        point: LatLng(request.locationLat, request.locationLng),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => widget.onRequestTapped?.call(request),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 8,
                )
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete, color: Colors.green, size: 20),
                  Text(
                    '\$${request.estimatedCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Build collector markers
  List<Marker> _buildCollectorMarkers() {
    return _onlineCollectors.map((collector) {
      return Marker(
        point: LatLng(collector.lastLocationLat, collector.lastLocationLng),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => widget.onCollectorTapped?.call(collector),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 8,
                )
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, color: Colors.blue, size: 20),
                  Text(
                    '⭐ ${collector.averageRating.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Build user location marker
  List<Marker> _buildUserMarker() {
    return [
      Marker(
        point: _userLocation,
        width: 80,
        height: 80,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red[100],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 8,
              )
            ],
          ),
          child: const Center(
            child: Icon(Icons.location_on, color: Colors.red, size: 24),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _userLocation,
            zoom: 16.0,
            maxZoom: 18.0,
            minZoom: 10.0,
          ),
          children: [
            // OpenStreetMap tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tiklina.app',
            ),

            // Service radius circle
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _userLocation,
                  color: Colors.blue.withOpacity(0.1),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 1,
                  radius: widget.serviceRadius * 100, // Approximate pixel conversion
                )
              ],
            ),

            // Markers layer
            MarkerLayer(
              markers: [
                ..._buildUserMarker(),
                ..._buildRequestMarkers(),
                ..._buildCollectorMarkers(),
              ],
            ),
          ],
        ),

        // Center on user location button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.blue,
            onPressed: _centerOnUserLocation,
            child: const Icon(Icons.my_location),
          ),
        ),

        // Legend
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Requests', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Collectors', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _realtimeService.unsubscribeAll();
    super.dispose();
  }
}

/// Extension to allow copying with nullable fields
extension CollectorProfileCopy on CollectorProfile {
  CollectorProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? photoUrl,
    double? averageRating,
    int? totalCollections,
    double? serviceRadiusKm,
    bool? isOnline,
    double? lastLocationLat,
    double? lastLocationLng,
    DateTime? onlineSince,
    String? bankAccount,
  }) {
    return CollectorProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      averageRating: averageRating ?? this.averageRating,
      totalCollections: totalCollections ?? this.totalCollections,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      isOnline: isOnline ?? this.isOnline,
      lastLocationLat: lastLocationLat ?? this.lastLocationLat,
      lastLocationLng: lastLocationLng ?? this.lastLocationLng,
      onlineSince: onlineSince ?? this.onlineSince,
      bankAccount: bankAccount ?? this.bankAccount,
    );
  }
}
