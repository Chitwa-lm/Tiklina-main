class JobAssignment {
  final String id;
  final String requestId;
  final String companyId;
  final DateTime acceptedAt;
  final DateTime scheduledPickupAt;

  JobAssignment({
    required this.id,
    required this.requestId,
    required this.companyId,
    required this.acceptedAt,
    required this.scheduledPickupAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'companyId': companyId,
      'acceptedAt': acceptedAt.toIso8601String(),
      'scheduledPickupAt': scheduledPickupAt.toIso8601String(),
    };
  }

  factory JobAssignment.fromMap(Map<String, dynamic> map) {
    return JobAssignment(
      id: map['id'],
      requestId: map['requestId'],
      companyId: map['companyId'],
      acceptedAt: DateTime.parse(map['acceptedAt']),
      scheduledPickupAt: DateTime.parse(map['scheduledPickupAt']),
    );
  }
}

class CollectionVerification {
  final String id;
  final String jobId;
  final String collectorPhotoUrl;
  final bool adminConfirmed;
  final DateTime confirmedAt;

  CollectionVerification({
    required this.id,
    required this.jobId,
    required this.collectorPhotoUrl,
    required this.adminConfirmed,
    required this.confirmedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'collectorPhotoUrl': collectorPhotoUrl,
      'adminConfirmed': adminConfirmed,
      'confirmedAt': confirmedAt.toIso8601String(),
    };
  }

  factory CollectionVerification.fromMap(Map<String, dynamic> map) {
    return CollectionVerification(
      id: map['id'],
      jobId: map['jobId'],
      collectorPhotoUrl: map['collectorPhotoUrl'],
      adminConfirmed: map['adminConfirmed'] ?? false,
      confirmedAt: DateTime.parse(map['confirmedAt']),
    );
  }
}
