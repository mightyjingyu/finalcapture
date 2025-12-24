import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'interfaces/i_auth_service.dart';

class FirebaseAuthService implements IAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '797406662895-s2bhm10nh4gpkie9crcu37qdi9oq1ekh.apps.googleusercontent.com' : null,
    scopes: [
      'email',
      'profile',
    ],
  );
  // Will be renamed in next step (Actually already renamed in previous step, but I am fixing the mapping now)
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  @override
  UserModel? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: DateTime.now(), // Fallback
      lastLoginAt: DateTime.now(),
    );
  }
  
  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(), // Fallback
        lastLoginAt: DateTime.now(),
      );
    });
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          createdAt: userCredential.additionalUserInfo?.isNewUser == true 
              ? DateTime.now() 
              : DateTime.now(), // Firestore에서 가져와야 함
          lastLoginAt: DateTime.now(),
        );

        await _firestoreService.createOrUpdateUser(userModel);
        return userModel;
      }
    } catch (e) {
      print('Google Sign In Error: $e');
      rethrow;
    }
    return null;
  }

  @override
  Future<UserModel?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      final User? user = userCredential.user;

      if (user != null) {
        String? displayName = user.displayName;
        if (displayName == null && credential.givenName != null) {
          displayName = '${credential.givenName} ${credential.familyName ?? ''}'.trim();
          await user.updateDisplayName(displayName);
        }

        final userModel = UserModel(
          uid: user.uid,
          email: user.email!,
          displayName: displayName,
          photoUrl: user.photoURL,
          createdAt: userCredential.additionalUserInfo?.isNewUser == true 
              ? DateTime.now() 
              : DateTime.now(), // Firestore에서 가져와야 함
          lastLoginAt: DateTime.now(),
        );

        await _firestoreService.createOrUpdateUser(userModel);
        return userModel;
      }
    } catch (e) {
      print('Apple Sign In Error: $e');
      rethrow;
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Firestore에서 사용자 데이터 삭제
      await _firestoreService.deleteUser(user.uid);
      
      // Firebase Auth에서 계정 삭제
      await user.delete();
    }
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await _firestoreService.getUser(user.uid);
    }
    return null;
  }

  @override
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);
      
      // Firestore에도 업데이트
      final currentUserData = await _firestoreService.getUser(user.uid);
      if (currentUserData != null) {
        final updatedUser = currentUserData.copyWith(
          displayName: displayName,
          photoUrl: photoUrl,
        );
        await _firestoreService.createOrUpdateUser(updatedUser);
      }
    }
  }
}
