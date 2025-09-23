import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '797406662895-s2bhm10nh4gpkie9crcu37qdi9oq1ekh.apps.googleusercontent.com' : null,
    scopes: [
      'email',
      'profile',
    ],
  );
  final FirestoreService _firestoreService = FirestoreService();

  // 현재 로그인된 사용자
  User? get currentUser => _auth.currentUser;
  
  // 사용자 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google 로그인
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

  // Apple 로그인
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

  // 로그아웃
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Firestore에서 사용자 데이터 삭제
      await _firestoreService.deleteUser(user.uid);
      
      // Firebase Auth에서 계정 삭제
      await user.delete();
    }
  }

  // 현재 사용자 정보 가져오기
  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await _firestoreService.getUser(user.uid);
    }
    return null;
  }

  // 사용자 프로필 업데이트
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
