# 김치찜 (KimchiJjim) 📱

AI로 스크린샷을 자동 분류하고 관리하는 크로스플랫폼 Flutter 앱

## 🚀 주요 기능

### 📸 스크린샷 자동 관리
- 새로운 스크린샷 자동 감지
- Gemini AI를 통한 OCR 텍스트 추출
- AI 기반 자동 카테고리 분류
- 8가지 기본 카테고리 지원

### 📁 스마트 앨범 시스템
- 카테고리별 자동 분류
- 최대 3개 앨범 고정 가능
- 즐겨찾기 및 최근 항목 관리
- 드래그 앤 드롭으로 간편한 분류

### ⏰ 알림 기능
- 중요한 스크린샷 알림 설정
- 일정/예약 관련 자동 알림
- Firebase Cloud Messaging 기반

### 🔐 안전한 로그인
- Google 로그인
- Apple 로그인 (iOS)
- Firebase Authentication

## 🛠 기술 스택

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Cloud Messaging
- **AI**: Google Gemini API
- **State Management**: Provider
- **Local Storage**: 갤러리 연동

## 📋 설치 및 설정

### 1. 환경 요구사항
- Flutter 3.7.2 이상
- Dart SDK
- Android Studio / Xcode
- Firebase 프로젝트

### 2. Firebase 설정

#### 2.1 Firebase 프로젝트 생성
1. [Firebase Console](https://console.firebase.google.com/)에서 새 프로젝트 생성
2. Authentication, Cloud Firestore, Cloud Messaging 활성화

#### 2.2 Android 설정
1. Firebase Console에서 Android 앱 추가
2. 패키지명: `com.kimchijjim.captureapp.kimchi_jjim`
3. `google-services.json` 파일 다운로드
4. `android/app/` 폴더에 복사

#### 2.3 iOS 설정
1. Firebase Console에서 iOS 앱 추가
2. Bundle ID: `com.kimchijjim.captureapp.kimchiJjim`
3. `GoogleService-Info.plist` 파일 다운로드
4. Xcode에서 Runner 프로젝트에 추가

### 3. API 키 설정

#### 3.1 Gemini API 키
1. [Google AI Studio](https://makersuite.google.com/app/apikey)에서 API 키 생성
2. `lib/data/services/gemini_service.dart` 파일의 `_apiKey` 변수에 설정

```dart
final String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
```

### 4. 패키지 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# iOS 설정 (iOS만)
cd ios && pod install && cd ..

# 앱 실행
flutter run
```

## 📱 지원 플랫폼

- ✅ Android 6.0 (API 23) 이상
- ✅ iOS 12.0 이상

## 🎨 앱 구조

```
lib/
├── core/
│   ├── constants/          # 앱 상수 및 색상
│   ├── utils/             # 유틸리티 함수
│   └── extensions/        # Dart 확장
├── data/
│   ├── models/            # 데이터 모델
│   ├── services/          # 비즈니스 로직
│   └── repositories/      # 데이터 저장소
└── presentation/
    ├── screens/           # 화면 UI
    ├── widgets/          # 재사용 위젯
    └── providers/        # 상태 관리
```

## 🔧 주요 클래스

### 데이터 모델
- `UserModel`: 사용자 정보
- `AlbumModel`: 앨범 정보
- `PhotoModel`: 사진 메타데이터
- `ReminderModel`: 알림 정보

### 서비스 클래스
- `AuthService`: 인증 관리
- `PhotoService`: 사진 처리
- `FirestoreService`: 데이터베이스 연동
- `GeminiService`: AI OCR 및 분류

### Provider 클래스
- `AuthProvider`: 인증 상태 관리
- `PhotoProvider`: 사진 목록 관리
- `AlbumProvider`: 앨범 관리

## 📖 사용법

### 첫 설정
1. 앱 설치 후 Google/Apple 계정으로 로그인
2. 갤러리 접근 권한 허용
3. 알림 권한 허용

### 기본 사용
1. **자동 분류**: 스크린샷을 찍으면 자동으로 AI가 분류
2. **수동 정리**: 드래그 앤 드롭으로 사진 이동
3. **즐겨찾기**: 중요한 사진을 즐겨찾기에 추가
4. **알림 설정**: 일정이 있는 사진에 알림 설정

## 🚨 문제 해결

### Firebase 초기화 오류
```
Firebase initialization error: [firebase_core/no-app] No Firebase App '[DEFAULT]' has been created
```

**해결방법**:
1. `google-services.json` (Android) 또는 `GoogleService-Info.plist` (iOS) 파일 확인
2. Firebase 프로젝트 설정 검토
3. 패키지명/Bundle ID 일치 확인

### 권한 오류
**갤러리 접근 권한이 없는 경우**:
- 설정 → 앱 → 김치찜 → 권한에서 사진 접근 허용

### Gemini API 오류
```
Gemini API Error: 403
```

**해결방법**:
1. API 키 확인
2. Gemini API 사용량 한도 확인
3. API 키 권한 설정 확인

## 🔮 향후 계획

- [ ] 사진 태그 시스템
- [ ] 고급 검색 필터
- [ ] 다크 모드 지원
- [ ] 앨범 공유 기능
- [ ] 사진 편집 기능
- [ ] 데이터 내보내기

## 📄 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다.

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

**Made with ❤️ by KimchiJjim Team**