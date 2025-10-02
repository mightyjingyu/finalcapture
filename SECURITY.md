# 🔐 보안 가이드

## API 키 관리

### 1. 환경변수 설정
프로젝트를 실행하기 전에 `.env` 파일을 생성하고 API 키를 설정하세요:

```bash
# .env 파일 생성
cp env.example .env

# .env 파일 편집
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

### 2. 보안 주의사항

⚠️ **중요**: 다음 파일들은 절대 Git에 커밋하지 마세요:
- `.env`
- `google-services.json`
- `GoogleService-Info.plist`
- `firebase_options.dart`

### 3. API 키 발급

1. **Gemini API 키**: [Google AI Studio](https://aistudio.google.com/)에서 발급
2. **Firebase API 키**: [Firebase Console](https://console.firebase.google.com/)에서 발급

### 4. 배포 시 주의사항

- 프로덕션 환경에서는 환경변수나 시크릿 관리 서비스를 사용하세요
- API 키는 절대 클라이언트 사이드에 하드코딩하지 마세요
- 정기적으로 API 키를 로테이션하세요

## 현재 보안 상태

✅ **해결됨**:
- API 키가 환경변수로 관리됨
- `.gitignore`에 민감한 파일들 추가됨
- 하드코딩된 API 키 제거됨

## 문제 해결

### 환경변수 로드 실패 시
```
⚠️ 환경변수 로드 실패: FileSystemException
💡 .env 파일을 생성하고 GEMINI_API_KEY를 설정하세요.
```

**해결방법**:
1. 프로젝트 루트에 `.env` 파일 생성
2. `GEMINI_API_KEY=your_api_key_here` 추가
3. 앱 재시작
