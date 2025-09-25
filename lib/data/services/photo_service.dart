import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
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
    
    try {
      print('🔐 권한 요청 시작...');
      
      // iOS/Android 갤러리 접근 권한 (PhotoManager 우선 사용)
      final photoPermission = await PhotoManager.requestPermissionExtend();
      print('📸 PhotoManager 권한 요청 결과: ${photoPermission.isAuth}');
      
      // PhotoManager가 성공하면 그것을 사용
      if (photoPermission.isAuth) {
        print('✅ PhotoManager 권한으로 충분합니다.');
        return true;
      }
      
      // PhotoManager가 실패한 경우에만 Permission Handler 사용
      final photosPermission = await Permission.photos.request();
      print('📷 Permission.photos 요청 결과: $photosPermission');
      
      // 권한이 영구적으로 거부된 경우 사용자에게 설정으로 안내
      if (photosPermission == PermissionStatus.permanentlyDenied) {
        print('⚠️ 권한이 영구적으로 거부되었습니다. 설정에서 수동으로 허용해야 합니다.');
        return false;
      }
      
      final isAuthorized = photoPermission.isAuth || 
                          (photosPermission == PermissionStatus.granted || 
                           photosPermission == PermissionStatus.limited);
      
      print('✅ 최종 권한 요청 결과: $isAuthorized');
      return isAuthorized;
    } catch (e) {
      print('❌ 권한 요청 오류: $e');
      return false;
    }
  }

  // 권한 상태 확인
  Future<bool> hasPermissions() async {
    if (kIsWeb) {
      // 웹에서는 항상 true 반환
      return true;
    }
    
    try {
      print('🔐 권한 상태 확인 중...');
      
      // PhotoManager 권한 상태 확인 (우선 사용)
      final photoPermission = await PhotoManager.requestPermissionExtend();
      print('📸 PhotoManager 권한 상태: ${photoPermission.isAuth}');
      
      if (photoPermission.isAuth) {
        print('✅ PhotoManager 권한으로 충분합니다.');
        return true;
      }
      
      // PhotoManager가 실패한 경우에만 Permission Handler 확인
      final permissionStatus = await Permission.photos.status;
      print('📷 Permission.photos 상태: $permissionStatus');
      
      final isAuthorized = photoPermission.isAuth || 
                          (permissionStatus == PermissionStatus.granted || 
                           permissionStatus == PermissionStatus.limited);
      
      print('✅ 최종 권한 상태: $isAuthorized');
      return isAuthorized;
    } catch (e) {
      print('❌ 권한 확인 오류: $e');
      return false;
    }
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
      print('❌ 갤러리 접근 권한이 없습니다.');
      throw Exception('갤러리 접근 권한이 필요합니다.');
    }

    print('📸 갤러리 접근 권한 확인 완료');

    try {
      // 스크린샷 앨범만 가져오기
      final screenshotAlbums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: false,
      );
      
      print('📁 전체 앨범 수: ${screenshotAlbums.length}');
      
      // 스크린샷 앨범 찾기
      AssetPathEntity? screenshotAlbum;
      for (final album in screenshotAlbums) {
        if (album.name.toLowerCase().contains('screenshot') || 
            album.name.toLowerCase().contains('스크린샷')) {
          screenshotAlbum = album;
          break;
        }
      }
      
      if (screenshotAlbum != null) {
        final screenshotAssets = await screenshotAlbum.getAssetListRange(
          start: 0,
          end: count,
        );
        print('📷 스크린샷 ${screenshotAssets.length}개 로드 완료');
        return screenshotAssets;
      }
      
      // 스크린샷 앨범이 없는 경우, 전체 사진에서 스크린샷만 필터링
      print('⚠️ 스크린샷 앨범을 찾을 수 없어 전체 사진에서 필터링합니다.');
      final allPhotos = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );
      
      if (allPhotos.isNotEmpty) {
        final allAssets = await allPhotos.first.getAssetListRange(
          start: 0,
          end: count * 3, // 더 많이 가져와서 필터링
        );
        
        // 스크린샷만 필터링 (파일명이나 메타데이터 기반)
        final screenshots = <AssetEntity>[];
        for (final asset in allAssets) {
          final fileName = asset.title ?? '';
          final filePath = asset.relativePath ?? '';
          
          // 스크린샷 파일명 패턴 확인
          if (fileName.toLowerCase().contains('screenshot') ||
              fileName.toLowerCase().contains('스크린샷') ||
              filePath.toLowerCase().contains('screenshot') ||
              filePath.toLowerCase().contains('스크린샷')) {
            screenshots.add(asset);
            if (screenshots.length >= count) break;
          }
        }
        
        print('📷 필터링된 스크린샷 ${screenshots.length}개 로드 완료');
        return screenshots;
      }
      
      print('⚠️ 사진이 없습니다.');
      return [];
    } catch (e) {
      print('❌ 사진 로드 실패: $e');
      throw Exception('사진 로드 실패: $e');
    }
  }

  // 새로운 스크린샷 감지 및 처리
  Future<List<PhotoModel>> processNewScreenshots(String userId) async {
    final screenshots = await getLatestScreenshots();
    final processedPhotos = <PhotoModel>[];

    // 기존에 처리된 사진들 가져오기 (최근 100개)
    final existingPhotos = await _firestoreService.getUserPhotos(userId, limit: 100);
    final existingAssetIds = existingPhotos
        .where((p) => p.assetEntityId != null)
        .map((p) => p.assetEntityId!)
        .toSet();

    print('📊 기존 처리된 사진 수: ${existingPhotos.length}');
    print('📊 기존 AssetEntity ID 수: ${existingAssetIds.length}');
    print('📊 현재 스크린샷 수: ${screenshots.length}');

    for (final screenshot in screenshots) {
      try {
        final file = await screenshot.file;
        if (file == null) continue;

        // 이미 처리된 사진인지 확인 (AssetEntity ID로 비교)
        if (existingAssetIds.contains(screenshot.id)) {
          print('⏭️ 이미 처리된 스크린샷 건너뛰기: ${screenshot.id}');
          continue;
        }

        print('🔄 새 스크린샷 처리 시작: ${screenshot.id}');

        // OCR 및 카테고리 분류 수행
        final ocrResult = await _geminiService.processImage(file);
        
        // 카테고리별 폴더로 파일 이동
        final movedFilePath = await _moveFileToCategoryFolder(file, ocrResult.category, userId);
        
        // PhotoModel 생성 (이동된 파일 경로 사용)
        final photoModel = PhotoModel(
          id: '', // Firestore에서 생성됨
          localPath: movedFilePath,
          fileName: path.basename(movedFilePath),
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
            'original_path': file.path,
            'reasoning': ocrResult.reasoning,
          },
          tags: ocrResult.tags,
          assetEntityId: screenshot.id, // AssetEntity ID 추가
        );

        // Firestore에 저장
        final photoId = await _firestoreService.createPhoto(photoModel);
        final savedPhoto = photoModel.copyWith(id: photoId);
        
        processedPhotos.add(savedPhoto);
        
        // 앨범 사진 개수 업데이트
        await _firestoreService.updateAlbumPhotoCount(savedPhoto.albumId);
        
        print('✅ 사진 처리 완료: ${savedPhoto.fileName} → ${ocrResult.category} 폴더');
        print('📁 저장 위치: $movedFilePath');
        
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

  // 카테고리별 폴더로 파일 이동 (사용자 접근 가능한 폴더)
  Future<String> _moveFileToCategoryFolder(File originalFile, String category, String userId) async {
    try {
      print('📁 파일 이동 시작: ${originalFile.path} → $category 폴더');
      
      String targetDir;
      
      if (Platform.isIOS) {
        // iOS: Photos 앨범에 저장 (사용자가 접근 가능)
        return await _saveToPhotosAlbum(originalFile, category);
      } else if (Platform.isAndroid) {
        // Android: Downloads 폴더에 카테고리별 폴더 생성 (사용자가 접근 가능)
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            targetDir = path.join(downloadsDir.path, 'FinalCapture', category);
          } else {
            // 폴백: 외부 저장소의 Downloads 폴더
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              targetDir = path.join(externalDir.path, '..', 'Download', 'FinalCapture', category);
              targetDir = path.normalize(targetDir);
            } else {
              throw Exception('외부 저장소 접근 불가');
            }
          }
        } catch (e) {
          print('⚠️ 외부 저장소 접근 실패, 앱 폴더 사용: $e');
          // 폴백: 앱 Documents 폴더
          final appDir = await getApplicationDocumentsDirectory();
          targetDir = path.join(appDir.path, 'FinalCapture', 'Photos', category);
        }
      } else {
        // 기타 플랫폼: 앱 Documents 폴더
        final appDir = await getApplicationDocumentsDirectory();
        targetDir = path.join(appDir.path, 'FinalCapture', 'Photos', category);
      }
      
      final categoryDir = Directory(targetDir);
      
      // 카테고리 폴더가 없으면 생성
      if (!await categoryDir.exists()) {
        await categoryDir.create(recursive: true);
        print('📂 카테고리 폴더 생성: ${categoryDir.path}');
      }
      
      // 새 파일명 생성 (중복 방지)
      final originalFileName = path.basename(originalFile.path);
      final fileExtension = path.extension(originalFileName);
      final fileNameWithoutExt = path.basenameWithoutExtension(originalFileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${fileNameWithoutExt}_$timestamp$fileExtension';
      
      final newFilePath = path.join(categoryDir.path, newFileName);
      
      // 파일 복사
      await originalFile.copy(newFilePath);
      print('📋 파일 복사 완료: $newFilePath');
      
      // 원본 파일 삭제 (선택사항 - 스크린샷이므로 삭제)
      try {
        await originalFile.delete();
        print('🗑️ 원본 파일 삭제: ${originalFile.path}');
      } catch (e) {
        print('⚠️ 원본 파일 삭제 실패 (무시): $e');
      }
      
      return newFilePath;
    } catch (e) {
      print('❌ 파일 이동 실패: $e');
      // 실패 시 원본 경로 반환
      return originalFile.path;
    }
  }

  // iOS Photos 앨범에 저장
  Future<String> _saveToPhotosAlbum(File file, String category) async {
    try {
      print('📱 iOS Photos 앨범에 저장 중...');
      
      // PhotoManager를 사용하여 Photos 앨범에 저장
      final result = await PhotoManager.editor.saveImage(
        await file.readAsBytes(),
        title: 'FinalCapture_${category}_${DateTime.now().millisecondsSinceEpoch}',
        filename: 'FinalCapture_${category}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      print('✅ Photos 앨범에 저장 완료: ${result.id}');
      // Photos 앨범에 저장된 경우 원본 파일 경로를 반환 (Photos 앨범의 실제 경로는 접근 불가)
      return file.path; // 원본 경로 유지
    } catch (e) {
      print('❌ Photos 앨범 저장 실패: $e');
      // 실패 시 원본 경로 반환
      return file.path;
    }
  }

  // 카테고리별 폴더 경로 가져오기
  Future<String> getCategoryFolderPath(String category, String userId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'FinalCapture', 'Photos', category);
  }

  // 모든 카테고리 폴더 생성
  Future<void> createAllCategoryFolders(String userId) async {
    try {
      String baseDir;
      
      if (Platform.isIOS) {
        // iOS에서는 Photos 앨범을 사용하므로 별도 폴더 생성 불필요
        print('📱 iOS: Photos 앨범에 저장됩니다');
        return;
      } else if (Platform.isAndroid) {
        // Android: Downloads 폴더에 생성
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          baseDir = path.join(downloadsDir.path, 'FinalCapture');
        } else {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            baseDir = path.join(externalDir.path, '..', 'Download', 'FinalCapture');
            baseDir = path.normalize(baseDir);
          } else {
            throw Exception('외부 저장소 접근 불가');
          }
        }
      } else {
        // 기타 플랫폼: 앱 Documents 폴더
        final appDir = await getApplicationDocumentsDirectory();
        baseDir = path.join(appDir.path, 'FinalCapture', 'Photos');
      }
      
      final baseDirectory = Directory(baseDir);
      
      // 기본 디렉토리 생성
      if (!await baseDirectory.exists()) {
        await baseDirectory.create(recursive: true);
        print('📂 기본 폴더 생성: ${baseDirectory.path}');
      }
      
      // 각 카테고리별 폴더 생성
      for (final category in AppConstants.defaultCategories) {
        final categoryDir = Directory(path.join(baseDir, category));
        if (!await categoryDir.exists()) {
          await categoryDir.create(recursive: true);
          print('📂 카테고리 폴더 생성: ${categoryDir.path}');
        }
      }
      
      print('📁 사용자 접근 가능한 폴더 위치: $baseDir');
    } catch (e) {
      print('❌ 카테고리 폴더 생성 실패: $e');
    }
  }

  // 사용자에게 폴더 위치 정보 제공
  Future<String> getFolderLocationInfo() async {
    if (Platform.isIOS) {
      return 'iOS Photos 앨범에 저장됩니다. Photos 앱에서 확인하세요.';
    } else if (Platform.isAndroid) {
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          return 'Android Downloads/FinalCapture 폴더에 저장됩니다.\n경로: ${downloadsDir.path}/FinalCapture';
        } else {
          return 'Android Downloads 폴더에 저장됩니다.';
        }
      } catch (e) {
        return 'Android Downloads 폴더에 저장됩니다.';
      }
    } else {
      return '앱 전용 폴더에 저장됩니다.';
    }
  }
}

// Gemini OCR 결과 모델
class OCRResult {
  final String text;
  final String category;
  final double confidence;
  final List<String> tags;
  final String reasoning;

  OCRResult({
    required this.text,
    required this.category,
    required this.confidence,
    required this.tags,
    required this.reasoning,
  });
}

// PhotoService에 필요한 메서드들 추가
extension PhotoServiceExtensions on PhotoService {
  // 이미지 처리
  Future<OCRResult> processImage(File file) async {
    return await _geminiService.processImage(file);
  }
  
  // 바이트 데이터로 이미지 처리 (웹용)
  Future<OCRResult> processImageBytes(Uint8List bytes, String fileName) async {
    return await _geminiService.processImageBytes(bytes, fileName);
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