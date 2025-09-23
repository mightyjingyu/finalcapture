import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/album_provider.dart';
import '../../providers/photo_provider.dart';
import '../../widgets/album_grid.dart';
import '../../widgets/permission_dialog.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) return;

    try {
      // 권한 확인 및 요청
      final hasPermissions = await photoProvider.requestPermissions();
      
      if (!hasPermissions && mounted) {
        _showPermissionDialog();
        return;
      }

      final userId = authProvider.firebaseUser!.uid;

      // 기본 앨범 초기화 (새 사용자인 경우)
      await albumProvider.loadUserAlbums(userId);
      if (albumProvider.albums.isEmpty) {
        await albumProvider.initializeDefaultAlbums(userId);
      }

      // 데이터 로드
      await Future.wait([
        photoProvider.initialize(userId),
        albumProvider.loadUserAlbums(userId),
      ]);

      // 새로운 스크린샷 처리
      await photoProvider.processNewScreenshots(userId);

    } catch (e) {
      print('App initialization error: $e');
      _showErrorSnackbar('앱 초기화 중 오류가 발생했습니다: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PermissionDialog(),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      await photoProvider.refresh(authProvider.firebaseUser!.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '🥬',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.photo_library_outlined),
              text: '앨범',
            ),
            Tab(
              icon: Icon(Icons.access_time_outlined),
              text: '최근',
            ),
            Tab(
              icon: Icon(Icons.favorite_outline),
              text: '즐겨찾기',
            ),
          ],
        ),
      ),
      body: Consumer3<AuthProvider, AlbumProvider, PhotoProvider>(
        builder: (context, authProvider, albumProvider, photoProvider, child) {
          if (!authProvider.isAuthenticated) {
            return const Center(
              child: Text('로그인이 필요합니다.'),
            );
          }

          if (!photoProvider.hasPermissions) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '갤러리 접근 권한이 필요합니다',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '설정에서 권한을 허용해주세요',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // 앨범 탭
              RefreshIndicator(
                onRefresh: _handleRefresh,
                child: const AlbumGrid(),
              ),
              
              // 최근 탭
              RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _buildRecentPhotosTab(photoProvider),
              ),
              
              // 즐겨찾기 탭
              RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _buildFavoritePhotosTab(photoProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          if (photoProvider.isProcessing) {
            return FloatingActionButton(
              onPressed: null,
              backgroundColor: AppColors.surfaceVariant,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            );
          }

          return FloatingActionButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.isAuthenticated) {
                if (kIsWeb) {
                  // 웹에서는 사진 선택
                  await photoProvider.pickAndProcessImages(
                    authProvider.firebaseUser!.uid,
                  );
                } else {
                  // 모바일에서는 스크린샷 처리
                  await photoProvider.processNewScreenshots(
                    authProvider.firebaseUser!.uid,
                  );
                }
              }
            },
            backgroundColor: AppColors.primary,
            child: Icon(
              kIsWeb ? Icons.upload : Icons.sync,
              color: AppColors.textOnPrimary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentPhotosTab(PhotoProvider photoProvider) {
    if (photoProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (photoProvider.recentPhotos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              '아직 스크린샷이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '스크린샷을 찍으면 자동으로 분류됩니다',
              style: TextStyle(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.gridCrossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: AppConstants.gridAspectRatio,
      ),
      itemCount: photoProvider.recentPhotos.length,
      itemBuilder: (context, index) {
        final photo = photoProvider.recentPhotos[index];
        return _buildPhotoTile(photo);
      },
    );
  }

  Widget _buildFavoritePhotosTab(PhotoProvider photoProvider) {
    if (photoProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (photoProvider.favoritePhotos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              '즐겨찾기한 사진이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '사진을 길게 눌러 즐겨찾기에 추가하세요',
              style: TextStyle(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.gridCrossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: AppConstants.gridAspectRatio,
      ),
      itemCount: photoProvider.favoritePhotos.length,
      itemBuilder: (context, index) {
        final photo = photoProvider.favoritePhotos[index];
        return _buildPhotoTile(photo);
      },
    );
  }

  Widget _buildPhotoTile(dynamic photo) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          gradient: AppColors.backgroundGradient,
        ),
        child: const Center(
          child: Icon(
            Icons.photo,
            size: 32,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
