import 'dart:async';

import '../domain/auth_service.dart';
import '../domain/auth_user.dart';

/// In-memory auth for widget/unit tests and Firebase-less local UI work.
class FakeAuthService implements AuthService {
  FakeAuthService({AuthUser? initialUser}) : _user = initialUser {
    _controller.add(_user);
  }

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
    return 'fake-id-token-${_user!.uid}';
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    const user = AuthUser(
      uid: 'fake-uid',
      email: 'devotee@example.com',
      displayName: 'Test Devotee',
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
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
