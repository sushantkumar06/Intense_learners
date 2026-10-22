import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../models/teacher_video.dart';
import '../../../theme/app_theme.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/animated_pressable.dart';

class TeacherVideoPlayerScreen extends StatefulWidget {
  final TeacherVideoItem video;
  final List<TeacherVideoItem> queue;
  final String folderName;

  const TeacherVideoPlayerScreen({
    super.key,
    required this.video,
    required this.queue,
    required this.folderName,
  });

  @override
  State<TeacherVideoPlayerScreen> createState() =>
      _TeacherVideoPlayerScreenState();
}

class _TeacherVideoPlayerScreenState extends State<TeacherVideoPlayerScreen> {
  late YoutubePlayerController _controller;
  late TeacherVideoItem _currentVideo;
  bool _showQueue = false;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;
    _initPlayer();
  }

  void _initPlayer() {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: _currentVideo.videoUrl,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  void _goTo(TeacherVideoItem v) {
    setState(() {
      _currentVideo = v;
      _showQueue = false;
    });
    _controller.loadVideoById(videoId: v.videoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex =
        widget.queue.indexWhere((v) => v.id == _currentVideo.id);
    final nextVideo = currentIndex >= 0 && currentIndex < widget.queue.length - 1
        ? widget.queue[currentIndex + 1]
        : null;
    final prevVideo = currentIndex > 0 ? widget.queue[currentIndex - 1] : null;

    final playerHeight = MediaQuery.of(context).size.width * 9 / 16;

    return SafeBackScope(
      fallbackLocation: '/teacher/video-library',
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    AnimatedPressable(
                      pressScale: 0.9,
                      onPress: () => context.canPop()
                          ? context.pop()
                          : context.go('/teacher/video-library'),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentVideo.title,
                          style: AppTypography.label.copyWith(
                            color: AppColors.white,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.folderName,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedPressable(
                    pressScale: 0.9,
                    onPress: () => setState(() => _showQueue = !_showQueue),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.list,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Video Player
            SizedBox(
              height: playerHeight,
              child: YoutubePlayer(controller: _controller),
            ),

            // Queue or Details View
            Expanded(
              child: _showQueue
                  ? _buildQueue()
                  : Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadius.xl),
                        ),
                      ),
                      child: _buildDetails(prevVideo, nextVideo),
                    ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildQueue() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.queue.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Queue · ${widget.queue.length} videos",
                  style: AppTypography.label.copyWith(
                    color: AppColors.white,
                    fontSize: 13,
                  ),
                ),
                AnimatedPressable(
                  pressScale: 0.9,
                  onPress: () => setState(() => _showQueue = false),
                  child: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final i = index - 1;
        final v = widget.queue[i];
        final isCurrent = v.id == _currentVideo.id;

        return AnimatedPressable(
          pressScale: 0.98,
          onPress: () => _goTo(v),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.coral.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: AppRadius.mdBorder,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    "${i + 1}",
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 64,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: AppRadius.smBorder,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: v.thumbnail.isNotEmpty
                      ? Image.network(
                          v.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.white10,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    v.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: isCurrent
                        ? AppTypography.label.copyWith(
                            color: const Color(0xFFE9938B),
                            fontSize: 12,
                          )
                        : AppTypography.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetails(
      TeacherVideoItem? prevVideo, TeacherVideoItem? nextVideo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Next / Prev Navigation Controls
          Row(
            children: [
              if (prevVideo != null)
                Expanded(
                  child: AnimatedPressable(
                    pressScale: 0.96,
                    onPress: () => _goTo(prevVideo),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.skipBack,
                            size: 14,
                            color: AppColors.ink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Previous",
                            style: AppTypography.label.copyWith(
                              fontSize: 12.5,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (prevVideo != null && nextVideo != null)
                const SizedBox(width: 10),
              if (nextVideo != null)
                Expanded(
                  child: AnimatedPressable(
                    pressScale: 0.96,
                    onPress: () => _goTo(nextVideo),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Next",
                            style: AppTypography.label.copyWith(
                              fontSize: 12.5,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            LucideIcons.skipForward,
                            size: 14,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            _currentVideo.title,
            style: AppTypography.h3.copyWith(
              fontSize: 17,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Text(
                _currentVideo.duration,
                style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "•",
                  style:
                      AppTypography.caption.copyWith(color: AppColors.inkFaint),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.eye,
                    size: 12,
                    color: AppColors.inkFaint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${_currentVideo.views} views",
                    style: AppTypography.caption
                        .copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "•",
                  style:
                      AppTypography.caption.copyWith(color: AppColors.inkFaint),
                ),
              ),
              Text(
                "${_currentVideo.uniqueViewers} unique",
                style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Open on YouTube Pill Button
          AnimatedPressable(
            pressScale: 0.96,
            onPress: () => launchUrl(
              Uri.parse(
                "https://www.youtube.com/watch?v=${_currentVideo.videoUrl}",
              ),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.coralTint,
                border: Border.all(
                  color: AppColors.coral.withValues(alpha: 0.3),
                ),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.play,
                    size: 13,
                    color: AppColors.coral,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    "Open on YouTube",
                    style: AppTypography.label.copyWith(
                      fontSize: 12.5,
                      color: AppColors.coral,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    LucideIcons.externalLink,
                    size: 11,
                    color: AppColors.coral,
                  ),
                ],
              ),
            ),
          ),

          if (_currentVideo.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              _currentVideo.description,
              style: AppTypography.body.copyWith(
                fontSize: 13.5,
                color: AppColors.inkMuted,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
