import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<User?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    await _ensureOwnerDoc(uid: cred.user!.uid, name: name);
    return cred.user;
  }

  Future<User?> signInWithGoogle() async {
    if (!_googleInitialized) {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) return null;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final cred = await _auth.signInWithCredential(credential);
    await _ensureOwnerDoc(
      uid: cred.user!.uid,
      name: cred.user!.displayName ?? account.displayName ?? '',
    );
    return cred.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _ensureOwnerDoc({
    required String uid,
    required String name,
  }) async {
    final ref = _db.collection('owners').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': name,
        'businessName': '',
        'createdAt': FieldValue.serverTimestamp,
      });
    }
  }
}
