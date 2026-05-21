import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

/// Service for managing push notifications and in-app alerts
/// 
/// Handles:
/// - FCM push notifications for new requests/updates
/// - Local notifications for in-app alerts
/// - Device token management
/// - Notification routing and deep linking
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService();

  /// Notification type enum
  enum NotificationType {
    newRequest,           // New waste request available
    requestAccepted,      // Your request was accepted
    collectorArrived,     // Collector is nearby
    collectorCompleted,   // Job completed
    withdrawalApproved,   // Withdrawal approved
    withdrawalRejected,   // Withdrawal rejected
    ratingReminder,       // Reminder to rate
    newMessage,           // Chat message
    systemAlert,          // Platform announcement
  }

  // ==================== Initialization ====================

  /// Initialize notification service
  /// Call during app startup
  Future<void> initialize() async {
    // Initialize Firebase Cloud Messaging
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carryForwardNotificationSettings: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message (top-level function)
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification opened
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

    // Get and store device token
    await _updateDeviceToken();

    print('[NotificationService] Initialized successfully');
  }

  /// Update device token in database
  /// Called on app startup and when token refreshes
  Future<void> _updateDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) return;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Store token in profiles table
      await _supabase
          .from('profiles')
          .update({'device_token': token})
          .eq('id', userId);

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await _supabase
            .from('profiles')
            .update({'device_token': newToken})
            .eq('id', userId);
      });
    } catch (e) {
      print('[NotificationService] Error updating device token: $e');
    }
  }

  // ==================== Foreground Handling ====================

  /// Handle notification when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('[NotificationService] Foreground message: ${message.data}');

    final notification = message.notification;
    final data = message.data;

    // Show local notification
    await _showLocalNotification(
      title: notification?.title ?? 'New Update',
      body: notification?.body ?? '',
      payload: data,
    );
  }

  /// Handle background message (top-level function - required by FCM)
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('[NotificationService] Background message: ${message.data}');
    // Process in background - minimal work only
  }

  /// Handle notification opened from background
  Future<void> _handleNotificationOpened(RemoteMessage message) async {
    print('[NotificationService] Notification opened: ${message.data}');
    _routeNotification(message.data);
  }

  /// Handle local notification tap
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null) {
      _routeNotification(Map<String, dynamic>.from(
        Map<String, String>.fromEntries(
          payload.split('&').map((e) {
            final parts = e.split('=');
            return MapEntry(parts[0], parts[1]);
          }),
        ),
      ));
    }
  }

  /// Route notification to appropriate screen
  void _routeNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final requestId = data['request_id'] as String?;
    final pickupId = data['pickup_id'] as String?;

    // TODO: Implement navigation routing based on notification type
    // Example: context.go('/request/$requestId');

    switch (type) {
      case 'new_request':
        // Navigate to request details or queue
        break;
      case 'request_accepted':
        // Navigate to pickup tracking
        break;
      case 'collector_arrived':
        // Show alert with collector info
        break;
      case 'completion_reminder':
        // Navigate to completion screen
        break;
      default:
        break;
    }
  }

  // ==================== Sending Notifications ====================

  /// Send notification to specific user
  /// Used by backend when events occur
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, String>? customData,
  }) async {
    try {
      // Get user's device token
      final response = await _supabase
          .from('profiles')
          .select('device_token')
          .eq('id', userId)
          .single();

      final deviceToken = response['device_token'] as String?;
      if (deviceToken == null || deviceToken.isEmpty) {
        print('[NotificationService] No device token for user $userId');
        return;
      }

      // In production: send via Firebase Admin SDK or backend service
      // For now: store notification intent in database
      await _logNotification(
        userId: userId,
        title: title,
        body: body,
        type: type.name,
        customData: customData,
      );

      // Show local notification if app is installed
      await _showLocalNotification(
        title: title,
        body: body,
        payload: {'user_id': userId, 'type': type.name, ...?customData},
      );
    } catch (e) {
      print('[NotificationService] Error sending notification: $e');
    }
  }

  /// Send notification to multiple collectors
  /// Used for request dispatch
  Future<void> sendNotificationToCollectors({
    required List<String> collectorIds,
    required String title,
    required String body,
    required String requestId,
    required double distanceKm,
  }) async {
    try {
      for (final collectorId in collectorIds) {
        await sendNotificationToUser(
          userId: collectorId,
          title: title,
          body: body,
          type: NotificationType.newRequest,
          customData: {
            'request_id': requestId,
            'distance_km': distanceKm.toStringAsFixed(1),
          },
        );
      }
    } catch (e) {
      print('[NotificationService] Error sending batch notifications: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'tiklina_channel',
        'Tiklina Notifications',
        channelDescription: 'Notifications for requests and updates',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert payload to string for local notifications
      final payloadStr = payload.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: payloadStr,
      );
    } catch (e) {
      print('[NotificationService] Error showing local notification: $e');
    }
  }

  // ==================== Notification Logging ====================

  /// Log notification to database for analytics
  Future<void> _logNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, String>? customData,
  }) async {
    try {
      // Store in notifications table (create this table in schema if needed)
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'custom_data': customData,
        'sent_at': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {
      print('[NotificationService] Error logging notification: $e');
    }
  }

  /// Get unread notifications for current user
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('read', false)
          .order('sent_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('[NotificationService] Error fetching unread notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('[NotificationService] Error marking notification as read: $e');
    }
  }

  /// Clear all notifications for current user
  Future<void> clearAllNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('[NotificationService] Error clearing notifications: $e');
    }
  }

  // ==================== Request Notifications ====================

  /// Notify collector of new request
  Future<void> notifyNewRequest({
    required String collectorId,
    required String requestId,
    required String address,
    required double estimatedCost,
    required double distanceKm,
  }) async {
    final title = 'New Waste Collection Request';
    final body = '$address • ${estimatedCost.toStringAsFixed(0)} USD';

    await sendNotificationToUser(
      userId: collectorId,
      title: title,
      body: body,
      type: NotificationType.newRequest,
      customData: {
        'request_id': requestId,
        'distance_km': distanceKm.toStringAsFixed(1),
      },
    );
  }

  /// Notify client that request was accepted
  Future<void> notifyRequestAccepted({
    required String clientId,
    required String collectorName,
    required double collectorRating,
  }) async {
    final title = 'Request Accepted!';
    final body = '$collectorName (⭐ ${collectorRating.toStringAsFixed(1)}) is on the way';

    await sendNotificationToUser(
      userId: clientId,
      title: title,
      body: body,
      type: NotificationType.requestAccepted,
    );
  }

  /// Notify client that collector is arriving
  Future<void> notifyCollectorArriving({
    required String clientId,
    required String collectorName,
    required String arrivalMinutes,
  }) async {
    final title = 'Collector Arriving Soon';
    final body = '$collectorName arriving in ~$arrivalMinutes mins';

    await sendNotificationToUser(
      userId: clientId,
      title: title,
      body: body,
      type: NotificationType.collectorArrived,
    );
  }

  /// Notify client that collection is complete
  Future<void> notifyCollectionComplete({
    required String clientId,
    required String collectorName,
    required double amount,
  }) async {
    final title = 'Collection Complete!';
    final body = 'Thanks! $collectorName collected your waste. ${amount.toStringAsFixed(0)} USD charged';

    await sendNotificationToUser(
      userId: clientId,
      title: title,
      body: body,
      type: NotificationType.collectorCompleted,
      customData: {'amount': amount.toStringAsFixed(2)},
    );
  }

  /// Remind user to rate after completion
  Future<void> remindToRate({
    required String userId,
    required String otherUserName,
    required String requestId,
  }) async {
    final title = 'Rate Your Experience';
    final body = 'How was your experience with $otherUserName?';

    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.ratingReminder,
      customData: {'request_id': requestId},
    );
  }

  /// Notify collector of withdrawal approval
  Future<void> notifyWithdrawalApproved({
    required String collectorId,
    required double amount,
  }) async {
    final title = 'Withdrawal Approved';
    final body = '${amount.toStringAsFixed(2)} USD will be sent to your account';

    await sendNotificationToUser(
      userId: collectorId,
      title: title,
      body: body,
      type: NotificationType.withdrawalApproved,
    );
  }

  /// Notify collector of withdrawal rejection
  Future<void> notifyWithdrawalRejected({
    required String collectorId,
    required double amount,
    required String reason,
  }) async {
    final title = 'Withdrawal Rejected';
    final body = '${amount.toStringAsFixed(2)} USD - Reason: $reason';

    await sendNotificationToUser(
      userId: collectorId,
      title: title,
      body: body,
      type: NotificationType.withdrawalRejected,
    );
  }

  /// System-wide announcement
  Future<void> broadcastAnnouncement({
    required String title,
    required String body,
  }) async {
    // Fetch all active user device tokens and broadcast
    try {
      final users = await _supabase
          .from('profiles')
          .select('id, device_token')
          .neq('device_token', null);

      for (final user in (users as List)) {
        await sendNotificationToUser(
          userId: user['id'] as String,
          title: title,
          body: body,
          type: NotificationType.systemAlert,
        );
      }
    } catch (e) {
      print('[NotificationService] Error broadcasting announcement: $e');
    }
  }
}
