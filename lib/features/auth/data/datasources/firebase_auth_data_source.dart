import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_user.dart';

/// Contract for the Firebase Auth data source.
abstract class FirebaseAuthDataSource {
  /// Stream of the current Firebase [User?], mapped to [AppUser?].
  Stream<AppUser?> get authStateChanges;

  /// Returns the currently signed-in [AppUser], or `null`.
  AppUser? get currentUser;

  /// Signs in with [email] and [password].
  Future<AppUser> signIn({required String email, required String password});

  /// Creates a new account with [email] and [password].
  Future<AppUser> signUp({required String email, required String password});

  /// Signs out the current user.
  Future<void> signOut();

  /// Returns the current Firebase ID token, refreshing if needed.
  Future<String> getIdToken();
}

/// Concrete implementation wrapping [FirebaseAuth].
class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final FirebaseAuth _firebaseAuth;

  const FirebaseAuthDataSourceImpl(this._firebaseAuth);

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  AppUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const ServerException(message: 'Sign-in succeeded but no user returned.');
      }
      return _mapUserStrict(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const ServerException(message: 'Sign-up succeeded but no user returned.');
      }
      return _mapUserStrict(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<String> getIdToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const ServerException(message: 'No authenticated user for token retrieval.');
    }
    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw const ServerException(message: 'Firebase returned an empty ID token.');
      }
      return token;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // --- Mapping helpers --------------------------------------------------------

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return _mapUserStrict(user);
  }

  AppUser _mapUserStrict(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  AppException _mapFirebaseException(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-email' =>
        const ServerException(
          message: 'Credenciales inv�lidas.',
          code: 401,
        ),
      'email-already-in-use' => const ServerException(
          message: 'El email ya est� registrado.',
          code: 409,
        ),
      'weak-password' => const ServerException(
          message: 'La contrase�a es demasiado d�bil.',
          code: 400,
        ),
      'too-many-requests' => const ServerException(
          message: 'Demasiados intentos. Intent� m�s tarde.',
          code: 429,
        ),
      'network-request-failed' => const NetworkException(
          message: 'Sin conexi�n. Verific� tu red.',
        ),
      _ => ServerException(
          message: e.message ?? 'Error de autenticaci�n.',
          code: 500,
        ),
    };
  }
}
