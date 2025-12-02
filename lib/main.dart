import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
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
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      print('✅ .env 파일 로드 성공');
      print('🔑 API 키 확인: ${apiKey.substring(0, apiKey.length > 10 ? 10 : apiKey.length)}...');
    } else {
      print('⚠️ .env 파일은 로드되었지만 GEMINI_API_KEY가 비어있습니다.');
      print('💡 .env 파일에 GEMINI_API_KEY=your_api_key_here 형식으로 추가해주세요.');
    }
  } catch (e) {
    print('⚠️ .env 파일 로드 실패: $e');
    print('💡 .env 파일을 생성하고 GEMINI_API_KEY를 설정하세요.');
  }
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase 초기화 성공');
  } catch (e) {
    print('❌ Firebase 초기화 실패: $e');
    // Firebase 초기화 실패 시에도 앱은 계속 실행
  }
  
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