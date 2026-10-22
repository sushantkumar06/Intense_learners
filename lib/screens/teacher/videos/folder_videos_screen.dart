import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/teacher_video.dart';
import '../../../theme/app_theme.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/animated_pressable.dart';

class FolderVideosScreen extends StatelessWidget {
  final TeacherVideoFolder folder;

  const FolderVideosScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    return SafeBackScope(
      fallbackLocation: '/teacher/video-library',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // Top Navigation Bar
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
                      onPress: () => context.canPop()
                          ? context.pop()
                          : context.go('/teacher/video-library'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: AppRadius.smBorder,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.arrowLeft,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                folder.name,
                                style: AppTypography.h3.copyWith(
                                  fontSize: 16,
                                  color: AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (folder.youtubePlaylistId != null &&
                                folder.youtubePlaylistId!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.coral,
                                  borderRadius: AppRadius.pillBorder,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.play,
                                      size: 8,
                                      color: AppColors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      "YT",
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          "${folder.videoCount} videos · ${folder.chapter}",
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Videos List
            Expanded(
              child: folder.videos.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: AppColors.coralTint,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                LucideIcons.play,
                                size: 30,
                                color: AppColors.coral,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              "No videos found",
                              style: AppTypography.label.copyWith(
                                color: AppColors.ink,
                                fontSize: 15,
                              ),
                            ),
                            if (folder.youtubePlaylistId != null &&
                                folder.youtubePlaylistId!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  'Linked to YouTube — go to the "YouTube Sync" tab and tap Sync Now.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 12.5,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: folder.videos.length,
                      itemBuilder: (context, index) {
                        final video = folder.videos[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AnimatedPressable(
                            pressScale: 0.98,
                            onPress: () => context.push(
                              '/teacher/video-library/${folder.id}/player',
                              extra: {
                                'video': video,
                                'queue': folder.videos,
                                'folderName': folder.name,
                              },
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
                                  // Video Thumbnail Box
                                  SizedBox(
                                    width: 112,
                                    height: 80,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (video.thumbnail.isNotEmpty)
                                          Image.network(
                                            video.thumbnail,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                Container(
                                              color: AppColors.coralTint,
                                            ),
                                          )
                                        else
                                          Container(
                                            color: AppColors.coralTint,
                                            alignment: Alignment.center,
                                            child: Icon(
                                              LucideIcons.play,
                                              size: 20,
                                              color: AppColors.coral,
                                            ),
                                          ),
                                        Positioned(
                                          top: 6,
                                          left: 6,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.7,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              "${index + 1}",
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 5,
                                          right: 5,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.75,
                                              ),
                                              borderRadius: AppRadius.smBorder,
                                            ),
                                            child: Text(
                                              video.duration,
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 9.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Title and Views
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.md),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            video.title,
                                            style: AppTypography.label.copyWith(
                                              color: AppColors.ink,
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 7),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 4,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    LucideIcons.eye,
                                                    size: 11,
                                                    color: AppColors.inkFaint,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "${video.views}",
                                                    style: AppTypography.caption
                                                        .copyWith(
                                                      color: AppColors.inkMuted,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                "${video.uniqueViewers} unique",
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  color: AppColors.inkFaint,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              Text(
                                                "${video.totalWatchTime} watched",
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  color: AppColors.inkFaint,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Quick external YouTube Play icon
                                  AnimatedPressable(
                                    pressScale: 0.9,
                                    onPress: () => launchUrl(
                                      Uri.parse(
                                        "https://www.youtube.com/watch?v=${video.videoUrl}",
                                      ),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                      ),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.coralTint,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          LucideIcons.play,
                                          size: 14,
                                          color: AppColors.coral,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
