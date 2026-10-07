import 'package:firebase_auth/firebase_auth.dart';
import 'package:qio_app/services/auth_service.dart';

class FakeUser implements User {
  FakeUser({
    this.uid = 'uid-1',
    this.displayName,
    this.email = 'dono@qio.app',
    DateTime? createdAt,
  }) : metadata = UserMetadata(
         (createdAt ?? DateTime(2025, 3, 10)).millisecondsSinceEpoch,
         0,
       );

  @override
  final String uid;

  @override
  final String? displayName;

  @override
  final String? email;

  @override
  final UserMetadata metadata;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  FakeAuthService({this.user, this.error, this.signOutError});

  User? user;
  Object? error;
  Object? signOutError;
  final List<String> calls = [];

  @override
  User? get currentUser => user;

  @override
  Stream<User?> get authStateChanges => Stream.value(user);

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    calls.add('signIn:$email:$password');
    if (error != null) throw error!;
    return user;
  }

  @override
  Future<User?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    calls.add('signUp:$name:$email');
    if (error != null) throw error!;
    return user;
  }

  @override
  Future<User?> signInWithGoogle() async {
    calls.add('google');
    if (error != null) throw error!;
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    if (error != null) throw error!;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    if (signOutError != null) throw signOutError!;
  }
}
