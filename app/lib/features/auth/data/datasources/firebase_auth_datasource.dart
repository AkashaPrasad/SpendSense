import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around the Firebase Auth + Google Sign-In SDKs. Throws the
/// SDKs' native exceptions — AuthRepositoryImpl is responsible for
/// translating those into domain AppFailures.
class FirebaseAuthDatasource {
  FirebaseAuthDatasource({fb.FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
      _googleSignInOverride = googleSignIn;

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn? _googleSignInOverride;

  /// Constructed lazily, on first actual use — not in the constructor.
  /// GoogleSignIn() throws synchronously on web when no OAuth client ID is
  /// configured yet (via a <meta name="google-signin-client_id"> tag), and
  /// this datasource is built as soon as any auth provider is read, i.e. at
  /// app boot. Eagerly constructing it there would crash the whole app
  /// before the user ever touched the Google button — deferring it means
  /// only an actual tap on "Continue with Google" can fail.
  GoogleSignIn? _googleSignIn;
  GoogleSignIn get _googleSignInInstance => _googleSignIn ??= _googleSignInOverride ?? GoogleSignIn();

  Stream<fb.User?> authStateChanges() => _firebaseAuth.authStateChanges();

  fb.User? get currentUser => _firebaseAuth.currentUser;

  Future<fb.User> signInWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    return credential.user!;
  }

  Future<fb.User> signUpWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    return credential.user!;
  }

  Future<fb.User> signInWithGoogle() async {
    final googleUser = await _googleSignInInstance.signIn();
    if (googleUser == null) {
      throw fb.FirebaseAuthException(code: 'cancelled', message: 'Sign-in was cancelled.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    return userCredential.user!;
  }

  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), if (_googleSignIn != null) _googleSignIn!.signOut()]);
  }
}
