import 'dart:async';
import '../interfaces/i_firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/album_model.dart';
import '../../models/photo_model.dart';
import '../../models/reminder_model.dart';
import '../../../core/constants/app_constants.dart';

class MockFirestoreService implements IFirestoreService {
  // In-memory storage
  final Map<String, UserModel> _users = {};
  final Map<String, AlbumModel> _albums = {};
  final Map<String, PhotoModel> _photos = {};
  final Map<String, ReminderModel> _reminders = {};

  final _albumsController = StreamController<List<AlbumModel>>.broadcast();
  final _photosController = StreamController<List<PhotoModel>>.broadcast(); // Simplified: one stream for all photos? Or per album?
  // Stream management for specific queries is complex in mock. 
  // We will emit events to listeners when data changes.

  MockFirestoreService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Initial data if needed
    final mockUserId = 'mock_user_123';
    
    // Default albums
    for (var i = 0; i < AppConstants.defaultCategories.length; i++) {
      final category = AppConstants.defaultCategories[i];
      final id = 'album_$i';
      _albums[id] = AlbumModel(
        id: id,
        name: category,
        description: '$category description',
        iconPath: '', // Mock icon path logic if needed
        userId: mockUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photoCount: 0,
        colorCode: '#CCCCCC',
        isDefault: true,
      );
    }
  }

  // User
  @override
  Future<void> createOrUpdateUser(UserModel user) async {
    _users[user.uid] = user;
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    return _users[uid];
  }

  @override
  Future<void> deleteUser(String uid) async {
    _users.remove(uid);
    _albums.removeWhere((key, value) => value.userId == uid);
    _photos.removeWhere((key, value) => value.userId == uid);
    _reminders.removeWhere((key, value) => value.userId == uid);
  }

  // Album
  @override
  Future<String> createAlbum(AlbumModel album) async {
    final id = album.id.isEmpty ? 'album_${DateTime.now().millisecondsSinceEpoch}' : album.id;
    final newAlbum = album.copyWith(id: id);
    _albums[id] = newAlbum;
    _notifyAlbumStream(album.userId);
    return id;
  }

  @override
  Future<void> updateAlbum(AlbumModel album) async {
    if (_albums.containsKey(album.id)) {
      _albums[album.id] = album;
      _notifyAlbumStream(album.userId);
    }
  }

  @override
  Future<void> deleteAlbum(String albumId) async {
    if (_albums.containsKey(albumId)) {
      final userId = _albums[albumId]!.userId;
      _albums.remove(albumId);
      _photos.removeWhere((key, value) => value.albumId == albumId);
      _notifyAlbumStream(userId);
    }
  }

  @override
  Future<List<AlbumModel>> getUserAlbums(String userId) async {
    return _albums.values.where((a) => a.userId == userId).toList();
  }

  @override
  Stream<List<AlbumModel>> getUserAlbumsStream(String userId) {
    // Return initial data immediately
    Future.microtask(() => _notifyAlbumStream(userId));
    return _albumsController.stream.map((albums) => albums.where((a) => a.userId == userId).toList());
  }
  
  void _notifyAlbumStream(String userId) {
    _albumsController.add(_albums.values.toList());
  }

  @override
  Future<void> updateAlbumPhotoCount(String albumId) async {
    if (_albums.containsKey(albumId)) {
      final count = _photos.values.where((p) => p.albumId == albumId).length;
      final album = _albums[albumId]!;
      _albums[albumId] = album.copyWith(photoCount: count);
      _notifyAlbumStream(album.userId);
    }
  }

  // Photo
  @override
  Future<String> createPhoto(PhotoModel photo) async {
    final id = photo.id.isEmpty ? 'photo_${DateTime.now().millisecondsSinceEpoch}' : photo.id;
    final newPhoto = photo.copyWith(id: id);
    _photos[id] = newPhoto;
    return id;
  }

  @override
  Future<void> updatePhoto(PhotoModel photo) async {
    if (_photos.containsKey(photo.id)) {
      _photos[photo.id] = photo;
    }
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    _photos.remove(photoId);
  }

  @override
  Future<List<PhotoModel>> getUserPhotos(String userId, {int? limit}) async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 300));
    var photos = _photos.values.where((p) => p.userId == userId).toList();
    photos.sort((a, b) => b.captureDate.compareTo(a.captureDate));
    if (limit != null && photos.length > limit) {
      photos = photos.sublist(0, limit);
    }
    return photos;
  }

  @override
  Future<List<PhotoModel>> getAlbumPhotos(String albumId, String userId) async {
    var photos = _photos.values.where((p) => p.albumId == albumId && p.userId == userId).toList();
    photos.sort((a, b) => b.captureDate.compareTo(a.captureDate));
    return photos;
  }

  @override
  Future<List<PhotoModel>> getFavoritePhotos(String userId) async {
    var photos = _photos.values.where((p) => p.userId == userId && p.isFavorite).toList();
    photos.sort((a, b) => b.captureDate.compareTo(a.captureDate));
    return photos;
  }

  @override
  Stream<List<PhotoModel>> getAlbumPhotosStream(String albumId, String userId) {
    return Stream.value([]); // Simplification: just return empty stream or implement proper stream logic
  }

  @override
  Future<void> batchUpdatePhotos(List<PhotoModel> photos) async {
    for (var photo in photos) {
      updatePhoto(photo);
    }
  }

  // Reminder
  @override
  Future<String> createReminder(ReminderModel reminder) async {
    final id = reminder.id.isEmpty ? 'reminder_${DateTime.now().millisecondsSinceEpoch}' : reminder.id;
    _reminders[id] = reminder.copyWith(id: id);
    return id;
  }

  @override
  Future<void> updateReminder(ReminderModel reminder) async {
    if (_reminders.containsKey(reminder.id)) {
      _reminders[reminder.id] = reminder;
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    _reminders.remove(reminderId);
  }

  @override
  Future<List<ReminderModel>> getUserReminders(String userId) async {
    return _reminders.values.where((r) => r.userId == userId).toList();
  }

  @override
  Stream<List<ReminderModel>> getUserRemindersStream(String userId) {
    return Stream.value([]);
  }

  @override
  Future<List<ReminderModel>> getTodayReminders(String userId) async {
    return [];
  }
}
