import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 프로필 섹션
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: authProvider.currentUser?.photoUrl != null
                            ? NetworkImage(authProvider.currentUser!.photoUrl!)
                            : null,
                        child: authProvider.currentUser?.photoUrl == null
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.currentUser?.displayName ?? '사용자',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authProvider.currentUser?.email ?? '',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 앱 설정
              const Text(
                '앱 설정',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('갤러리 권한'),
                      subtitle: const Text('스크린샷 자동 불러오기'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Open permission settings
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('알림 설정'),
                      subtitle: const Text('알림 시간 및 방식 설정'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Open notification settings
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.category),
                      title: const Text('카테고리 관리'),
                      subtitle: const Text('분류 카테고리 수정'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Open category management
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 데이터 관리
              const Text(
                '데이터 관리',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('데이터 동기화'),
                      subtitle: const Text('클라우드와 동기화'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Sync data
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.backup),
                      title: const Text('백업 및 복원'),
                      subtitle: const Text('데이터 백업 설정'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Open backup settings
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('저장공간 정리'),
                      subtitle: const Text('캐시 및 임시 파일 삭제'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Clean storage
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 정보
              const Text(
                '정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('앱 정보'),
                      subtitle: Text('버전 ${AppConstants.appVersion}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Show app info
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('개인정보처리방침'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Open privacy policy
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('이용약관'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Open terms of service
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 계정 관리
              const Text(
                '계정 관리',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.textSecondary),
                      title: const Text('로그아웃'),
                      onTap: () => _showLogoutDialog(context, authProvider),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: AppColors.error),
                      title: const Text('계정 삭제', style: TextStyle(color: AppColors.error)),
                      onTap: () => _showDeleteAccountDialog(context, authProvider),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text(
          '계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다.\n'
          '이 작업은 되돌릴 수 없습니다.\n\n'
          '정말 계정을 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await authProvider.deleteAccount();
              if (success && context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
