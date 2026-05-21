import 'package:intl/intl.dart';

// ==================== WASTE REQUEST (Gig Model) ====================
class WasteRequest {
  final String id;
  final String clientId;
  final double locationLat;
  final double locationLng;
  final String? locationAddress;
  final String wasteType; // Household, Restaurant, Bar, Commercial, Other
  final String volumeCategory; // Small, Medium, Large
  final String description;
  final double estimatedCost;
  final String status; // Pending, Accepted, In_Transit, Completed, Cancelled
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? collectorId;
  final String? cancellationReason;
  final DateTime updatedAt;

  WasteRequest({
    required this.id,
    required this.clientId,
    required this.locationLat,
    required this.locationLng,
    this.locationAddress,
    required this.wasteType,
    required this.volumeCategory,
    required this.description,
    required this.estimatedCost,
    this.status = 'Pending',
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.collectorId,
    this.cancellationReason,
    required this.updatedAt,
  });

  factory WasteRequest.fromJson(Map<String, dynamic> json) {
    return WasteRequest(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      locationLat: (json['location_lat'] as num).toDouble(),
      locationLng: (json['location_lng'] as num).toDouble(),
      locationAddress: json['location_address'] as String?,
      wasteType: json['waste_type'] as String,
      volumeCategory: json['volume_category'] as String,
      description: json['description'] as String,
      estimatedCost: (json['estimated_cost'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      collectorId: json['collector_id'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'location_address': locationAddress,
      'waste_type': wasteType,
      'volume_category': volumeCategory,
      'description': description,
      'estimated_cost': estimatedCost,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'collector_id': collectorId,
      'cancellation_reason': cancellationReason,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ==================== REQUEST PHOTO ====================
class RequestPhoto {
  final String id;
  final String requestId;
  final String photoUrl;
  final String? photoType; // client_submitted, collector_before, collector_after
  final DateTime createdAt;

  RequestPhoto({
    required this.id,
    required this.requestId,
    required this.photoUrl,
    this.photoType,
    required this.createdAt,
  });

  factory RequestPhoto.fromJson(Map<String, dynamic> json) {
    return RequestPhoto(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      photoUrl: json['photo_url'] as String,
      photoType: json['photo_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'photo_url': photoUrl,
      'photo_type': photoType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ==================== COLLECTOR SESSION ====================
class CollectorSession {
  final String id;
  final String collectorId;
  final DateTime onlineAt;
  final DateTime? offlineAt;
  final bool isActive;
  final double? lastLocationLat;
  final double? lastLocationLng;
  final DateTime lastUpdatedAt;
  final int requestsNotified;
  final int requestsAccepted;

  CollectorSession({
    required this.id,
    required this.collectorId,
    required this.onlineAt,
    this.offlineAt,
    this.isActive = true,
    this.lastLocationLat,
    this.lastLocationLng,
    required this.lastUpdatedAt,
    this.requestsNotified = 0,
    this.requestsAccepted = 0,
  });

  factory CollectorSession.fromJson(Map<String, dynamic> json) {
    return CollectorSession(
      id: json['id'] as String,
      collectorId: json['collector_id'] as String,
      onlineAt: DateTime.parse(json['online_at'] as String),
      offlineAt: json['offline_at'] != null
          ? DateTime.parse(json['offline_at'] as String)
          : null,
      isActive: json['is_active'] as bool,
      lastLocationLat: (json['last_location_lat'] as num?)?.toDouble(),
      lastLocationLng: (json['last_location_lng'] as num?)?.toDouble(),
      lastUpdatedAt: DateTime.parse(json['last_updated_at'] as String),
      requestsNotified: json['requests_notified'] as int? ?? 0,
      requestsAccepted: json['requests_accepted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collector_id': collectorId,
      'online_at': onlineAt.toIso8601String(),
      'offline_at': offlineAt?.toIso8601String(),
      'is_active': isActive,
      'last_location_lat': lastLocationLat,
      'last_location_lng': lastLocationLng,
      'last_updated_at': lastUpdatedAt.toIso8601String(),
      'requests_notified': requestsNotified,
      'requests_accepted': requestsAccepted,
    };
  }
}

// ==================== REQUEST NOTIFICATION ====================
class RequestNotification {
  final String id;
  final String requestId;
  final String collectorId;
  final DateTime notifiedAt;
  final DateTime? seenAt;
  final String status; // Notified, Seen, Accepted, Rejected, Expired
  final String? reason;
  final double? distanceKm;

  RequestNotification({
    required this.id,
    required this.requestId,
    required this.collectorId,
    required this.notifiedAt,
    this.seenAt,
    this.status = 'Notified',
    this.reason,
    this.distanceKm,
  });

  factory RequestNotification.fromJson(Map<String, dynamic> json) {
    return RequestNotification(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      collectorId: json['collector_id'] as String,
      notifiedAt: DateTime.parse(json['notified_at'] as String),
      seenAt: json['seen_at'] != null
          ? DateTime.parse(json['seen_at'] as String)
          : null,
      status: json['notification_status'] as String,
      reason: json['notification_reason'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'collector_id': collectorId,
      'notified_at': notifiedAt.toIso8601String(),
      'seen_at': seenAt?.toIso8601String(),
      'notification_status': status,
      'notification_reason': reason,
      'distance_km': distanceKm,
    };
  }
}

// ==================== WASTE PICKUP (Gig Job) ====================
class WastePickup {
  final String id;
  final String requestId;
  final String collectorId;
  final String status; // Accepted, In_Transit, Completed, Cancelled
  final DateTime acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completionPhotoUrl;
  final DateTime updatedAt;

  WastePickup({
    required this.id,
    required this.requestId,
    required this.collectorId,
    this.status = 'Accepted',
    required this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.completionPhotoUrl,
    required this.updatedAt,
  });

  factory WastePickup.fromJson(Map<String, dynamic> json) {
    return WastePickup(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      collectorId: json['collector_id'] as String,
      status: json['status'] as String,
      acceptedAt: DateTime.parse(json['accepted_at'] as String),
      startedAt:
          json['started_at'] != null
              ? DateTime.parse(json['started_at'] as String)
              : null,
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'] as String)
              : null,
      completionPhotoUrl: json['completion_photo_url'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'collector_id': collectorId,
      'status': status,
      'accepted_at': acceptedAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'completion_photo_url': completionPhotoUrl,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ==================== WALLET ====================
class Wallet {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.currency = 'USD',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ==================== TRANSACTION ====================
class Transaction {
  final String id;
  final String userId;
  final String transactionType; // Payment, Earning, Withdrawal, Refund, Bonus
  final double amount;
  final String currency;
  final String status; // Pending, Completed, Failed, Rejected
  final String? relatedRequestId;
  final String? relatedPickupId;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.transactionType,
    required this.amount,
    this.currency = 'USD',
    this.status = 'Completed',
    this.relatedRequestId,
    this.relatedPickupId,
    this.description,
    required this.createdAt,
    this.completedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      transactionType: json['transaction_type'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String,
      relatedRequestId: json['related_request_id'] as String?,
      relatedPickupId: json['related_pickup_id'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'transaction_type': transactionType,
      'amount': amount,
      'currency': currency,
      'status': status,
      'related_request_id': relatedRequestId,
      'related_pickup_id': relatedPickupId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

// ==================== RATING (Gig Rating - both sides) ====================
class GigRating {
  final String id;
  final String requestId;
  final String ratedById;
  final String ratedToId;
  final int rating; // 1-5
  final String? comment;
  final String ratedRole; // Client or Collector
  final DateTime createdAt;

  GigRating({
    required this.id,
    required this.requestId,
    required this.ratedById,
    required this.ratedToId,
    required this.rating,
    this.comment,
    required this.ratedRole,
    required this.createdAt,
  });

  factory GigRating.fromJson(Map<String, dynamic> json) {
    return GigRating(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      ratedById: json['rated_by_id'] as String,
      ratedToId: json['rated_to_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      ratedRole: json['rated_role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'rated_by_id': ratedById,
      'rated_to_id': ratedToId,
      'rating': rating,
      'comment': comment,
      'rated_role': ratedRole,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ==================== COLLECTOR PROFILE (Extended from UserModel) ====================
class CollectorProfile {
  final String id;
  final String userId;
  final String name;
  final String? photoUrl;
  final double? averageRating;
  final int totalCollections;
  final int serviceRadiusKm;
  final bool isOnline;
  final double? lastLocationLat;
  final double? lastLocationLng;
  final DateTime onlineSince;
  final String? bankAccount;

  CollectorProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.averageRating,
    this.totalCollections = 0,
    this.serviceRadiusKm = 5,
    this.isOnline = false,
    this.lastLocationLat,
    this.lastLocationLng,
    required this.onlineSince,
    this.bankAccount,
  });

  factory CollectorProfile.fromJson(Map<String, dynamic> json) {
    return CollectorProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['company_name'] as String? ?? json['market_name'] as String? ?? 'Unknown',
      photoUrl: json['contact_info'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      totalCollections: json['total_collections'] as int? ?? 0,
      serviceRadiusKm: json['service_radius_km'] as int? ?? 5,
      isOnline: json['is_online'] as bool? ?? false,
      lastLocationLat: (json['last_location_lat'] as num?)?.toDouble(),
      lastLocationLng: (json['last_location_lng'] as num?)?.toDouble(),
      onlineSince: DateTime.parse(json['online_since'] as String? ?? DateTime.now().toIso8601String()),
      bankAccount: json['bank_account_number'] as String?,
    );
  }
}
