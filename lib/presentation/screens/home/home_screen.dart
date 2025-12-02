import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
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

      // 카테고리별 폴더 생성
      await photoProvider.createAllCategoryFolders(userId);

      // 데이터 로드
      await Future.wait([
        photoProvider.initialize(userId),
        albumProvider.loadUserAlbums(userId),
      ]);

      // 자동 분류 제거 - 사용자가 수동으로 분류시작 버튼을 눌러야 함

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
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      final userId = authProvider.firebaseUser!.uid;
      
      // 사진 새로고침 (새로 추가된 사진만 처리 - API 비용 절약)
      await photoProvider.refresh(userId, forceReprocess: false);
      
      // 앨범 데이터도 새로고침
      await albumProvider.loadUserAlbums(userId);
    }
  }

  Future<void> _startClassification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) return;

    try {
      final userId = authProvider.firebaseUser!.uid;
      
      // 분류 시작 (이미 분류된 사진도 재분류)
      await photoProvider.startClassification(userId);
      
      // 앨범 데이터도 새로고침
      await albumProvider.loadUserAlbums(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('분류가 완료되었습니다!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('분류 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
          // 강제 OCR 재처리 버튼
          IconButton(
            onPressed: () async {
              final user = context.read<AuthProvider>().currentUser;
              if (user != null) {
                await context.read<PhotoProvider>().refresh(user.uid, forceReprocess: true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('모든 스크린샷을 다시 OCR 분석합니다... (API 비용 발생)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.refresh),
            tooltip: '강제 OCR 재처리 (API 비용 발생)',
          ),
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
    );
  }

  Widget _buildRecentPhotosTab(PhotoProvider photoProvider) {
    if (photoProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // latestScreenshots (AssetEntity) 사용 - 실제 갤러리에서 로드된 사진들
    if (photoProvider.latestScreenshots.isEmpty) {
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
              '아직 사진이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '갤러리에서 사진을 확인해보세요',
              style: TextStyle(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 분류시작 버튼
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: photoProvider.isProcessing ? null : () => _startClassification(),
            icon: photoProvider.isProcessing 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
            label: Text(
              photoProvider.isProcessing ? '분류 중...' : '분류시작',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // 사진 그리드
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppConstants.gridCrossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: AppConstants.gridAspectRatio,
            ),
            itemCount: photoProvider.latestScreenshots.length,
            itemBuilder: (context, index) {
              final asset = photoProvider.latestScreenshots[index];
              return _buildAssetTile(asset);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritePhotosTab(PhotoProvider photoProvider) {
    if (photoProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (photoProvider.favoriteScreenshots.isEmpty) {
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
      itemCount: photoProvider.favoriteScreenshots.length,
      itemBuilder: (context, index) {
        final asset = photoProvider.favoriteScreenshots[index];
        return _buildAssetTile(asset);
      },
    );
  }

  Widget _buildAssetTile(AssetEntity asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // AssetEntity에서 이미지 표시
          FutureBuilder<Uint8List?>(
            future: asset.thumbnailData,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _placeholder();
                  },
                );
              } else if (snapshot.hasError) {
                return _placeholder();
              } else {
                return _placeholder();
              }
            },
          ),
          // 상단 우측 즐겨찾기 버튼
          Positioned(
            top: 8,
            right: 8,
            child: Consumer<PhotoProvider>(
              builder: (context, photoProvider, child) {
                // 해당 AssetEntity가 즐겨찾기인지 확인
                final isFavorite = photoProvider.isAssetFavorite(asset);
                
                return GestureDetector(
                  onTap: () async {
                    await _toggleAssetFavorite(context, asset, photoProvider);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // AssetEntity 즐겨찾기 토글
  Future<void> _toggleAssetFavorite(BuildContext context, AssetEntity asset, PhotoProvider photoProvider) async {
    try {
      // AssetEntity 즐겨찾기 토글
      final isNowFavorite = await photoProvider.toggleAssetFavorite(asset);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNowFavorite ? '즐겨찾기에 추가되었습니다!' : '즐겨찾기에서 제거되었습니다!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 즐겨찾기 토글 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('즐겨찾기 변경 실패: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.photo,
          size: 32,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
