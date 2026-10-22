import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../models/video.dart';
import '../../../theme/app_theme.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/ui.dart';

class FolderDetailScreen extends StatelessWidget {
  final VideoFolder folder;

  const FolderDetailScreen({
    super.key,
    required this.folder,
  });

  @override
  Widget build(BuildContext context) {
    return SafeBackScope(
      fallbackLocation: '/student/videos',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedPressable(
                      pressScale: 0.9,
                      onPress: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/student/videos');
                        }
                      },
                      child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: AppRadius.smBorder,
                      ),
                      alignment: Alignment.center,
                      child: Icon(LucideIcons.arrowLeft, size: 18, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: AppTypography.h3.copyWith(fontSize: 16, color: AppColors.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          "${folder.videoCount} videos · ${folder.totalDuration}",
                          style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Video List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: folder.videos.length,
                itemBuilder: (context, index) {
                  final video = folder.videos[index];
                  return RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                    child: AnimatedPressable(
                      pressScale: 0.98,
                      onPress: () => context.push(
                        '/student/videos/${folder.id}/${video.id}',
                        extra: {'video': video, 'folderName': folder.name},
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lgBorder,
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          children: [
                            // Thumbnail
                            SizedBox(
                              width: 118,
                              height: 84,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(color: AppColors.indigoTint),
                                  if (video.thumbnail.isNotEmpty)
                                    Image.network(
                                      video.thumbnail,
                                      fit: BoxFit.cover,
                                      cacheWidth: 320,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Icon(LucideIcons.play, size: 20, color: AppColors.indigo),
                                      ),
                                    )
                                  else
                                    Center(
                                      child: Icon(LucideIcons.play, size: 20, color: AppColors.indigo),
                                    ),
                                  // Index badge top-left
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withValues(alpha: 0.7),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "${index + 1}",
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Watched progress bar bottom
                                  if (video.watchedPercentage > 0)
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      height: 3,
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: (video.watchedPercentage / 100.0).clamp(0.0, 1.0),
                                          child: Container(
                                            color: video.watched ? AppColors.mint : AppColors.gold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Content Details
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      video.duration,
                                      style: AppTypography.caption.copyWith(color: AppColors.inkFaint),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      video.title,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 13.5,
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (video.watched) ...[
                                          Icon(LucideIcons.checkCircle, size: 11, color: AppColors.mint),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Watched",
                                            style: AppTypography.caption.copyWith(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.mint,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ] else if (video.watchedPercentage > 0) ...[
                                          Text(
                                            "${video.watchedPercentage.round()}% watched",
                                            style: AppTypography.caption.copyWith(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.gold,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Icon(LucideIcons.eye, size: 11, color: AppColors.inkFaint),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${video.views}",
                                          style: AppTypography.caption.copyWith(color: AppColors.inkFaint),
                                        ),
                                        if (video.bookmarked) ...[
                                          const SizedBox(width: 10),
                                          Icon(LucideIcons.bookmarkCheck, size: 11, color: AppColors.gold),
                                          const SizedBox(width: 3),
                                          Text(
                                            "Saved",
                                            style: AppTypography.caption.copyWith(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.gold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
