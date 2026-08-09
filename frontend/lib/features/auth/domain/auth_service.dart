import 'auth_user.dart';

/// Abstraction over Firebase Auth + Google Sign-In.
///
/// Production: [FirebaseAuthService]. Tests: [FakeAuthService].
abstract class AuthService {
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  /// Returns a fresh Firebase ID token for API Authorization headers.
  Future<String?> getIdToken({bool forceRefresh = false});

  /// Required sign-in path: Google → Firebase credential.
  Future<AuthUser> signInWithGoogle();

  Future<void> updateProfile({String? displayName, String? photoUrl});

  Future<void> signOut();
}

