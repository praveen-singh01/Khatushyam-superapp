import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_service.dart';
import '../domain/auth_user.dart';

/// Firebase Authentication with required Google Sign-In.
///
/// Requires a real FlutterFire config (`flutterfire configure`) before use.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    // Web client ID from Firebase Google provider (required for ID tokens).
    await _googleSignIn.initialize(
      serverClientId:
          '191548396096-dvjb97icqrd5gjmq0pp04aj2gpig5325.apps.googleusercontent.com',
    );
    _googleInitialized = true;
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  @override
  AuthUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() =>
      _firebaseAuth.authStateChanges().map(_mapUser);

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google Sign-In did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _firebaseAuth.signInWithCredential(credential);
    final mapped = _mapUser(result.user);
    if (mapped == null) {
      throw StateError('Firebase sign-in succeeded without a user.');
    }
    return mapped;
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('Not signed in');
    if (displayName != null) await user.updateDisplayName(displayName);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);
    await user.reload();
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }
}
