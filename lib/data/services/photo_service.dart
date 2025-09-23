import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../../core/constants/app_constants.dart';
import 'firestore_service.dart';
import 'gemini_service.dart';

class PhotoService {
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();

  // 권한 요청
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      // 웹에서는 항상 true 반환 (브라우저에서 파일 선택 시 권한 요청)
      return true;
    }
    
    // iOS/Android 갤러리 접근 권한
    final photoPermission = await PhotoManager.requestPermissionExtend();
    
    // 알림 권한
    final notificationPermission = await Permission.notification.request();
    
    return photoPermission.isAuth && 
           (notificationPermission == PermissionStatus.granted || 
            notificationPermission == PermissionStatus.limited);
  }

  // 권한 상태 확인
  Future<bool> hasPermissions() async {
    if (kIsWeb) {
      // 웹에서는 항상 true 반환
      return true;
    }
    
    final photoPermission = await PhotoManager.requestPermissionExtend();
    final notificationPermission = await Permission.notification.status;
    
    return photoPermission.isAuth && 
           (notificationPermission == PermissionStatus.granted || 
            notificationPermission == PermissionStatus.limited);
  }

  // 웹에서 사진 선택하기
  Future<List<XFile>> pickImagesFromWeb() async {
    if (!kIsWeb) {
      throw Exception('이 메서드는 웹에서만 사용할 수 있습니다.');
    }
    
    print('📸 ImagePicker 초기화 중...');
    final ImagePicker picker = ImagePicker();
    
    print('🖼️ 다중 이미지 선택 요청 중...');
    final List<XFile> images = await picker.pickMultiImage();
    print('📁 선택된 이미지 수: ${images.length}');
    
    if (images.isEmpty) {
      print('❌ 사용자가 이미지를 선택하지 않았습니다.');
      return [];
    }
    
    print('✅ ${images.length}개 이미지 선택 완료');
    return images;
  }

  // 최신 스크린샷 가져오기
  Future<List<AssetEntity>> getLatestScreenshots({int count = 50}) async {
    if (kIsWeb) {
      // 웹에서는 빈 리스트 반환 (photo_manager가 웹에서 지원되지 않음)
      return [];
    }
    
    final hasPermission = await hasPermissions();
    if (!hasPermission) {
      throw Exception('갤러리 접근 권한이 필요합니다.');
    }

    // 스크린샷 앨범 찾기
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: false,
    );

    AssetPathEntity? screenshotAlbum;
    for (final album in albums) {
      final albumName = album.name.toLowerCase();
      if (albumName.contains('screenshot') || 
          albumName.contains('스크린샷') ||
          albumName.contains('screen shots')) {
        screenshotAlbum = album;
        break;
      }
    }

    if (screenshotAlbum == null) {
      // 스크린샷 앨범이 없으면 전체 사진에서 최근 항목들 가져오기
      final allPhotos = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );
      
      if (allPhotos.isNotEmpty) {
        return await allPhotos.first.getAssetListRange(
          start: 0,
          end: count,
        );
      }
      return [];
    }

    return await screenshotAlbum.getAssetListRange(
      start: 0,
      end: count,
    );
  }

  // 새로운 스크린샷 감지 및 처리
  Future<List<PhotoModel>> processNewScreenshots(String userId) async {
    final screenshots = await getLatestScreenshots();
    final processedPhotos = <PhotoModel>[];

    // 기존에 처리된 사진들 가져오기 (최근 100개)
    final existingPhotos = await _firestoreService.getUserPhotos(userId, limit: 100);
    final existingPaths = existingPhotos.map((p) => p.localPath).toSet();

    for (final screenshot in screenshots) {
      try {
        final file = await screenshot.file;
        if (file == null) continue;

        // 이미 처리된 사진인지 확인
        if (existingPaths.contains(file.path)) continue;

        // OCR 및 카테고리 분류 수행
        final ocrResult = await _geminiService.processImage(file);
        
        // PhotoModel 생성
        final photoModel = PhotoModel(
          id: '', // Firestore에서 생성됨
          localPath: file.path,
          fileName: path.basename(file.path),
          captureDate: screenshot.createDateTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: userId,
          albumId: await getOrCreateAlbumForCategory(userId, ocrResult.category),
          category: ocrResult.category,
          ocrText: ocrResult.text,
          metadata: {
            'confidence': ocrResult.confidence,
            'processing_version': '1.0',
          },
          tags: ocrResult.tags,
        );

        // Firestore에 저장
        final photoId = await _firestoreService.createPhoto(photoModel);
        final savedPhoto = photoModel.copyWith(id: photoId);
        
        processedPhotos.add(savedPhoto);
        
        // 앨범 사진 개수 업데이트
        await _firestoreService.updateAlbumPhotoCount(savedPhoto.albumId);
        
      } catch (e) {
        print('Error processing screenshot: $e');
        // 개별 사진 처리 실패는 전체 프로세스를 중단시키지 않음
        continue;
      }
    }

    return processedPhotos;
  }

  // 카테고리에 해당하는 앨범 가져오기 또는 생성
  Future<String> getOrCreateAlbumForCategory(String userId, String category) async {
    final albums = await _firestoreService.getUserAlbums(userId);
    
    // 기존 앨범 찾기
    AlbumModel? existingAlbum;
    try {
      existingAlbum = albums.firstWhere((album) => album.name == category);
    } catch (e) {
      existingAlbum = null;
    }
    
    if (existingAlbum != null) {
      return existingAlbum.id;
    }

    // 새 앨범 생성
    final categoryIndex = AppConstants.defaultCategories.indexOf(category);
    final colorCode = categoryIndex >= 0 && categoryIndex < AppConstants.defaultCategories.length
        ? '#${(0xFF000000 | (categoryIndex * 0x123456)).toRadixString(16).substring(2)}'
        : '#6B73FF';

    final newAlbum = AlbumModel(
      id: '',
      name: category,
      description: '$category 관련 스크린샷',
      iconPath: _getCategoryIcon(category),
      colorCode: colorCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
      isDefault: AppConstants.defaultCategories.contains(category),
    );

    return await _firestoreService.createAlbum(newAlbum);
  }

  // 카테고리별 아이콘 가져오기
  String _getCategoryIcon(String category) {
    switch (category) {
      case '정보/참고용':
        return '📄';
      case '대화/메시지':
        return '💬';
      case '학습/업무 메모':
        return '📝';
      case '재미/밈/감정':
        return '😄';
      case '일정/예약':
        return '📅';
      case '증빙/거래':
        return '💳';
      case '옷':
        return '👕';
      case '제품':
        return '📦';
      default:
        return '📷';
    }
  }

  // 사진을 다른 앨범으로 이동
  Future<void> movePhotoToAlbum(String photoId, String newAlbumId) async {
    final photoDoc = await _firestoreService.firestore
        .collection(AppConstants.photosCollection)
        .doc(photoId)
        .get();
    
    if (!photoDoc.exists) return;
    
    final photo = PhotoModel.fromJson({...photoDoc.data()!, 'id': photoId});
    final oldAlbumId = photo.albumId;
    
    // 사진 업데이트
    final updatedPhoto = photo.copyWith(
      albumId: newAlbumId,
      updatedAt: DateTime.now(),
    );
    
    await _firestoreService.updatePhoto(updatedPhoto);
    
    // 앨범 사진 개수 업데이트
    await _firestoreService.updateAlbumPhotoCount(oldAlbumId);
    await _firestoreService.updateAlbumPhotoCount(newAlbumId);
  }

  // 사진 즐겨찾기 토글
  Future<void> togglePhotoFavorite(String photoId) async {
    final photoDoc = await _firestoreService.firestore
        .collection(AppConstants.photosCollection)
        .doc(photoId)
        .get();
    
    if (!photoDoc.exists) return;
    
    final photo = PhotoModel.fromJson({...photoDoc.data()!, 'id': photoId});
    final updatedPhoto = photo.copyWith(
      isFavorite: !photo.isFavorite,
      updatedAt: DateTime.now(),
    );
    
    await _firestoreService.updatePhoto(updatedPhoto);
  }

  // 사진 삭제 (로컬 파일은 유지)
  Future<void> deletePhoto(String photoId) async {
    final photoDoc = await _firestoreService.firestore
        .collection(AppConstants.photosCollection)
        .doc(photoId)
        .get();
    
    if (!photoDoc.exists) return;
    
    final photo = PhotoModel.fromJson({...photoDoc.data()!, 'id': photoId});
    await _firestoreService.deletePhoto(photoId);
    
    // 앨범 사진 개수 업데이트
    await _firestoreService.updateAlbumPhotoCount(photo.albumId);
  }

  // 썸네일 생성
  Future<Uint8List?> generateThumbnail(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      // photo_manager를 사용하여 썸네일 생성
      final assets = await PhotoManager.getAssetListRange(
        start: 0,
        end: 1,
      );
      
      for (final asset in assets) {
        final assetFile = await asset.file;
        if (assetFile?.path == localPath) {
          return await asset.thumbnailData;
        }
      }
      
      return null;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  // 사진 검색
  Future<List<PhotoModel>> searchPhotos(String userId, String query) async {
    // Firestore의 제한으로 인해 클라이언트 사이드에서 필터링
    final allPhotos = await _firestoreService.getUserPhotos(userId);
    
    return allPhotos.where((photo) {
      final ocrText = photo.ocrText?.toLowerCase() ?? '';
      final fileName = photo.fileName.toLowerCase();
      final category = photo.category.toLowerCase();
      final tags = photo.tags.join(' ').toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return ocrText.contains(searchQuery) ||
             fileName.contains(searchQuery) ||
             category.contains(searchQuery) ||
             tags.contains(searchQuery);
    }).toList();
  }
}

// Gemini OCR 결과 모델
class OCRResult {
  final String text;
  final String category;
  final double confidence;
  final List<String> tags;

  OCRResult({
    required this.text,
    required this.category,
    required this.confidence,
    required this.tags,
  });
}

// PhotoService에 필요한 메서드들 추가
extension PhotoServiceExtensions on PhotoService {
  // 이미지 처리
  Future<OCRResult> processImage(File file) async {
    return await _geminiService.processImage(file);
  }
  
  // 사진 생성
  Future<String> createPhoto(PhotoModel photo) async {
    return await _firestoreService.createPhoto(photo);
  }
  
  // 앨범 사진 개수 업데이트
  Future<void> updateAlbumPhotoCount(String albumId) async {
    await _firestoreService.updateAlbumPhotoCount(albumId);
  }
}