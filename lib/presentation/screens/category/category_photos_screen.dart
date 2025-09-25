import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/photo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/photo_grid.dart';

class CategoryPhotosScreen extends StatelessWidget {
  final String category;
  final String categoryIcon;

  const CategoryPhotosScreen({
    super.key,
    required this.category,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              categoryIcon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Consumer2<AuthProvider, PhotoProvider>(
                    builder: (context, authProvider, photoProvider, child) {
                      final categoryPhotos = photoProvider.photos
                          .where((photo) => photo.category == category)
                          .toList();
                      return Text(
                        '${categoryPhotos.length}개의 사진',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        actions: [
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadCategoryPhotos(context),
              tooltip: '폴더 다운로드',
            ),
        ],
      ),
      body: Consumer2<AuthProvider, PhotoProvider>(
        builder: (context, authProvider, photoProvider, child) {
          if (!authProvider.isAuthenticated) {
            return const Center(
              child: Text('로그인이 필요합니다.'),
            );
          }

          final categoryPhotos = photoProvider.photos
              .where((photo) => photo.category == category)
              .toList();

          if (categoryPhotos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    categoryIcon,
                    style: const TextStyle(
                      fontSize: 64,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$category 폴더가 비어있습니다',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '사진을 업로드하면 자동으로 분류됩니다',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return PhotoGrid(
            photos: categoryPhotos,
            onPhotoTap: (photo) => _showPhotoDetail(context, photo),
            onPhotoLongPress: (photo) => _showPhotoOptions(context, photo),
          );
        },
      ),
    );
  }

  void _showPhotoDetail(BuildContext context, photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(photo.fileName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photo.ocrText?.isNotEmpty == true) ...[
              const Text(
                '추출된 텍스트:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(photo.ocrText!),
              ),
              const SizedBox(height: 12),
            ],
            Text('카테고리: ${photo.category}'),
            Text('업로드 날짜: ${photo.createdAt.toString().split(' ')[0]}'),
            if (photo.metadata?['confidence'] != null)
              Text('신뢰도: ${(photo.metadata!['confidence'] * 100).toStringAsFixed(1)}%'),
            if (photo.metadata?['reasoning'] != null) ...[
              const SizedBox(height: 8),
              const Text(
                '분류 근거:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  photo.metadata!['reasoning'],
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (kIsWeb)
            TextButton.icon(
              onPressed: () => _downloadPhoto(context, photo),
              icon: const Icon(Icons.download),
              label: const Text('다운로드'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions(BuildContext context, photo) {
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
              leading: Icon(
                photo.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: photo.isFavorite ? Colors.red : null,
              ),
              title: Text(photo.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가'),
              onTap: () {
                Navigator.pop(context);
                final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
                photoProvider.togglePhotoFavorite(photo.id);
              },
            ),
            if (kIsWeb)
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('다운로드'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadPhoto(context, photo);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('상세 정보'),
              onTap: () {
                Navigator.pop(context);
                _showPhotoDetail(context, photo);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadCategoryPhotos(BuildContext context) async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final categoryPhotos = photoProvider.photos
        .where((photo) => photo.category == category)
        .toList();

    if (categoryPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('다운로드할 사진이 없습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$category 폴더의 ${categoryPhotos.length}개 사진을 다운로드합니다.'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: '확인',
          textColor: AppColors.textOnPrimary,
          onPressed: () {
            // TODO: 실제 다운로드 구현
          },
        ),
      ),
    );
  }

  Future<void> _downloadPhoto(BuildContext context, photo) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${photo.fileName} 다운로드를 시작합니다.'),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: '확인',
            textColor: AppColors.textOnPrimary,
            onPressed: () {
              // TODO: 실제 다운로드 구현
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('다운로드 실패: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
