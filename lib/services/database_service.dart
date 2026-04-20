import 'supabase_service.dart';

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

  /// Get all waste reports (for syncing to JobStore)
  Future<List<Map<String, dynamic>>> getAllWasteReports() async {
    final response = await _supabase
        .from('waste_reports')
        .select()
        .order('reported_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
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
}
