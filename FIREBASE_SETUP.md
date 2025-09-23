# 🔥 Firebase 설정 완료 가이드

## ✅ 완료된 설정

### 1. Firebase 프로젝트 생성
- **프로젝트 ID**: `finalcapture`
- **프로젝트 번호**: `797406662895`
- **Firebase Console URL**: https://console.firebase.google.com/project/finalcapture/overview

### 2. Flutter 앱 설정
- ✅ Firebase CLI 설치 및 로그인 완료
- ✅ FlutterFire CLI 설치 완료
- ✅ `firebase_options.dart` 파일 생성 완료
- ✅ `lib/main.dart`에 Firebase 초기화 코드 추가 완료

### 3. Android 설정
- ✅ `android/app/google-services.json` 파일 추가됨
- ✅ `android/app/build.gradle.kts`에 Google Services 플러그인 추가됨
- ✅ `android/settings.gradle.kts`에 Firebase 플러그인 설정됨
- ✅ `android/app/src/main/AndroidManifest.xml`에 필요한 권한들 추가됨

### 4. iOS 설정
- ✅ `ios/Runner/GoogleService-Info.plist` 파일 추가됨
- ✅ `ios/Runner/Info.plist`에 갤러리 접근 권한 설명 추가됨
- ✅ 백그라운드 모드 설정 완료

---

## 🚀 다음 단계: Firebase 서비스 활성화

Firebase Console에서 다음 서비스들을 활성화해야 합니다:

### 1. Authentication 설정
1. Firebase Console 접속: https://console.firebase.google.com/project/finalcapture/authentication
2. **Sign-in method** 탭 클릭
3. 다음 로그인 방법들을 활성화:
   - **Google**: 활성화 후 프로젝트 지원 이메일 설정
   - **Apple** (iOS용): Apple Developer 계정 필요

### 2. Cloud Firestore 설정
1. Firebase Console 접속: https://console.firebase.google.com/project/finalcapture/firestore
2. **Create database** 클릭
3. **Start in test mode** 선택 (나중에 보안 규칙 수정)
4. 지역 선택: **asia-northeast3 (Seoul)** 권장

### 3. Cloud Messaging 설정
1. Firebase Console 접속: https://console.firebase.google.com/project/finalcapture/settings/cloudmessaging
2. Cloud Messaging API 활성화
3. iOS용 APNs 키 업로드 (Apple Developer Console에서 생성)

---

## 📱 테스트 실행

설정이 완료되면 다음 명령어로 앱을 테스트할 수 있습니다:

```bash
# Android 에뮬레이터 또는 실제 기기에서 실행
flutter run

# iOS 시뮬레이터 또는 실제 기기에서 실행 (macOS만)
flutter run -d ios
```

---

## 🔑 Gemini API 키 설정

김치찜 앱의 AI 기능을 사용하려면 Gemini API 키가 필요합니다:

### 1. Gemini API 키 생성
1. Google AI Studio 접속: https://makersuite.google.com/app/apikey
2. **Create API Key** 클릭
3. API 키 복사

### 2. 앱에 API 키 설정
`lib/data/services/gemini_service.dart` 파일을 열고 다음 라인을 수정:

```dart
final String _apiKey = 'YOUR_GEMINI_API_KEY_HERE'; // 여기에 실제 API 키 입력
```

---

## 🛡️ 보안 설정

### Firestore 보안 규칙
테스트 완료 후 Firestore 보안 규칙을 업데이트하세요:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자는 자신의 데이터만 읽고 쓸 수 있음
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /albums/{albumId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    match /photos/{photoId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    match /reminders/{reminderId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## 🔧 문제 해결

### Firebase 초기화 오류
```
Firebase initialization error: [firebase_core/no-app] No Firebase App '[DEFAULT]' has been created
```

**해결방법**:
1. `google-services.json` (Android) 파일이 올바른 위치에 있는지 확인
2. `GoogleService-Info.plist` (iOS) 파일이 Xcode 프로젝트에 추가되었는지 확인
3. Firebase 콘솔에서 앱이 정상 등록되었는지 확인

### 권한 관련 오류
**Android**: 
- `android/app/src/main/AndroidManifest.xml`에서 권한 설정 확인
- Android 13+ 기기에서는 런타임 권한 요청 필요

**iOS**: 
- `ios/Runner/Info.plist`에서 권한 설명 문구 확인
- iOS 14+ 기기에서는 앱 추적 투명성 정책 준수 필요

### Gemini API 오류
```
Gemini API Error: 403
```

**해결방법**:
1. API 키 확인
2. Gemini API 사용량 한도 확인
3. 네트워크 연결 상태 확인

---

## 📞 지원

문제가 발생하면 다음 리소스를 참고하세요:

- [Firebase 문서](https://firebase.google.com/docs)
- [FlutterFire 문서](https://firebase.flutter.dev/)
- [Flutter 문서](https://docs.flutter.dev/)
- [Gemini API 문서](https://developers.generativeai.google.com/)

---

**🎉 Firebase 설정이 완료되었습니다! 김치찜 앱을 테스트해보세요!**
