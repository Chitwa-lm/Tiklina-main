import 'dart:async';
import 'dart:math';
import 'database_service.dart';
import 'realtime_service.dart';
import '../models/gig_models.dart';

/// Score model for sorting collectors
class CollectorScore {
  final String collectorId;
  final double score;
  final double distanceKm;
  final double? averageRating;
  final int activeMinutes;

  CollectorScore({
    required this.collectorId,
    required this.score,
    required this.distanceKm,
    required this.averageRating,
    required this.activeMinutes,
  });

  @override
  String toString() =>
      'CollectorScore(id: $collectorId, score: ${score.toStringAsFixed(2)}, distance: ${distanceKm.toStringAsFixed(1)}km, rating: ${averageRating?.toStringAsFixed(1) ?? "N/A"}, activeMin: $activeMinutes)';
}

class DispatchService {
  static DispatchService? _instance;
  static DispatchService get instance {
    _instance ??= DispatchService._();
    return _instance!;
  }

  DispatchService._();

  final _dbService = DatabaseService.instance;
  final _realtimeService = RealtimeService.instance;

  // Configuration
  static const int initialWaveSize = 3; // Notify 3 collectors per wave
  static const int waveTimeoutSeconds = 30;
  static const int totalTimeoutSeconds = 300; // 5 minutes
  static const double initialRadiusKm = 5;
  static const double radiusExpansionKm = 2;

  // Dispatch tracking
  final Map<String, DispatchContext> _dispatchContexts = {};

  // ==================== DISPATCH ENTRY POINT ====================

  /// Main entry point: Dispatch waste request to nearby collectors
  /// Called when client creates a waste request
  Future<void> dispatchRequest({
    required String requestId,
    required double clientLat,
    required double clientLng,
  }) async {
    print('[DISPATCH] Starting dispatch for request: $requestId');

    // Create dispatch context
    final context = DispatchContext(
      requestId: requestId,
      clientLat: clientLat,
      clientLng: clientLng,
      startTime: DateTime.now(),
    );

    _dispatchContexts[requestId] = context;

    // Start first wave
    await _notifyNextWave(context);
  }

  // ==================== WAVE NOTIFICATION SYSTEM ====================

  /// Notify next batch of collectors
  Future<void> _notifyNextWave(DispatchContext context) async {
    final waveNum = context.waveNumber;
    final currentRadius = initialRadiusKm + (waveNum * radiusExpansionKm);

    print('[DISPATCH] Wave $waveNum for request ${context.requestId}, radius: ${currentRadius}km');

    // Get online collectors in expanded radius
    final onlineCollectors = await _dbService.getOnlineCollectors();

    // Filter by distance
    final nearbyCollectors = onlineCollectors.where((collector) {
      final collectorLat = collector['last_location_lat'] as double?;
      final collectorLng = collector['last_location_lng'] as double?;

      if (collectorLat == null || collectorLng == null) return false;

      final distance = _calculateDistance(
        context.clientLat,
        context.clientLng,
        collectorLat,
        collectorLng,
      );

      return distance <= currentRadius;
    }).toList();

    if (nearbyCollectors.isEmpty) {
      print('[DISPATCH] No nearby collectors found in wave $waveNum');
      await _handleNoCollectorsAvailable(context);
      return;
    }

    // Score and sort collectors
    final scoredCollectors = await _scoreCollectors(
      nearbyCollectors,
      context.clientLat,
      context.clientLng,
    );

    print('[DISPATCH] Scored collectors: $scoredCollectors');

    // Get batch for this wave
    final waveStart = waveNum * initialWaveSize;
    final waveBatch = scoredCollectors
        .skip(waveStart)
        .take(initialWaveSize)
        .toList();

    if (waveBatch.isEmpty) {
      print('[DISPATCH] No more collectors available in wave $waveNum');
      await _handleNoCollectorsAvailable(context);
      return;
    }

    // Notify batch
    context.currentWaveBatch = waveBatch;
    context.waveNumber++;

    for (final collectorScore in waveBatch) {
      await _notifyCollector(context, collectorScore);
    }

    // Start timer for this wave
    _startWaveTimer(context);
  }

  /// Notify individual collector
  Future<void> _notifyCollector(
    DispatchContext context,
    CollectorScore collectorScore,
  ) async {
    try {
      print('[DISPATCH] Notifying collector ${collectorScore.collectorId}');

      // Create notification record
      await _dbService.createRequestNotification(
        requestId: context.requestId,
        collectorId: collectorScore.collectorId,
        distanceKm: collectorScore.distanceKm,
        reason: 'Distance-based match',
      );

      // In production: Send push notification here
      // await NotificationService.sendPushNotification(...)

      context.notifiedCollectorIds.add(collectorScore.collectorId);
    } catch (e) {
      print('[DISPATCH] Error notifying collector: $e');
    }
  }

  /// Start timer for current wave
  void _startWaveTimer(DispatchContext context) {
    Timer(Duration(seconds: waveTimeoutSeconds), () async {
      print('[DISPATCH] Wave ${context.waveNumber - 1} timeout for request ${context.requestId}');

      // Check if request still pending
      final request = await _dbService.getWasteRequestById(context.requestId);
      if (request == null || request['status'] != 'Pending') {
        print('[DISPATCH] Request no longer pending, stopping dispatch');
        return;
      }

      // Check responses from current wave
      final responses = context.currentWaveBatch
          .map((collector) => collector.collectorId)
          .toList();

      // Count rejections (notifications that weren't accepted)
      int rejectionCount = 0;

      // If rejection count high, expand and retry
      if (rejectionCount >= 2) {
        print('[DISPATCH] High rejections ($rejectionCount), expanding radius');
        // Continue to next wave with expanded radius
        await _notifyNextWave(context);
      } else if (context.waveNumber < 3) {
        // Try next batch
        await _notifyNextWave(context);
      } else {
        // Timeout - cancel request
        print('[DISPATCH] Max waves reached, cancelling request');
        await _handleRequestTimeout(context);
      }
    });
  }

  // ==================== COLLECTOR ACCEPTANCE HANDLING ====================

  /// Handle collector accepting request
  /// Called from UI when collector taps Accept
  Future<void> handleCollectorAcceptance({
    required String requestId,
    required String collectorId,
  }) async {
    print('[DISPATCH] Collector $collectorId accepted request $requestId');

    final context = _dispatchContexts[requestId];
    if (context == null) {
      print('[DISPATCH] No context found for request $requestId');
      return;
    }

    // Mark acceptance
    context.acceptedCollectorId = collectorId;
    context.acceptedTime = DateTime.now();

    // Update request status to Accepted
    try {
      final pickup = await _dbService.acceptWasteRequest(
        requestId: requestId,
        collectorId: collectorId,
      );

      print('[DISPATCH] Pickup created: ${pickup['id']}');

      // Cancel other notifications
      await _cancelOtherNotifications(context, collectorId);

      // Clean up context
      _dispatchContexts.remove(requestId);

      print('[DISPATCH] Request $requestId successfully dispatched to $collectorId');
    } catch (e) {
      print('[DISPATCH] Error accepting request: $e');
      rethrow;
    }
  }

  /// Cancel notifications for other collectors
  Future<void> _cancelOtherNotifications(
    DispatchContext context,
    String acceptedCollectorId,
  ) async {
    // In production: Would update notification_status to 'Expired' for others
    // This signals to collectors that the request is no longer available
  }

  // ==================== TIMEOUT HANDLERS ====================

  /// Handle no collectors available
  Future<void> _handleNoCollectorsAvailable(DispatchContext context) async {
    print('[DISPATCH] No collectors available for request ${context.requestId}');

    await _dbService.cancelWasteRequest(
      requestId: context.requestId,
      reason: 'No collectors available within service radius',
    );

    _dispatchContexts.remove(context.requestId);
  }

  /// Handle total request timeout (5 minutes)
  Future<void> _handleRequestTimeout(DispatchContext context) async {
    print('[DISPATCH] Total timeout for request ${context.requestId}');

    final request = await _dbService.getWasteRequestById(context.requestId);
    if (request != null && request['status'] == 'Pending') {
      await _dbService.cancelWasteRequest(
        requestId: context.requestId,
        reason: 'No collectors accepted within 5 minutes',
      );
    }

    _dispatchContexts.remove(context.requestId);
  }

  // ==================== SCORING & SORTING ====================

  /// Score and sort collectors for dispatch
  /// Score = -(distance * 0.4) + (rating * 0.4) + (activeMinutes * 0.2) + random
  Future<List<CollectorScore>> _scoreCollectors(
    List<Map<String, dynamic>> collectors,
    double clientLat,
    double clientLng,
  ) async {
    final scored = <CollectorScore>[];

    for (final collector in collectors) {
      final collectorId = collector['collector_id'] as String;
      final collectorLat = (collector['last_location_lat'] as num).toDouble();
      final collectorLng = (collector['last_location_lng'] as num).toDouble();
      final onlineAt = DateTime.parse(collector['online_at'] as String);

      // Calculate distance
      final distance = _calculateDistance(
        clientLat,
        clientLng,
        collectorLat,
        collectorLng,
      );

      // Get collector average rating
      final avgRating = await _dbService.getUserAverageRating(collectorId);

      // Calculate active minutes
      final activeMinutes = DateTime.now().difference(onlineAt).inMinutes;

      // Calculate score
      final distancePenalty = -(distance * 0.4);
      final ratingBonus = (avgRating ?? 3.0) * 0.4;
      final activityBonus = (min(activeMinutes / 300, 1.0)) * 0.2;
      final randomTiebreaker = Random().nextDouble() * 0.01;

      final score =
          distancePenalty + ratingBonus + activityBonus + randomTiebreaker;

      scored.add(CollectorScore(
        collectorId: collectorId,
        score: score,
        distanceKm: distance,
        averageRating: avgRating,
        activeMinutes: activeMinutes,
      ));
    }

    // Sort by score (highest first)
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored;
  }

  // ==================== UTILITY FUNCTIONS ====================

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lng2 - lng1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R=6371 km
  }

  // ==================== CLEANUP ====================

  /// Get dispatch context for request (for testing)
  DispatchContext? getDispatchContext(String requestId) =>
      _dispatchContexts[requestId];

  /// Get active dispatch count (for monitoring)
  int get activeDispatchCount => _dispatchContexts.length;

  /// Clear all contexts (for cleanup)
  void clearAllContexts() {
    _dispatchContexts.clear();
  }
}

// ==================== DISPATCH CONTEXT ====================

/// Holds state for a single dispatch operation
class DispatchContext {
  final String requestId;
  final double clientLat;
  final double clientLng;
  final DateTime startTime;

  int waveNumber = 0;
  List<CollectorScore> currentWaveBatch = [];
  Set<String> notifiedCollectorIds = {};
  String? acceptedCollectorId;
  DateTime? acceptedTime;

  DispatchContext({
    required this.requestId,
    required this.clientLat,
    required this.clientLng,
    required this.startTime,
  });

  /// Check if dispatch has timed out (5 minutes)
  bool get isTimedOut =>
      DateTime.now().difference(startTime).inSeconds > 300;

  /// Get time elapsed
  Duration get elapsedTime => DateTime.now().difference(startTime);
}
