import 'dart:io';
import 'package:flutter/foundation.dart';

enum UserRole { admin, collector }

class AppUser {
  final String email;
  final String password; // plain text — fine for local demo
  final UserRole role;
  final String name;
  final String location;
  final File? marketImage;

  const AppUser({
    required this.email,
    required this.password,
    required this.role,
    required this.name,
    required this.location,
    this.marketImage,
  });
}

class AuthStore extends ChangeNotifier {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  final List<AppUser> _users = [];
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Returns null on success, error message on failure.
  String? register(AppUser user) {
    final exists = _users.any(
      (u) => u.email.toLowerCase() == user.email.toLowerCase(),
    );
    if (exists) return 'An account with this email already exists.';
    _users.add(user);
    notifyListeners();
    return null;
  }

  /// Returns null on success, error message on failure.
  String? login(String email, String password) {
    try {
      final user = _users.firstWhere(
        (u) =>
            u.email.toLowerCase() == email.toLowerCase() &&
            u.password == password,
      );
      _currentUser = user;
      notifyListeners();
      return null;
    } catch (_) {
      return 'Incorrect email or password.';
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
