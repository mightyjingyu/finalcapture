import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/photo_provider.dart';
import 'presentation/providers/album_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env 파일 로드
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env 파일 로드 성공');
  } catch (e) {
    print('⚠️ .env 파일 로드 실패: $e');
    print('💡 .env 파일이 없으면 기본 설정으로 진행합니다.');
  }

  // API Check
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey != null && apiKey.isNotEmpty) {
      print('🔑 API 키 확인: 설정됨');
  } else {
      print('⚠️ GEMINI_API_KEY가 비어있습니다.');
  }

  // Mock 모드 확인
  final useMockData = dotenv.env['USE_MOCK_DATA'] == 'true';

  if (!useMockData) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase 초기화 성공');
    } catch (e) {
      print('❌ Firebase 초기화 실패: $e');
      print('⚠️ Mock 모드로 전환을 고려해보세요 (.env에 USE_MOCK_DATA=true 설정)');
      // Firebase 실패 시 Mock 모드로 강제 전환할지 여부는 선택사항. 
      // 현재는 그냥 진행하여 에러를 보여주거나 ServiceLocator에서 처리.
      // 하지만 ServiceLocator.init(useMock: false)는 Firebase 인스턴스를 사용하므로 에러 발생 가능.
    }
  } else {
    print('🛠️ Mock Data 모드로 실행합니다. (Firebase 초기화 건너뜀)');
  }

  // ServiceLocator 초기화
  ServiceLocator.init(useMock: useMockData);
  
  runApp(const KimchiJjimApp());
}

class KimchiJjimApp extends StatelessWidget {
  const KimchiJjimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => AlbumProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
              ),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}