import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/photo_model.dart';
import '../providers/photo_provider.dart';

class PhotoGrid extends StatelessWidget {
  final List<PhotoModel> photos;
  final Function(PhotoModel)? onPhotoTap;
  final Function(PhotoModel)? onPhotoLongPress;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.onPhotoTap,
    this.onPhotoLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
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
              '사진이 없습니다',
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.gridCrossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: AppConstants.gridAspectRatio,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return _PhotoTile(
          photo: photo,
          onTap: () => onPhotoTap?.call(photo),
          onLongPress: () => onPhotoLongPress?.call(photo),
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final PhotoModel photo;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _PhotoTile({
    required this.photo,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 이미지 표시
          GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: _buildImage(),
          ),
          
          // 즐겨찾기 아이콘
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                photo.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          
          // 카테고리 배지
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getCategoryIcon(photo.category),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // OCR 텍스트가 있는 경우 표시
          if (photo.ocrText?.isNotEmpty == true)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.text_fields,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      // 웹에서는 Provider를 통해 이미지 바이트 데이터 가져오기
      return Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          final imageBytes = photoProvider.getWebImageBytes(photo.id);
          if (imageBytes != null) {
            return Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildWebPlaceholder();
              },
            );
          } else {
            // 바이트 데이터가 없으면 카테고리 아이콘과 함께 플레이스홀더 표시
            return _buildWebPlaceholder();
          }
        },
      );
    } else {
      // 모바일에서는 로컬 파일 사용
      return Image.file(
        File(photo.localPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _placeholder();
        },
      );
    }
  }

  Widget _buildWebPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getCategoryIcon(photo.category),
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              photo.category,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              photo.fileName,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '웹에서 업로드됨',
              style: TextStyle(
                fontSize: 8,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
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

  String _getCategoryIcon(String category) {
    switch (category) {
      case '정보/참고용':
        return '📄';
      case '대화/메시지':
        return '💬';
      case '학습/업무 메모':
        return '📝';
      case '재미/밈/감정':
        return '😄';
      case '일정/예약':
        return '📅';
      case '증빙/거래':
        return '💳';
      case '옷':
        return '👕';
      case '제품':
        return '📦';
      default:
        return '📷';
    }
  }
}
