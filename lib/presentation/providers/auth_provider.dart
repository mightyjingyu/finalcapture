import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  User? _firebaseUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Firebase Auth 상태 변화 리스너
    _authService.authStateChanges.listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  // 사용자 데이터 로드
  Future<void> _loadUserData(String uid) async {
    try {
      _currentUser = await _authService.getCurrentUserData();
    } catch (e) {
      _errorMessage = '사용자 정보를 불러오는데 실패했습니다: $e';
    }
    notifyListeners();
  }

  // Google 로그인
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      
      _currentUser = await _authService.signInWithGoogle();
      
      if (_currentUser != null) {
        return true;
      } else {
        _errorMessage = '로그인이 취소되었습니다.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Google 로그인 실패: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Apple 로그인
  Future<bool> signInWithApple() async {
    try {
      _setLoading(true);
      _clearError();
      
      _currentUser = await _authService.signInWithApple();
      
      if (_currentUser != null) {
        return true;
      } else {
        _errorMessage = '로그인이 취소되었습니다.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Apple 로그인 실패: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.signOut();
      _currentUser = null;
      _firebaseUser = null;
      
    } catch (e) {
      _errorMessage = '로그아웃 실패: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 계정 삭제
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.deleteAccount();
      _currentUser = null;
      _firebaseUser = null;
      
      return true;
    } catch (e) {
      _errorMessage = '계정 삭제 실패: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 프로필 업데이트
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.updateUserProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      
      // 로컬 사용자 정보 업데이트
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          displayName: displayName,
          photoUrl: photoUrl,
        );
      }
      
      return true;
    } catch (e) {
      _errorMessage = '프로필 업데이트 실패: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 사용자 권한 확인 및 요청
  Future<bool> checkAndRequestPermissions() async {
    try {
      _setLoading(true);
      _clearError();
      
      // PhotoService를 통한 권한 확인은 다른 Provider에서 처리
      return true;
      
    } catch (e) {
      _errorMessage = '권한 확인 실패: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
