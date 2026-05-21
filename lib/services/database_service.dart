import 'dart:math';
import 'supabase_service.dart';
import '../models/gig_models.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  DatabaseService._();

  final _supabase = SupabaseService.instance.client;

  // ==================== USER OPERATIONS ====================

  /// Create or update user profile
  Future<Map<String, dynamic>> upsertUserProfile({
    required String userId,
    required String role,
    required String phone,
    required String email,
    String? companyName,
    String? marketName,
    String? location,
    String? contactInfo,
  }) async {
    final profileData = {
      'user_id': userId,
      'role': role,
      'phone': phone,
      'email': email,
      'company_name': companyName,
      'market_name': marketName,
      'location': location,
      'contact_info': contactInfo,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _supabase.from('profiles').upsert(profileData).select().single();

    return response;
  }

  /// Get user profile by user ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  // ==================== WASTE REPORT OPERATIONS ====================

  /// Create a new waste report
  Future<Map<String, dynamic>> createWasteReport({
    required String reporterId,
    required String marketName,
    required double locationLat,
    required double locationLng,
    required String description,
    required String estVolume,
    List<String>? photoUrls,
  }) async {
    final reportData = {
      'reporter_id': reporterId,
      'market_name': marketName,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'description': description,
      'est_volume': estVolume,
      'status': 'Submitted',
      'reported_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('waste_reports')
        .insert(reportData)
        .select()
        .single();

    // If photos are provided, create evidence records
    if (photoUrls != null && photoUrls.isNotEmpty) {
      final reportId = response['id'];
      await _createReportEvidence(
        reportId: reportId,
        photoUrls: photoUrls,
        locationLat: locationLat,
        locationLng: locationLng,
      );
    }

    return response;
  }

  /// Create report evidence (photos)
  Future<void> _createReportEvidence({
    required String reportId,
    required List<String> photoUrls,
    required double locationLat,
    required double locationLng,
  }) async {
    final evidenceList = photoUrls
        .map(
          (url) => {
            'report_id': reportId,
            'photo_url': url,
            'location_lat': locationLat,
            'location_lng': locationLng,
            'timestamp': DateTime.now().toIso8601String(),
          },
        )
        .toList();

    await _supabase.from('report_evidence').insert(evidenceList);
  }

  /// Get all waste reports for a specific user
  Future<List<Map<String, dynamic>>> getWasteReportsByUser(
    String userId,
  ) async {
    final response = await _supabase
        .from('waste_reports')
        .select('*, report_evidence(*)')
        .eq('reporter_id', userId)
        .order('reported_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get all waste reports
  Future<List<Map<String, dynamic>>> getAllWasteReports() async {
    final response = await _supabase
        .from('waste_reports')
        .select()
        .order('reported_at', ascending: false);

    final reports = List<Map<String, dynamic>>.from(response);

    // For each report with accepted_by, get collector info from profiles
    for (final report in reports) {
      if (report['accepted_by'] != null) {
        try {
          final collectorProfile = await _supabase
              .from('profiles')
              .select('email')
              .eq('user_id', report['accepted_by'])
              .maybeSingle();

          if (collectorProfile != null) {
            report['collector'] = collectorProfile;
          }
        } catch (e) {
          // If we can't get collector info, just continue
        }
      }
    }

    return reports;
  }

  /// Get a single waste report with evidence
  Future<Map<String, dynamic>?> getWasteReportById(String reportId) async {
    final response = await _supabase
        .from('waste_reports')
        .select('*, report_evidence(*)')
        .eq('id', reportId)
        .maybeSingle();

    return response;
  }

  /// Update waste report status
  Future<void> updateWasteReportStatus({
    required String reportId,
    required String status,
  }) async {
    await _supabase
        .from('waste_reports')
        .update({'status': status}).eq('id', reportId);
  }

  /// Accept a waste report job (assign to collector)
  Future<void> acceptWasteReportJob({
    required String reportId,
    required String collectorId,
  }) async {
    await _supabase.from('waste_reports').update({
      'status': 'Accepted',
      'accepted_by': collectorId,
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  /// Get waste reports accepted by a specific collector
  Future<List<Map<String, dynamic>>> getWasteReportsByCollector(
    String collectorId,
  ) async {
    final response = await _supabase
        .from('waste_reports')
        .select()
        .eq('accepted_by', collectorId)
        .order('accepted_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== COLLECTION REQUEST OPERATIONS ====================

  /// Create a collection request from a waste report
  Future<Map<String, dynamic>> createCollectionRequest({
    required String reportId,
  }) async {
    final requestData = {
      'report_id': reportId,
      'status': 'Pending',
      'requested_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('collection_requests')
        .insert(requestData)
        .select()
        .single();

    return response;
  }

  /// Get all pending collection requests (for waste collectors)
  Future<List<Map<String, dynamic>>> getPendingCollectionRequests() async {
    final response = await _supabase.from('collection_requests').select('''
          *,
          waste_reports!inner(
            *,
            report_evidence(*)
          )
        ''').eq('status', 'Pending').order('requested_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update collection request status
  Future<void> updateCollectionRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await _supabase
        .from('collection_requests')
        .update({'status': status}).eq('id', requestId);
  }

  // ==================== JOB ASSIGNMENT OPERATIONS ====================

  /// Create a job assignment when a company accepts a request
  Future<Map<String, dynamic>> createJobAssignment({
    required String requestId,
    required String companyId,
    required DateTime scheduledPickupAt,
  }) async {
    final jobData = {
      'request_id': requestId,
      'company_id': companyId,
      'accepted_at': DateTime.now().toIso8601String(),
      'scheduled_pickup_at': scheduledPickupAt.toIso8601String(),
    };

    final response = await _supabase
        .from('job_assignments')
        .insert(jobData)
        .select()
        .single();

    // Update collection request status
    await updateCollectionRequestStatus(
      requestId: requestId,
      status: 'Accepted',
    );

    return response;
  }

  /// Get jobs for a specific company
  Future<List<Map<String, dynamic>>> getJobsByCompany(String companyId) async {
    final response = await _supabase.from('job_assignments').select('''
          *,
          collection_requests!inner(
            *,
            waste_reports!inner(
              *,
              report_evidence(*)
            )
          )
        ''').eq('company_id', companyId).order('accepted_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== COLLECTION VERIFICATION OPERATIONS ====================

  /// Create collection verification (after job completion)
  Future<Map<String, dynamic>> createCollectionVerification({
    required String jobId,
    required String collectorPhotoUrl,
  }) async {
    final verificationData = {
      'job_id': jobId,
      'collector_photo_url': collectorPhotoUrl,
      'admin_confirmed': false,
      'confirmed_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('collection_verifications')
        .insert(verificationData)
        .select()
        .single();

    return response;
  }

  /// Confirm collection by admin
  Future<void> confirmCollection({required String verificationId}) async {
    await _supabase
        .from('collection_verifications')
        .update({'admin_confirmed': true}).eq('id', verificationId);
  }

  // ==================== REVIEW OPERATIONS ====================

  /// Create a review for a completed job
  Future<Map<String, dynamic>> createReview({
    required String jobId,
    required String reviewerId,
    required String companyId,
    required int rating,
    required String comment,
  }) async {
    final reviewData = {
      'job_id': jobId,
      'reviewer_id': reviewerId,
      'company_id': companyId,
      'rating': rating,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _supabase.from('reviews').insert(reviewData).select().single();

    return response;
  }

  /// Get reviews for a company
  Future<List<Map<String, dynamic>>> getReviewsByCompany(
    String companyId,
  ) async {
    final response = await _supabase
        .from('reviews')
        .select('*')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get average rating for a company
  Future<double> getCompanyAverageRating(String companyId) async {
    final reviews = await getReviewsByCompany(companyId);

    if (reviews.isEmpty) return 0.0;

    final totalRating = reviews.fold<int>(
      0,
      (sum, review) => sum + (review['rating'] as int),
    );

    return totalRating / reviews.length;
  }

  // ==================== GIG ECONOMY: COLLECTOR SESSIONS ====================

  /// Collector goes online
  Future<Map<String, dynamic>> goOnline({
    required String collectorId,
    required double currentLat,
    required double currentLng,
  }) async {
    final sessionData = {
      'collector_id': collectorId,
      'online_at': DateTime.now().toIso8601String(),
      'is_active': true,
      'last_location_lat': currentLat,
      'last_location_lng': currentLng,
      'last_updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('collector_sessions')
        .insert(sessionData)
        .select()
        .single();

    // Update profile is_online status
    await _supabase
        .from('profiles')
        .update({'is_online': true})
        .eq('user_id', collectorId);

    return response;
  }

  /// Collector goes offline
  Future<void> goOffline(String collectorId) async {
    final session = await _supabase
        .from('collector_sessions')
        .select()
        .eq('collector_id', collectorId)
        .eq('is_active', true)
        .maybeSingle();

    if (session != null) {
      await _supabase
          .from('collector_sessions')
          .update({
            'is_active': false,
            'offline_at': DateTime.now().toIso8601String(),
          })
          .eq('id', session['id']);
    }

    // Update profile is_online status
    await _supabase
        .from('profiles')
        .update({'is_online': false})
        .eq('user_id', collectorId);
  }

  /// Update collector location
  Future<void> updateCollectorLocation({
    required String collectorId,
    required double lat,
    required double lng,
  }) async {
    final session = await _supabase
        .from('collector_sessions')
        .select()
        .eq('collector_id', collectorId)
        .eq('is_active', true)
        .maybeSingle();

    if (session != null) {
      await _supabase
          .from('collector_sessions')
          .update({
            'last_location_lat': lat,
            'last_location_lng': lng,
            'last_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', session['id']);
    }

    // Also update in profiles table
    await _supabase
        .from('profiles')
        .update({
          'last_location_lat': lat,
          'last_location_lng': lng,
        })
        .eq('user_id', collectorId);
  }

  /// Get active online collectors
  Future<List<Map<String, dynamic>>> getOnlineCollectors() async {
    final response = await _supabase
        .from('collector_sessions')
        .select()
        .eq('is_active', true)
        .order('last_updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== GIG ECONOMY: WASTE REQUESTS ====================

  /// Client creates a waste request
  Future<Map<String, dynamic>> createWasteRequest({
    required String clientId,
    required double locationLat,
    required double locationLng,
    String? locationAddress,
    required String wasteType,
    required String volumeCategory,
    required String description,
    required double estimatedCost,
    List<String>? photoUrls,
  }) async {
    final requestData = {
      'client_id': clientId,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'location_address': locationAddress,
      'waste_type': wasteType,
      'volume_category': volumeCategory,
      'description': description,
      'estimated_cost': estimatedCost,
      'status': 'Pending',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('waste_requests')
        .insert(requestData)
        .select()
        .single();

    // If photos provided, create request_photos records
    if (photoUrls != null && photoUrls.isNotEmpty) {
      await _createRequestPhotos(
        requestId: response['id'],
        photoUrls: photoUrls,
        photoType: 'client_submitted',
      );
    }

    return response;
  }

  /// Create request photos
  Future<void> _createRequestPhotos({
    required String requestId,
    required List<String> photoUrls,
    required String photoType,
  }) async {
    final photosList = photoUrls
        .map((url) => {
          'request_id': requestId,
          'photo_url': url,
          'photo_type': photoType,
          'created_at': DateTime.now().toIso8601String(),
        })
        .toList();

    await _supabase.from('request_photos').insert(photosList);
  }

  /// Get waste requests near collector (for dispatch)
  Future<List<Map<String, dynamic>>> getWasteRequestsNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    // Note: Supabase doesn't have built-in GIS, so we fetch all pending and filter client-side
    // For production, consider PostGIS extension
    final response = await _supabase
        .from('waste_requests')
        .select()
        .eq('status', 'Pending')
        .order('created_at', ascending: false);

    final requests = List<Map<String, dynamic>>.from(response);

    // Filter by approximate distance (simplified Haversine)
    final filtered = requests.where((req) {
      final reqLat = req['location_lat'] as double;
      final reqLng = req['location_lng'] as double;
      final distance = _calculateDistance(lat, lng, reqLat, reqLng);
      return distance <= radiusKm;
    }).toList();

    return filtered;
  }

  /// Get waste request by ID
  Future<Map<String, dynamic>?> getWasteRequestById(String requestId) async {
    final response = await _supabase
        .from('waste_requests')
        .select('*, request_photos(*)')
        .eq('id', requestId)
        .maybeSingle();

    return response;
  }

  /// Get waste requests by client
  Future<List<Map<String, dynamic>>> getWasteRequestsByClient(
    String clientId,
  ) async {
    final response = await _supabase
        .from('waste_requests')
        .select('*, request_photos(*)')
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update waste request status
  Future<void> updateWasteRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await _supabase
        .from('waste_requests')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  /// Cancel waste request
  Future<void> cancelWasteRequest({
    required String requestId,
    required String reason,
  }) async {
    await _supabase
        .from('waste_requests')
        .update({
          'status': 'Cancelled',
          'cancellation_reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  // ==================== GIG ECONOMY: REQUEST NOTIFICATIONS ====================

  /// Create request notification for collector
  Future<Map<String, dynamic>> createRequestNotification({
    required String requestId,
    required String collectorId,
    required double distanceKm,
    String? reason,
  }) async {
    final notificationData = {
      'request_id': requestId,
      'collector_id': collectorId,
      'notified_at': DateTime.now().toIso8601String(),
      'notification_status': 'Notified',
      'notification_reason': reason,
      'distance_km': distanceKm,
    };

    try {
      final response = await _supabase
          .from('request_notifications')
          .insert(notificationData)
          .select()
          .single();
      return response;
    } catch (e) {
      // Ignore duplicates (same collector already notified)
      rethrow;
    }
  }

  /// Get notifications for collector
  Future<List<Map<String, dynamic>>> getCollectorNotifications(
    String collectorId,
  ) async {
    final response = await _supabase
        .from('request_notifications')
        .select('*, waste_requests(*)')
        .eq('collector_id', collectorId)
        .in_('notification_status', ['Notified', 'Seen'])
        .order('notified_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update notification status
  Future<void> updateNotificationStatus({
    required String notificationId,
    required String status,
  }) async {
    await _supabase
        .from('request_notifications')
        .update({
          'notification_status': status,
          'seen_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId);
  }

  // ==================== GIG ECONOMY: WASTE PICKUPS ====================

  /// Accept waste request (create pickup)
  Future<Map<String, dynamic>> acceptWasteRequest({
    required String requestId,
    required String collectorId,
  }) async {
    // Update request status
    await _supabase
        .from('waste_requests')
        .update({
          'status': 'Accepted',
          'collector_id': collectorId,
          'accepted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);

    // Create waste pickup record
    final pickupData = {
      'request_id': requestId,
      'collector_id': collectorId,
      'status': 'Accepted',
      'accepted_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('waste_pickups')
        .insert(pickupData)
        .select()
        .single();

    return response;
  }

  /// Start trip (collector heading to client)
  Future<void> startPickupTrip(String pickupId) async {
    await _supabase
        .from('waste_pickups')
        .update({
          'status': 'In_Transit',
          'started_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', pickupId);

    // Also update request status
    final pickup =
        await _supabase
            .from('waste_pickups')
            .select('request_id')
            .eq('id', pickupId)
            .single();

    await _supabase
        .from('waste_requests')
        .update({
          'status': 'In_Transit',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', pickup['request_id']);
  }

  /// Complete pickup (add photo and mark complete)
  Future<void> completePickup({
    required String pickupId,
    required String completionPhotoUrl,
  }) async {
    await _supabase
        .from('waste_pickups')
        .update({
          'status': 'Completed',
          'completion_photo_url': completionPhotoUrl,
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', pickupId);

    // Also update request status
    final pickup =
        await _supabase
            .from('waste_pickups')
            .select('request_id')
            .eq('id', pickupId)
            .single();

    await _supabase
        .from('waste_requests')
        .update({
          'status': 'Completed',
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', pickup['request_id']);
  }

  /// Get pickups for collector
  Future<List<Map<String, dynamic>>> getPickupsByCollector(
    String collectorId,
  ) async {
    final response = await _supabase
        .from('waste_pickups')
        .select('*, waste_requests(*)')
        .eq('collector_id', collectorId)
        .order('accepted_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== GIG ECONOMY: WALLETS & TRANSACTIONS ====================

  /// Create or get wallet for user
  Future<Map<String, dynamic>> getOrCreateWallet(String userId) async {
    final existing = await _supabase
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      return existing;
    }

    // Create new wallet
    final walletData = {
      'user_id': userId,
      'balance': 0.0,
      'currency': 'USD',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('wallets')
        .insert(walletData)
        .select()
        .single();

    return response;
  }

  /// Get wallet balance
  Future<double> getWalletBalance(String userId) async {
    final wallet = await _supabase
        .from('wallets')
        .select('balance')
        .eq('user_id', userId)
        .maybeSingle();

    return wallet != null ? (wallet['balance'] as num).toDouble() : 0.0;
  }

  /// Process payment (client pays collector)
  Future<Map<String, dynamic>> processPayment({
    required String clientId,
    required String collectorId,
    required double amount,
    required String requestId,
  }) async {
    // Deduct from client wallet
    await _supabase
        .from('wallets')
        .update({
          'balance': _supabase.raw('balance - $amount'),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', clientId);

    // Add to collector wallet
    await _supabase
        .from('wallets')
        .update({
          'balance': _supabase.raw('balance + $amount'),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', collectorId);

    // Log transactions
    await createTransaction(
      userId: clientId,
      transactionType: 'Payment',
      amount: amount,
      relatedRequestId: requestId,
      description: 'Payment for waste collection',
    );

    await createTransaction(
      userId: collectorId,
      transactionType: 'Earning',
      amount: amount,
      relatedRequestId: requestId,
      description: 'Earned from waste collection',
    );

    final updatedWallet = await _supabase
        .from('wallets')
        .select()
        .eq('user_id', collectorId)
        .single();

    return updatedWallet;
  }

  /// Create transaction record
  Future<Map<String, dynamic>> createTransaction({
    required String userId,
    required String transactionType,
    required double amount,
    String? relatedRequestId,
    String? relatedPickupId,
    String? description,
    String? status,
  }) async {
    final transactionData = {
      'user_id': userId,
      'transaction_type': transactionType,
      'amount': amount,
      'currency': 'USD',
      'status': status ?? 'Completed',
      'related_request_id': relatedRequestId,
      'related_pickup_id': relatedPickupId,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
      'completed_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('transactions')
        .insert(transactionData)
        .select()
        .single();

    return response;
  }

  /// Get transactions for user
  Future<List<Map<String, dynamic>>> getTransactionsByUser(
    String userId,
  ) async {
    final response = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Request withdrawal
  Future<Map<String, dynamic>> requestWithdrawal({
    required String userId,
    required double amount,
    String? bankAccount,
  }) async {
    // Create withdrawal transaction
    final transactionData = {
      'user_id': userId,
      'transaction_type': 'Withdrawal',
      'amount': amount,
      'currency': 'USD',
      'status': 'Pending',
      'description': 'Withdrawal to bank account',
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('transactions')
        .insert(transactionData)
        .select()
        .single();

    return response;
  }

  // ==================== GIG ECONOMY: RATINGS ====================

  /// Create rating (client or collector rating each other)
  Future<Map<String, dynamic>> createRating({
    required String requestId,
    required String ratedById,
    required String ratedToId,
    required int rating,
    required String ratedRole,
    String? comment,
  }) async {
    final ratingData = {
      'request_id': requestId,
      'rated_by_id': ratedById,
      'rated_to_id': ratedToId,
      'rating': rating,
      'comment': comment,
      'rated_role': ratedRole,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('ratings')
        .insert(ratingData)
        .select()
        .single();

    return response;
  }

  /// Get ratings for user (as rated_to)
  Future<List<Map<String, dynamic>>> getRatingsForUser(String userId) async {
    final response = await _supabase
        .from('ratings')
        .select()
        .eq('rated_to_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get average rating for user
  Future<double> getUserAverageRating(String userId) async {
    final ratings = await getRatingsForUser(userId);

    if (ratings.isEmpty) return 0.0;

    final totalRating = ratings.fold<int>(
      0,
      (sum, rating) => sum + (rating['rating'] as int),
    );

    return totalRating / ratings.length;
  }

  // ==================== PROFILE HELPERS ====================

  /// Create or update user profile with full details
  Future<Map<String, dynamic>> createOrUpdateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? userRole,
    String? photoUrl,
    double? serviceRadiusKm,
  }) async {
    final data = <String, dynamic>{
      'id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullName != null) data['full_name'] = fullName;
    if (phoneNumber != null) data['phone'] = phoneNumber;
    if (userRole != null) data['user_role'] = userRole;
    if (photoUrl != null) data['photo_url'] = photoUrl;
    if (serviceRadiusKm != null) data['service_radius_km'] = serviceRadiusKm;

    try {
      final response =
          await _supabase.from('profiles').upsert(data).select().single();
      return response;
    } catch (e) {
      print('Error creating/updating profile: $e');
      rethrow;
    }
  }

  /// Get profile by ID
  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  // ==================== REQUEST PHOTO HELPERS ====================

  /// Get all photos for a waste request
  Future<List<RequestPhoto>> getRequestPhotos(String requestId) async {
    try {
      final response = await _supabase
          .from('request_photos')
          .select()
          .eq('request_id', requestId);

      return (response as List)
          .map((json) => RequestPhoto.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching request photos: $e');
      return [];
    }
  }

  // ==================== UTILITY FUNCTIONS ====================

  /// Calculate distance between two coordinates (simplified Haversine)
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
}
