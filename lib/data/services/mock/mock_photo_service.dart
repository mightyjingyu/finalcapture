import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../interfaces/i_photo_service.dart';
import '../../models/photo_model.dart';
import '../../models/ocr_result.dart';

class MockPhotoService implements IPhotoService {
  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<List<XFile>> pickImagesFromWeb() async {
    return []; // Mock empty selection
  }

  @override
  Future<List<AssetEntity>> getLatestScreenshots({int count = 50}) async {
    // Return empty list in mock mode as we can't easily mock AssetEntity
    return [];
  }

  @override
  Future<List<PhotoModel>> processNewScreenshots(String userId, {bool forceReprocess = false}) async {
    // Return empty list or generate fake photo models without real files
    return [];
  }

  @override
  Future<OCRResult> processImageBytes(Uint8List bytes, String fileName) async {
    return OCRResult(
      text: "Mock OCR Text",
      category: "정보/참고용",
      confidence: 0.9,
      tags: ["mock", "test"],
      reasoning: "Mock reasoning",
    );
  }

  @override
  Future<OCRResult> processImage(File file) async {
    return OCRResult(
      text: "Mock OCR Text from File",
      category: "정보/참고용",
      confidence: 0.9,
      tags: ["mock", "file"],
      reasoning: "Mock reasoning",
    );
  }

  @override
  Future<String> createPhoto(PhotoModel photo) async {
    return "mock_photo_id_${DateTime.now().millisecondsSinceEpoch}";
  }

  @override
  Future<void> updateAlbumPhotoCount(String albumId) async {}

  @override
  Future<void> movePhotoToAlbum(String photoId, String newAlbumId) async {}

  @override
  Future<void> togglePhotoFavorite(String photoId) async {}

  @override
  Future<void> deletePhoto(String photoId) async {}

  @override
  Future<List<PhotoModel>> searchPhotos(String userId, String query) async {
    return [];
  }

  @override
  Future<Uint8List?> generateThumbnail(String localPath) async {
    return null;
  }

  @override
  Future<String> getFolderLocationInfo() async {
    return "Mock Folder Location";
  }

  @override
  Future<void> createAllCategoryFolders(String userId) async {}

  @override
  Future<String> getCategoryFolderPath(String category, String userId) async {
    return "/mock/path/$category";
  }

  @override
  Future<String> getOrCreateAlbumForCategory(String userId, String category) async {
    return "mock_album_id";
  }
}
