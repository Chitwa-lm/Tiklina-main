class Review {
  final String id;
  final String jobId;
  final String reviewerId;
  final String companyId;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.jobId,
    required this.reviewerId,
    required this.companyId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'reviewerId': reviewerId,
      'companyId': companyId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      jobId: map['jobId'],
      reviewerId: map['reviewerId'],
      companyId: map['companyId'],
      rating: map['rating'] ?? 5,
      comment: map['comment'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
