class UserModel {
  final String id;
  final String role; // 'Admin', 'Company', 'Council'
  final String phone;
  final String email;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.role,
    required this.phone,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'phone': phone,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      role: map['role'],
      phone: map['phone'],
      email: map['email'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class UserProfile {
  final String id;
  final String userId;
  final String? companyName;
  final String? marketName;
  final String? location;
  final String? contactInfo;

  UserProfile({
    required this.id,
    required this.userId,
    this.companyName,
    this.marketName,
    this.location,
    this.contactInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'companyName': companyName,
      'marketName': marketName,
      'location': location,
      'contactInfo': contactInfo,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      userId: map['userId'],
      companyName: map['companyName'],
      marketName: map['marketName'],
      location: map['location'],
      contactInfo: map['contactInfo'],
    );
  }
}
