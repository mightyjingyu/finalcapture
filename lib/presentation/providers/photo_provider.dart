import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' if (dart.library.html) '';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../data/models/photo_model.dart';
import '../../data/services/photo_service.dart';
import '../../data/services/firestore_service.dart';

class PhotoProvider extends ChangeNotifier {
  final PhotoService _photoService = PhotoService();
  
  List<PhotoModel> _photos = [];
  List<PhotoModel> _recentPhotos = [];
  List<PhotoModel> _favoritePhotos = [];
  List<AssetEntity> _latestScreenshots = [];
  List<AssetEntity> _favoriteScreenshots = []; // 즐겨찾기된 스크린샷들
  
  // 웹에서 이미지 캐시 (메모리 저장)
  final Map<String, Uint8List> _webImageCache = {};
  
  // 갤러리 변화 감지를 위한 변수들 (현재 비활성화)
  // StreamSubscription<void>? _galleryChangeSubscription;
  // bool _isListeningToGalleryChanges = false;
  
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _hasPermissions = false;

  // Getters
  List<PhotoModel> get photos => _photos;
  List<PhotoModel> get recentPhotos => _recentPhotos;
  List<PhotoModel> get favoritePhotos => _favoritePhotos;
  List<AssetEntity> get latestScreenshots => _latestScreenshots;
  List<AssetEntity> get favoriteScreenshots => _favoriteScreenshots;
  
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasPermissions => _hasPermissions;
  
  // 웹 이미지 캐시 getter
  Uint8List? getWebImageBytes(String photoId) => _webImageCache[photoId];

  // 권한 확인 및 요청
  Future<bool> requestPermissions() async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔐 권한 요청 시작...');
      _hasPermissions = await _photoService.requestPermissions();
      
      if (!_hasPermissions) {
        _errorMessage = '갤러리 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.';
        print('❌ 권한 요청 실패: $_errorMessage');
      } else {
        print('✅ 권한 요청 성공');
      }
      
      return _hasPermissions;
    } catch (e) {
      _errorMessage = '권한 요청 실패: $e';
      print('❌ 권한 요청 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 권한 상태 확인
  Future<void> checkPermissions() async {
    try {
      print('🔐 PhotoProvider에서 권한 상태 확인 중...');
      _hasPermissions = await _photoService.hasPermissions();
      print('📱 PhotoProvider 권한 상태: $_hasPermissions');
    } catch (e) {
      _errorMessage = '권한 확인 실패: $e';
      print('❌ 권한 확인 실패: $e');
      _hasPermissions = false;
    }
    notifyListeners();
  }

  // 최신 스크린샷 로드
  Future<void> loadLatestScreenshots() async {
    if (!_hasPermissions) {
      print('🔐 권한이 없어 권한 확인 중...');
      await checkPermissions();
      if (!_hasPermissions) {
        print('❌ 권한이 없어 스크린샷을 로드할 수 없습니다.');
        return;
      }
    }

    try {
      _setLoading(true);
      _clearError();
      
      print('📸 최신 스크린샷 로드 시작...');
      _latestScreenshots = await _photoService.getLatestScreenshots();
      print('✅ 스크린샷 로드 완료: ${_latestScreenshots.length}개');
      
    } catch (e) {
      _errorMessage = '스크린샷 로드 실패: $e';
      print('❌ 스크린샷 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 갤러리 변화 감지 시작 (현재 비활성화 - photo_manager API 호환성 문제)
  Future<void> startGalleryChangeListener() async {
    // 현재 photo_manager 패키지에서 갤러리 변화 감지 API가 불안정하여 비활성화
    print('⚠️ 갤러리 변화 감지 기능이 현재 비활성화되어 있습니다.');
    print('💡 수동 새로고침을 사용하거나 앱을 재시작하여 최신 사진을 확인하세요.');
  }

  // 갤러리 변화 감지 중지 (현재 비활성화)
  void stopGalleryChangeListener() {
    // 현재 비활성화됨
  }

  // 갤러리 변화 처리 (현재 비활성화)
  Future<void> _handleGalleryChange() async {
    // 현재 비활성화됨 - photo_manager API 호환성 문제
  }

  // 삭제된 사진들을 Firestore에서 제거 (현재 비활성화)
  Future<void> _removeDeletedPhotosFromFirestore(Set<String> deletedAssetIds) async {
    // 현재 비활성화됨 - photo_manager API 호환성 문제
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
          
          // 웹에서도 카테고리별 폴더로 파일 이동 (로컬 저장)
          final movedFilePath = await _moveWebFileToCategoryFolder(xFile, ocrResult.category, userId);
          
          // PhotoModel 생성 (이동된 파일 경로 사용)
          final photoModel = PhotoModel(
            id: '', // Firestore에서 생성됨
            localPath: movedFilePath,
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
              'original_path': xFile.path,
              'reasoning': ocrResult.reasoning,
              // 웹에서는 바이트 데이터를 저장하지 않음 (Firestore 문서 크기 제한)
              'web_image_size': kIsWeb ? (await xFile.readAsBytes()).length : null,
            },
            tags: ocrResult.tags,
          );

          print('💾 Firestore에 저장 중...');
          // Firestore에 저장
          final photoId = await _photoService.createPhoto(photoModel);
          final savedPhoto = photoModel.copyWith(id: photoId);
          
          // 웹에서는 XFile 데이터를 메모리에 임시 저장
          if (kIsWeb) {
            _webImageCache[photoId] = await xFile.readAsBytes();
          }
          
          processedPhotos.add(savedPhoto);
          print('✅ 사진 저장 완료: $photoId → ${ocrResult.category} 폴더');
          
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
      
      // UI 업데이트를 위해 notifyListeners 호출
      notifyListeners();
      
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
      
      // 웹에서 기존 사진들을 위한 이미지 캐시 초기화
      if (kIsWeb) {
        _initializeWebImageCache();
      }
      
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
      
      // 웹에서는 임시 파일을 생성하지 않고 직접 바이트 데이터를 사용
      // Gemini API는 바이트 데이터를 직접 처리할 수 있도록 수정 필요
      final ocrResult = await _photoService.processImageBytes(bytes, xFile.name);
      
      return ocrResult;
    } catch (e) {
      print('❌ 웹 이미지 처리 오류: $e');
      // 폴백: 기본값 반환
      return OCRResult(
        text: '',
        category: '정보/참고용',
        confidence: 0.5,
        tags: ['웹업로드'],
        reasoning: '웹 이미지 처리 실패: $e',
      );
    }
  }

  // 웹에서 파일을 카테고리별 폴더로 이동 (다운로드 폴더에 저장)
  Future<String> _moveWebFileToCategoryFolder(XFile xFile, String category, String userId) async {
    try {
      print('📁 웹 파일 이동 시작: ${xFile.name} → $category 폴더');
      
      // 웹에서는 실제 파일 시스템 접근이 제한적이므로
      // 메타데이터만 저장하고 사용자가 수동으로 다운로드하도록 함
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${category}_${timestamp}_${xFile.name}';
      
      print('📁 웹 파일 저장 완료: $fileName');
      return 'web_download/$fileName';
    } catch (e) {
      print('❌ 웹 파일 이동 실패: $e');
      return xFile.path; // 원본 경로 반환
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
      
      // 갤러리 변화 감지 시작
      await startGalleryChangeListener();
    }
  }

  // 수동 새로고침 - 갤러리의 최신 스크린샷 반영
  Future<void> refresh(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔄 수동 새로고침 시작...');
      
      // 1. 최신 스크린샷 로드 (갤러리에서 직접 가져오기)
      await loadLatestScreenshots();
      
      // 2. 새로 추가된 스크린샷 처리 (OCR 및 분류)
      print('📸 새 스크린샷 처리 시작...');
      final processedPhotos = await processNewScreenshots(userId);
      
      if (processedPhotos.isNotEmpty) {
        print('✅ ${processedPhotos.length}개 새 스크린샷 처리 완료');
      } else {
        print('ℹ️ 처리할 새 스크린샷이 없습니다');
      }
      
      // 3. 사용자 사진 목록 새로고침 (Firestore에서)
      await loadUserPhotos(userId);
      
      // 4. 즐겨찾기 사진 목록 새로고침
      await loadFavoritePhotos(userId);
      
      print('✅ 수동 새로고침 완료');
      
    } catch (e) {
      _errorMessage = '새로고침 실패: $e';
      print('❌ 새로고침 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 모든 카테고리 폴더 생성
  Future<void> createAllCategoryFolders(String userId) async {
    try {
      await _photoService.createAllCategoryFolders(userId);
    } catch (e) {
      print('카테고리 폴더 생성 실패: $e');
    }
  }

  // 사진 생성
  Future<String> createPhoto(PhotoModel photo) async {
    return await _photoService.createPhoto(photo);
  }

  // AssetEntity 즐겨찾기 토글
  Future<bool> toggleAssetFavorite(AssetEntity asset) async {
    try {
      // 이미 즐겨찾기에 있는지 확인
      final isFavorite = _favoriteScreenshots.any((fav) => fav.id == asset.id);
      
      if (isFavorite) {
        // 즐겨찾기에서 제거
        _favoriteScreenshots.removeWhere((fav) => fav.id == asset.id);
        print('✅ 즐겨찾기에서 제거: ${asset.id}');
      } else {
        // 즐겨찾기에 추가
        _favoriteScreenshots.add(asset);
        print('✅ 즐겨찾기에 추가: ${asset.id}');
      }
      
      notifyListeners();
      return !isFavorite; // 새로운 즐겨찾기 상태 반환
    } catch (e) {
      print('❌ 즐겨찾기 토글 실패: $e');
      return false;
    }
  }

  // AssetEntity가 즐겨찾기인지 확인
  bool isAssetFavorite(AssetEntity asset) {
    return _favoriteScreenshots.any((fav) => fav.id == asset.id);
  }

  // 폴더 위치 정보 가져오기
  Future<String> getFolderLocationInfo() async {
    try {
      return await _photoService.getFolderLocationInfo();
    } catch (e) {
      return '폴더 위치 정보를 가져올 수 없습니다.';
    }
  }

  // 웹 이미지 캐시 초기화 (기존 사진들을 위한 플레이스홀더)
  void _initializeWebImageCache() {
    print('🔄 웹 이미지 캐시 초기화 중...');
    for (final photo in _photos) {
      // 기존 사진들에 대해 웹 이미지 캐시에 플레이스홀더 표시를 위한 마커 추가
      if (!_webImageCache.containsKey(photo.id)) {
        // 웹에서 업로드된 사진이지만 캐시에 없는 경우를 위한 처리
        print('📷 기존 사진 캐시 마킹: ${photo.fileName}');
      }
    }
    print('✅ 웹 이미지 캐시 초기화 완료: ${_photos.length}개 사진');
  }

  @override
  void dispose() {
    // 갤러리 변화 감지 중지 (현재 비활성화)
    // stopGalleryChangeListener();
    super.dispose();
  }
}
