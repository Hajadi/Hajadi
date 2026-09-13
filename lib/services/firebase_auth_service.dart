import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Android can resolve the SMS automatically; we keep the credential so
  /// [confirmPhoneCode] can complete without a typed code.
  final Map<String, PhoneAuthCredential> _autoCredentials =
      <String, PhoneAuthCredential>{};

  @override
  Stream<String?> authStateChanges() =>
      _auth.authStateChanges().map((User? user) => user?.uid);

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<String> signInWithEmail(String email, String password) =>
      _guard(() async {
        final UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return credential.user!.uid;
      });

  @override
  Future<String> signUpWithEmail(String email, String password) =>
      _guard(() async {
        final UserCredential credential =
            await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return credential.user!.uid;
      });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<String> signInWithGoogle() => _guard(() async {
        final GoogleSignInAccount? account = await _googleSignIn.signIn();
        if (account == null) {
          throw const AuthException('cancelled');
        }
        final GoogleSignInAuthentication auth = await account.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        final UserCredential result =
            await _auth.signInWithCredential(credential);
        return result.user!.uid;
      });

  @override
  Future<String> signInWithApple() => _guard(() async {
        final AuthorizationCredentialAppleID apple =
            await SignInWithApple.getAppleIDCredential(
          scopes: <AppleIDAuthorizationScopes>[
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
        final OAuthCredential credential = OAuthProvider('apple.com').credential(
          idToken: apple.identityToken,
          accessToken: apple.authorizationCode,
        );
        final UserCredential result =
            await _auth.signInWithCredential(credential);
        final String? givenName = apple.givenName;
        if (givenName != null && (result.user?.displayName ?? '').isEmpty) {
          await result.user?.updateDisplayName(
            '$givenName ${apple.familyName ?? ''}'.trim(),
          );
        }
        return result.user!.uid;
      });

  @override
  Future<String> startPhoneVerification(String phoneNumber) {
    final Completer<String> completer = Completer<String>();
    return _guard(() async {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          final String? id = credential.verificationId;
          if (id != null) {
            _autoCredentials[id] = credential;
          }
        },
        verificationFailed: (FirebaseAuthException error) {
          if (!completer.isCompleted) {
            completer.completeError(
              AuthException(error.code, error.message),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
      );
      return completer.future;
    });
  }

  @override
  Future<String> confirmPhoneCode(String verificationId, String smsCode) =>
      _guard(() async {
        final PhoneAuthCredential credential =
            _autoCredentials.remove(verificationId) ??
                PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: smsCode,
                );
        final User? current = _auth.currentUser;
        // An already signed-in user verifying their number links the phone to
        // the existing account instead of creating a second one.
        if (current != null && current.phoneNumber == null) {
          final UserCredential linked =
              await current.linkWithCredential(credential);
          return linked.user!.uid;
        }
        final UserCredential result =
            await _auth.signInWithCredential(credential);
        return result.user!.uid;
      });

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut().catchError((_) => null);
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() => _guard(() async {
        await _auth.currentUser?.delete();
      });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseAuthException catch (error) {
      throw AuthException(error.code, error.message);
    } on AuthException {
      rethrow;
    } catch (error) {
      throw AuthException('unknown', '$error');
    }
  }
}
