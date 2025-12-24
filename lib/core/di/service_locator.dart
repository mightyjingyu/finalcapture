import '../../data/services/interfaces/i_auth_service.dart';
import '../../data/services/interfaces/i_firestore_service.dart';
import '../../data/services/interfaces/i_photo_service.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/photo_service.dart';

import '../../data/services/mock/mock_auth_service.dart';
import '../../data/services/mock/mock_firestore_service.dart';
import '../../data/services/mock/mock_photo_service.dart';

class ServiceLocator {
  static late IAuthService authService;
  static late IFirestoreService firestoreService;
  static late IPhotoService photoService;

  static void init({bool useMock = false}) {
    print('🔧 ServiceLocator Initializing... Mode: ${useMock ? "MOCK" : "REAL"}');
    
    if (useMock) {
      firestoreService = MockFirestoreService(); // Init firestore first as others might depend on it (though interfaces don't enforce order, implementations might)
      authService = MockAuthService();
      photoService = MockPhotoService();
    } else {
      firestoreService = FirebaseFirestoreService();
      authService = FirebaseAuthService();
      photoService = FirebasePhotoService();
    }
    
    print('✅ ServiceLocator Initialized');
  }
}
