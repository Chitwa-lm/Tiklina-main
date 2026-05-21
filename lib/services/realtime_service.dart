import 'package:supabase_flutter/supabase_flutter.dart';

typedef OnNewRequest = Function(Map<String, dynamic> request);
typedef OnStatusChange = Function(String requestId, String newStatus);
typedef OnLocationUpdate = Function(String collectorId, double lat, double lng);
typedef OnRequestAccepted = Function(String requestId, Map<String, dynamic> collectorData);

class RealtimeService {
  static RealtimeService? _instance;
  static RealtimeService get instance {
    _instance ??= RealtimeService._();
    return _instance!;
  }

  RealtimeService._();

  final _supabase = Supabase.instance.client;
  final Map<String, RealtimeChannel> _subscriptions = {};

  // ==================== SUBSCRIPTION MANAGEMENT ====================

  /// Subscribe to new waste requests in an area
  /// Listens for all Pending waste requests
  RealtimeChannel subscribeToNewRequests({
    required Function(Map<String, dynamic>) onNewRequest,
    required Function(String) onError,
  }) {
    final channel = _supabase.channel('waste_requests:status=eq.Pending')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'waste_requests',
          filter: 'status=eq.Pending',
        ),
        (payload, [ref]) {
          final newRequest = payload.newRecord;
          onNewRequest(newRequest);
        },
      )
      ..subscribe(
        onError: (err) => onError(err.toString()),
      );

    _subscriptions['waste_requests_new'] = channel;
    return channel;
  }

  /// Subscribe to waste request status updates
  RealtimeChannel subscribeToRequestUpdates({
    required String requestId,
    required Function(String, String) onStatusChange,
    required Function(String) onError,
  }) {
    final channel = _supabase.channel('waste_requests:id=eq.$requestId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'UPDATE',
          schema: 'public',
          table: 'waste_requests',
          filter: 'id=eq.$requestId',
        ),
        (payload, [ref]) {
          final newRecord = payload.newRecord;
          final newStatus = newRecord['status'] as String;
          onStatusChange(requestId, newStatus);
        },
      )
      ..subscribe(
        onError: (err) => onError(err.toString()),
      );

    _subscriptions['request_updates_$requestId'] = channel;
    return channel;
  }

  /// Subscribe to collector location updates
  /// Listens for updates to collector_sessions for a specific collector
  RealtimeChannel subscribeToCollectorLocation({
    required String collectorId,
    required Function(String, double, double) onLocationUpdate,
    required Function(String) onError,
  }) {
    final channel = _supabase.channel('collector_sessions:collector_id=eq.$collectorId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'UPDATE',
          schema: 'public',
          table: 'collector_sessions',
          filter: 'collector_id=eq.$collectorId',
        ),
        (payload, [ref]) {
          final updated = payload.newRecord;
          final lat = (updated['last_location_lat'] as num?)?.toDouble();
          final lng = (updated['last_location_lng'] as num?)?.toDouble();

          if (lat != null && lng != null) {
            onLocationUpdate(collectorId, lat, lng);
          }
        },
      )
      ..subscribe(
        onError: (err) => onError(err.toString()),
      );

    _subscriptions['collector_location_$collectorId'] = channel;
    return channel;
  }

  /// Subscribe to request acceptance events
  /// Listens for waste_pickups creations (when request is accepted)
  RealtimeChannel subscribeToRequestAcceptance({
    required String requestId,
    required Function(String requestId, Map<String, dynamic> collectorData) onAccepted,
    required Function(String) onError,
  }) {
    final channel = _supabase.channel('waste_pickups:request_id=eq.$requestId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'waste_pickups',
          filter: 'request_id=eq.$requestId',
        ),
        (payload, [ref]) {
          final pickup = payload.newRecord;
          // You might want to fetch collector profile separately
          onAccepted(requestId, pickup);
        },
      )
      ..subscribe(
        onError: (err) => onError(err.toString()),
      );

    _subscriptions['request_acceptance_$requestId'] = channel;
    return channel;
  }

  /// Subscribe to request notifications for a collector
  /// Listens for new request_notifications for this collector
  RealtimeChannel subscribeToCollectorNotifications({
    required String collectorId,
    required Function(Map<String, dynamic>) onNewNotification,
    required Function(String) onError,
  }) {
    final channel = _supabase.channel('request_notifications:collector_id=eq.$collectorId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'request_notifications',
          filter: 'collector_id=eq.$collectorId',
        ),
        (payload, [ref]) {
          final notification = payload.newRecord;
          onNewNotification(notification);
        },
      )
      ..subscribe(
        onError: (err) => onError(err.toString()),
      );

    _subscriptions['collector_notifications_$collectorId'] = channel;
    return channel;
  }

  /// Subscribe to waste pickup status updates (for tracking)
  RealtimeChannel subscribeToPickupUpdates({
    required String pickupId,
    required Function(String, String) onStatusChange,
    required Function(String) onError,
  }) {
    final channel = _supabase.channel('waste_pickups:id=eq.$pickupId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'UPDATE',
          schema: 'public',
          table: 'waste_pickups',
          filter: 'id=eq.$pickupId',
        ),
        (payload, [ref]) {
          final updated = payload.newRecord;
          final newStatus = updated['status'] as String;
          onStatusChange(pickupId, newStatus);
        },
      )
      ..subscribe(
        onError: (err) => onError(err.toString()),
      );

    _subscriptions['pickup_updates_$pickupId'] = channel;
    return channel;
  }

  /// Subscribe to wallet balance changes
  RealtimeChannel subscribeToWalletUpdates({
    required String userId,
    required Function(double) onBalanceChange,
    required Function(String) onError,
  }) {
    final channel = _supabase.channel('wallets:user_id=eq.$userId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'UPDATE',
          schema: 'public',
          table: 'wallets',
          filter: 'user_id=eq.$userId',
        ),
        (payload, [ref]) {
          final updated = payload.newRecord;
          final balance = (updated['balance'] as num).toDouble();
          onBalanceChange(balance);
        },
      )
      ..subscribe(
        onError: (err) => onError(err.toString()),
      );

    _subscriptions['wallet_updates_$userId'] = channel;
    return channel;
  }

  // ==================== UNSUBSCRIBE OPERATIONS ====================

  /// Unsubscribe from a specific channel
  Future<void> unsubscribe(String subscriptionKey) async {
    final channel = _subscriptions[subscriptionKey];
    if (channel != null) {
      await _supabase.removeChannel(channel);
      _subscriptions.remove(subscriptionKey);
    }
  }

  /// Unsubscribe from all subscriptions
  Future<void> unsubscribeAll() async {
    for (final key in _subscriptions.keys.toList()) {
      await unsubscribe(key);
    }
    _subscriptions.clear();
  }

  // ==================== HELPER: Broadcast Events (for testing/manual triggering) ====================

  /// Manually publish a request created event (for testing)
  void publishRequestCreated(Map<String, dynamic> requestData) {
    // In production, these would be triggered by database changes
    // This is a placeholder for testing
  }

  /// Manually publish a request accepted event (for testing)
  void publishRequestAccepted({
    required String requestId,
    required Map<String, dynamic> collectorData,
  }) {
    // Placeholder for testing
  }

  /// Manually publish a location update event (for testing)
  void publishLocationUpdate({
    required String collectorId,
    required double lat,
    required double lng,
  }) {
    // Placeholder for testing
  }

  // ==================== SUBSCRIPTION GETTERS ====================

  /// Get count of active subscriptions (for debugging)
  int get activeSubscriptionsCount => _subscriptions.length;

  /// Get list of active subscription keys (for debugging)
  List<String> get activeSubscriptionKeys => _subscriptions.keys.toList();
}
