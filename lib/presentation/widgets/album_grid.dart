import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../providers/album_provider.dart';
import '../providers/auth_provider.dart';

class AlbumGrid extends StatelessWidget {
  const AlbumGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AlbumProvider, AuthProvider>(
      builder: (context, albumProvider, authProvider, child) {
        if (albumProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (albumProvider.albums.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_album_outlined,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                SizedBox(height: 16),
                Text(
                  '앨범이 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // 고정 탭들 (최근 항목, 기한이 있는 항목, 즐겨찾기)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '빠른 접근',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final quickAccessAlbums = [
                      _QuickAccessAlbum(
                        name: '최근 항목',
                        icon: '🕒',
                        color: AppColors.primary,
                        onTap: () => _navigateToRecent(context),
                      ),
                      _QuickAccessAlbum(
                        name: '기한이 있는 항목',
                        icon: '⏰',
                        color: Colors.orange,
                        onTap: () => _navigateToScheduled(context),
                      ),
                      _QuickAccessAlbum(
                        name: '즐겨찾기',
                        icon: '⭐',
                        color: Colors.amber,
                        onTap: () => _navigateToFavorites(context),
                      ),
                    ];
                    return _QuickAccessCard(album: quickAccessAlbums[index]);
                  },
                  childCount: 3,
                ),
              ),
            ),

            // 카테고리 앨범들
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '카테고리',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final categoryAlbums = albumProvider.albums
                        .where((album) => AppConstants.defaultCategories.contains(album.name))
                        .toList();
                    
                    if (index >= categoryAlbums.length) return null;
                    
                    final album = categoryAlbums[index];
                    return _AlbumCard(
                      album: album,
                      isPinned: false,
                    );
                  },
                  childCount: albumProvider.albums
                      .where((album) => AppConstants.defaultCategories.contains(album.name))
                      .length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 빠른 접근 탭들로 이동하는 메서드들
  void _navigateToRecent(BuildContext context) {
    // TODO: 최근 항목 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('최근 항목은 "최근" 탭에서 확인하세요')),
    );
  }

  void _navigateToScheduled(BuildContext context) {
    // TODO: 기한이 있는 항목 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('기한이 있는 항목 기능은 준비 중입니다')),
    );
  }

  void _navigateToFavorites(BuildContext context) {
    // TODO: 즐겨찾기 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('즐겨찾기는 "즐겨찾기" 탭에서 확인하세요')),
    );
  }
}

// 빠른 접근 앨범 모델
class _QuickAccessAlbum {
  final String name;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAccessAlbum({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// 빠른 접근 카드 위젯
class _QuickAccessCard extends StatelessWidget {
  final _QuickAccessAlbum album;

  const _QuickAccessCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: album.onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            gradient: LinearGradient(
              colors: [
                album.color.withOpacity(0.15),
                album.color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: album.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    album.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 이름
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  album.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final dynamic album; // AlbumModel
  final bool isPinned;

  const _AlbumCard({
    required this.album,
    required this.isPinned,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isPinned ? 4 : 2,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to album detail screen
        },
        onLongPress: () {
          _showAlbumOptions(context);
        },
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            gradient: LinearGradient(
              colors: [
                _getAlbumColor().withOpacity(0.1),
                _getAlbumColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앨범 아이콘
              Container(
                width: isPinned ? 48 : 36,
                height: isPinned ? 48 : 36,
                decoration: BoxDecoration(
                  color: _getAlbumColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    album.iconPath ?? '📷',
                    style: TextStyle(
                      fontSize: isPinned ? 24 : 18,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: isPinned ? 12 : 8),
              
              // 앨범 이름
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  album.name ?? 'Unknown',
                  style: TextStyle(
                    fontSize: isPinned ? 14 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // 사진 개수
              Text(
                '${album.photoCount ?? 0}장',
                style: TextStyle(
                  fontSize: isPinned ? 12 : 10,
                  color: AppColors.textSecondary,
                ),
              ),
              
              // 고정 표시
              if (isPinned)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '고정',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAlbumColor() {
    if (album.colorCode != null) {
      try {
        return Color(int.parse(album.colorCode.replaceFirst('#', '0xFF')));
      } catch (e) {
        return AppColors.primary;
      }
    }
    return AppColors.primary;
  }

  void _showAlbumOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('앨범 수정'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show edit album dialog
              },
            ),
            ListTile(
              leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(isPinned ? '고정 해제' : '고정'),
              onTap: () {
                Navigator.pop(context);
                final albumProvider = Provider.of<AlbumProvider>(context, listen: false);
                albumProvider.toggleAlbumPin(album.id);
              },
            ),
            if (!album.isDefault)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('삭제', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앨범 삭제'),
        content: Text('${album.name} 앨범을 삭제하시겠습니까?\n앨범의 모든 사진도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final albumProvider = Provider.of<AlbumProvider>(context, listen: false);
              albumProvider.deleteAlbum(album.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
