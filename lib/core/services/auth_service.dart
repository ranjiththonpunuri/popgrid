import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Anonymous Auth.
/// Provides a stable session identity without requiring user login.
class AuthService {
  final FirebaseAuth _auth;
  String _displayName = 'Player';

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// The stable session ID (Firebase UID).
  String get sessionId => _auth.currentUser!.uid;

  /// The local display name.
  String get displayName => _displayName;

  /// Whether the user is authenticated.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Signs in anonymously. Call once at app startup.
  Future<void> initialize() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  /// Sets the local display name (not persisted to Firebase).
  void setDisplayName(String name) {
    _displayName = name.trim().isEmpty ? 'Player' : name.trim();
  }
}
