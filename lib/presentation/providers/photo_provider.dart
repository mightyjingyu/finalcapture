import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/models/photo_model.dart';
import '../../data/services/photo_service.dart';
import '../../data/services/firestore_service.dart';

class PhotoProvider extends ChangeNotifier {
  final PhotoService _photoService = PhotoService();
  
  List<PhotoModel> _photos = [];
  List<PhotoModel> _recentPhotos = [];
  List<PhotoModel> _favoritePhotos = [];
  List<AssetEntity> _latestScreenshots = [];
  
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _hasPermissions = false;

  // Getters
  List<PhotoModel> get photos => _photos;
  List<PhotoModel> get recentPhotos => _recentPhotos;
  List<PhotoModel> get favoritePhotos => _favoritePhotos;
  List<AssetEntity> get latestScreenshots => _latestScreenshots;
  
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasPermissions => _hasPermissions;

  // 권한 확인 및 요청
  Future<bool> requestPermissions() async {
    try {
      _setLoading(true);
      _clearError();
      
      _hasPermissions = await _photoService.requestPermissions();
      
      if (!_hasPermissions) {
        _errorMessage = '갤러리 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.';
      }
      
      return _hasPermissions;
    } catch (e) {
      _errorMessage = '권한 요청 실패: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 권한 상태 확인
  Future<void> checkPermissions() async {
    try {
      _hasPermissions = await _photoService.hasPermissions();
    } catch (e) {
      _errorMessage = '권한 확인 실패: $e';
      _hasPermissions = false;
    }
    notifyListeners();
  }

  // 최신 스크린샷 로드
  Future<void> loadLatestScreenshots() async {
    if (!_hasPermissions) {
      await checkPermissions();
      if (!_hasPermissions) return;
    }

    try {
      _setLoading(true);
      _clearError();
      
      _latestScreenshots = await _photoService.getLatestScreenshots();
      
    } catch (e) {
      _errorMessage = '스크린샷 로드 실패: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 웹에서 사진 선택 및 처리
  Future<List<PhotoModel>> pickAndProcessImages(String userId) async {
    if (!kIsWeb) {
      _errorMessage = '이 기능은 웹에서만 사용할 수 있습니다.';
      return [];
    }

    try {
      _setProcessing(true);
      _clearError();
      
      print('🔄 웹에서 사진 선택 시작...');
      
      // 웹에서 사진 선택
      final selectedImages = await _photoService.pickImagesFromWeb();
      print('📁 선택된 이미지 수: ${selectedImages.length}');
      
      if (selectedImages.isEmpty) {
        print('❌ 선택된 이미지가 없습니다.');
        return [];
      }
      
      final processedPhotos = <PhotoModel>[];
      
      for (int i = 0; i < selectedImages.length; i++) {
        final xFile = selectedImages[i];
        print('🖼️ 이미지 ${i + 1}/${selectedImages.length} 처리 중: ${xFile.name}');
        
        try {
          // 웹에서는 XFile을 직접 사용하여 이미지 처리
          print('🤖 OCR 처리 시작...');
          final ocrResult = await _processWebImage(xFile);
          print('✅ OCR 완료 - 카테고리: ${ocrResult.category}, 신뢰도: ${ocrResult.confidence}');
          
          // PhotoModel 생성
          final photoModel = PhotoModel(
            id: '', // Firestore에서 생성됨
            localPath: xFile.path,
            fileName: xFile.name,
            captureDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: userId,
            albumId: await _photoService.getOrCreateAlbumForCategory(userId, ocrResult.category),
            category: ocrResult.category,
            ocrText: ocrResult.text,
            metadata: {
              'confidence': ocrResult.confidence,
              'processing_version': '1.0',
              'source': 'web_upload',
            },
            tags: ocrResult.tags,
          );

          print('💾 Firestore에 저장 중...');
          // Firestore에 저장
          final photoId = await _photoService.createPhoto(photoModel);
          final savedPhoto = photoModel.copyWith(id: photoId);
          
          processedPhotos.add(savedPhoto);
          print('✅ 사진 저장 완료: $photoId');
          
          // 앨범 사진 개수 업데이트
          await _photoService.updateAlbumPhotoCount(savedPhoto.albumId);
          
        } catch (e) {
          print('❌ 이미지 처리 오류: $e');
          _errorMessage = '이미지 처리 중 오류 발생: $e';
          continue;
        }
      }
      
      print('🔄 로컬 목록 업데이트 중...');
      // 로컬 목록 업데이트
      _photos.insertAll(0, processedPhotos);
      _recentPhotos.insertAll(0, processedPhotos);
      
      print('✅ 총 ${processedPhotos.length}개 사진 처리 완료');
      return processedPhotos;
    } catch (e) {
      print('❌ 사진 처리 실패: $e');
      _errorMessage = '사진 처리 실패: $e';
      return [];
    } finally {
      _setProcessing(false);
    }
  }

  // 새로운 스크린샷 처리
  Future<List<PhotoModel>> processNewScreenshots(String userId) async {
    if (kIsWeb) {
      // 웹에서는 수동으로 사진을 선택하도록 안내
      _errorMessage = '웹에서는 "사진 업로드" 버튼을 사용해주세요.';
      return [];
    }
    
    if (!_hasPermissions) {
      await checkPermissions();
      if (!_hasPermissions) return [];
    }

    try {
      _setProcessing(true);
      _clearError();
      
      final newPhotos = await _photoService.processNewScreenshots(userId);
      
      // 로컬 목록 업데이트
      _photos.insertAll(0, newPhotos);
      _recentPhotos.insertAll(0, newPhotos);
      
      return newPhotos;
    } catch (e) {
      _errorMessage = '스크린샷 처리 실패: $e';
      return [];
    } finally {
      _setProcessing(false);
    }
  }

  // 사용자의 모든 사진 로드
  Future<void> loadUserPhotos(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Firestore에서 사진 목록 로드
      final firestoreService = FirestoreService();
      _photos = await firestoreService.getUserPhotos(userId);
      _recentPhotos = _photos.take(20).toList();
      
    } catch (e) {
      _errorMessage = '사진 로드 실패: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 즐겨찾기 사진 로드
  Future<void> loadFavoritePhotos(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final firestoreService = FirestoreService();
      _favoritePhotos = await firestoreService.getFavoritePhotos(userId);
      
    } catch (e) {
      _errorMessage = '즐겨찾기 로드 실패: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 사진을 다른 앨범으로 이동
  Future<bool> movePhotoToAlbum(String photoId, String newAlbumId) async {
    try {
      _clearError();
      
      await _photoService.movePhotoToAlbum(photoId, newAlbumId);
      
      // 로컬 목록에서 해당 사진 업데이트
      _updatePhotoInLists(photoId, (photo) => photo.copyWith(albumId: newAlbumId));
      
      return true;
    } catch (e) {
      _errorMessage = '사진 이동 실패: $e';
      return false;
    }
  }

  // 사진 즐겨찾기 토글
  Future<bool> togglePhotoFavorite(String photoId) async {
    try {
      _clearError();
      
      await _photoService.togglePhotoFavorite(photoId);
      
      // 로컬 목록에서 해당 사진 업데이트
      _updatePhotoInLists(photoId, (photo) => photo.copyWith(isFavorite: !photo.isFavorite));
      
      return true;
    } catch (e) {
      _errorMessage = '즐겨찾기 토글 실패: $e';
      return false;
    }
  }

  // 사진 삭제
  Future<bool> deletePhoto(String photoId) async {
    try {
      _clearError();
      
      await _photoService.deletePhoto(photoId);
      
      // 로컬 목록에서 제거
      _photos.removeWhere((photo) => photo.id == photoId);
      _recentPhotos.removeWhere((photo) => photo.id == photoId);
      _favoritePhotos.removeWhere((photo) => photo.id == photoId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '사진 삭제 실패: $e';
      return false;
    }
  }

  // 사진 검색
  Future<List<PhotoModel>> searchPhotos(String userId, String query) async {
    if (query.trim().isEmpty) return [];

    try {
      _clearError();
      
      return await _photoService.searchPhotos(userId, query);
    } catch (e) {
      _errorMessage = '검색 실패: $e';
      return [];
    }
  }

  // 앨범별 사진 로드
  Future<List<PhotoModel>> loadAlbumPhotos(String albumId) async {
    try {
      _clearError();
      
      final firestoreService = FirestoreService();
      return await firestoreService.getAlbumPhotos(albumId);
    } catch (e) {
      _errorMessage = '앨범 사진 로드 실패: $e';
      return [];
    }
  }

  // 웹에서 이미지 처리 (XFile 사용)
  Future<OCRResult> _processWebImage(XFile xFile) async {
    try {
      // XFile에서 바이트 데이터 읽기
      final bytes = await xFile.readAsBytes();
      print('📊 이미지 크기: ${bytes.length} bytes');
      
      // 임시 파일 생성 (Gemini API용)
      final tempFile = File(xFile.path);
      await tempFile.writeAsBytes(bytes);
      
      // Gemini API 호출
      final ocrResult = await _photoService.processImage(tempFile);
      
      // 임시 파일 삭제
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      return ocrResult;
    } catch (e) {
      print('❌ 웹 이미지 처리 오류: $e');
      // 폴백: 기본값 반환
      return OCRResult(
        text: '',
        category: '정보/참고용',
        confidence: 0.5,
        tags: ['웹업로드'],
      );
    }
  }

  // Helper methods
  void _updatePhotoInLists(String photoId, PhotoModel Function(PhotoModel) updater) {
    // _photos 업데이트
    final photoIndex = _photos.indexWhere((photo) => photo.id == photoId);
    if (photoIndex != -1) {
      _photos[photoIndex] = updater(_photos[photoIndex]);
    }

    // _recentPhotos 업데이트
    final recentIndex = _recentPhotos.indexWhere((photo) => photo.id == photoId);
    if (recentIndex != -1) {
      _recentPhotos[recentIndex] = updater(_recentPhotos[recentIndex]);
    }

    // _favoritePhotos 업데이트
    final favoriteIndex = _favoritePhotos.indexWhere((photo) => photo.id == photoId);
    if (favoriteIndex != -1) {
      final updatedPhoto = updater(_favoritePhotos[favoriteIndex]);
      if (updatedPhoto.isFavorite) {
        _favoritePhotos[favoriteIndex] = updatedPhoto;
      } else {
        _favoritePhotos.removeAt(favoriteIndex);
      }
    } else {
      // 즐겨찾기가 추가된 경우
      final mainPhotoIndex = _photos.indexWhere((photo) => photo.id == photoId);
      if (mainPhotoIndex != -1) {
        final updatedPhoto = updater(_photos[mainPhotoIndex]);
        if (updatedPhoto.isFavorite) {
          _favoritePhotos.insert(0, updatedPhoto);
        }
      }
    }

    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // 앱 시작 시 초기화
  Future<void> initialize(String userId) async {
    await checkPermissions();
    if (_hasPermissions) {
      await Future.wait([
        loadUserPhotos(userId),
        loadFavoritePhotos(userId),
        loadLatestScreenshots(),
      ]);
    }
  }

  // 수동 새로고침
  Future<void> refresh(String userId) async {
    await Future.wait([
      loadUserPhotos(userId),
      loadFavoritePhotos(userId),
      loadLatestScreenshots(),
      processNewScreenshots(userId),
    ]);
  }
}
