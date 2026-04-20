class WasteReport {
  final String id;
  final String reporterId;
  final String marketName;
  final double locationLat;
  final double locationLng;
  final String description;
  final String estVolume;
  final String status; // 'Submitted', 'Acknowledged', 'Scheduled', 'Resolved'
  final DateTime reportedAt;

  WasteReport({
    required this.id,
    required this.reporterId,
    required this.marketName,
    required this.locationLat,
    required this.locationLng,
    required this.description,
    required this.estVolume,
    required this.status,
    required this.reportedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'marketName': marketName,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'description': description,
      'estVolume': estVolume,
      'status': status,
      'reportedAt': reportedAt.toIso8601String(),
    };
  }

  factory WasteReport.fromMap(Map<String, dynamic> map) {
    return WasteReport(
      id: map['id'],
      reporterId: map['reporterId'],
      marketName: map['marketName'],
      locationLat: map['locationLat']?.toDouble() ?? 0.0,
      locationLng: map['locationLng']?.toDouble() ?? 0.0,
      description: map['description'],
      estVolume: map['estVolume'],
      status: map['status'],
      reportedAt: DateTime.parse(map['reportedAt']),
    );
  }
}

class ReportEvidence {
  final String id;
  final String reportId;
  final String photoUrl;
  final double locationLat;
  final double locationLng;
  final DateTime timestamp;

  ReportEvidence({
    required this.id,
    required this.reportId,
    required this.photoUrl,
    required this.locationLat,
    required this.locationLng,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportId': reportId,
      'photoUrl': photoUrl,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ReportEvidence.fromMap(Map<String, dynamic> map) {
    return ReportEvidence(
      id: map['id'],
      reportId: map['reportId'],
      photoUrl: map['photoUrl'],
      locationLat: map['locationLat']?.toDouble() ?? 0.0,
      locationLng: map['locationLng']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class CollectionRequest {
  final String id;
  final String reportId;
  final String status; // 'Pending', 'Accepted', 'Completed'
  final DateTime requestedAt;

  CollectionRequest({
    required this.id,
    required this.reportId,
    required this.status,
    required this.requestedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportId': reportId,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }

  factory CollectionRequest.fromMap(Map<String, dynamic> map) {
    return CollectionRequest(
      id: map['id'],
      reportId: map['reportId'],
      status: map['status'],
      requestedAt: DateTime.parse(map['requestedAt']),
    );
  }
}
