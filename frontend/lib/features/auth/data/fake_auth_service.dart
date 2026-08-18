import 'dart:async';

import '../domain/auth_service.dart';
import '../domain/auth_user.dart';

/// In-memory auth for widget/unit tests and Firebase-less local UI work.
///
/// Tokens match `npm run local` on the backend: `free` | `premium` | `admin`.
class FakeAuthService implements AuthService {
  FakeAuthService({
    AuthUser? initialUser,
    this.localBearerToken = 'premium',
  }) : _user = initialUser {
    _controller.add(_user);
  }

  /// Sent as `Authorization: Bearer …` to the local Node API.
  final String localBearerToken;

  AuthUser? _user;
  final _controller = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (_user == null) return null;
    // Email backdoor always hits the API as premium in local FakeAuth mode.
    if (_user!.uid == 'local-reviewer') return 'premium';
    return localBearerToken;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final user = AuthUser(
      uid: 'local-$localBearerToken',
      email: '$localBearerToken@local.test',
      displayName: 'Local ${localBearerToken[0].toUpperCase()}${localBearerToken.substring(1)}',
    );
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw StateError('Email and password are required.');
    }
    // Local / FakeAuth backdoor always acts as premium for API calls.
    final user = AuthUser(
      uid: 'local-reviewer',
      email: email.trim().toLowerCase(),
      displayName: 'Reviewer',
    );
    _user = user;
    _controller.add(user);
    return user;
  }

  /// Test helper to simulate an already-signed-in session.
  void emitUser(AuthUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final current = _user;
    if (current == null) throw StateError('Not signed in');
    _user = AuthUser(
      uid: current.uid,
      email: current.email,
      displayName: displayName ?? current.displayName,
      photoUrl: photoUrl ?? current.photoUrl,
    );
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
