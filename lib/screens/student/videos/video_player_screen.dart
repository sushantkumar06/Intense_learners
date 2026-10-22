import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../models/video.dart';
import '../../../services/api_client.dart';
import '../../../theme/app_theme.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/ui.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final VideoItem video;
  final String folderName;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.folderName,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late final YoutubePlayerController _controller;
  bool _playing = false;
  int _secondsSinceSync = 0;
  bool _hasSeekedToResume = false;
  Timer? _timer;

  late bool _isBookmarked;
  late bool _isWatched;
  bool _savingBookmark = false;
  bool _savingCompleted = false;

  static const int _syncIntervalSeconds = 10;
  static const double _completionThreshold = 0.9;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.video.bookmarked;
    _isWatched = widget.video.watched;
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.videoUrl,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
    _controller.listen(_onPlayerStateChange);
  }

  @override
  void dispose() {
    _syncProgress(); // Sync on leaving the screen
    _timer?.cancel();
    _controller.close();
    super.dispose();
  }

  void _onPlayerStateChange(YoutubePlayerValue event) {
    if (!mounted) return;

    final playerState = event.playerState;
    final isPlaying = playerState == PlayerState.playing;

    if (isPlaying && !_playing) {
      setState(() => _playing = true);
      _startTimer();
    } else if (playerState == PlayerState.paused && _playing) {
      setState(() => _playing = false);
      _stopTimer();
      _syncProgress();
    } else if (playerState == PlayerState.ended) {
      setState(() => _playing = false);
      _stopTimer();
      _syncProgress(completedOverride: true);
    }

    // Seek to last position when ready
    if (playerState == PlayerState.playing &&
        !_hasSeekedToResume &&
        widget.video.lastPosition > 0) {
      _controller.seekTo(
        seconds: widget.video.lastPosition.toDouble(),
        allowSeekAhead: true,
      );
      _hasSeekedToResume = true;
    }
  }

  double _lastKnownPosition = 0;
  double _lastKnownDuration = 0;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _secondsSinceSync += 1;

      try {
        _lastKnownPosition = await _controller.currentTime;
        _lastKnownDuration = await _controller.duration;
      } catch (_) {}

      if (_secondsSinceSync >= _syncIntervalSeconds) {
        _syncProgress();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _syncProgress({bool completedOverride = false}) async {
    if (_secondsSinceSync <= 0 && !completedOverride) return;

    try {
      final currentTime = _lastKnownPosition;
      final duration = _lastKnownDuration;

      final pct = duration > 0 ? (currentTime / duration) * 100.0 : 0.0;
      final clampedPct = pct.clamp(0.0, 100.0);
      final completed =
          completedOverride || (clampedPct / 100.0 >= _completionThreshold);

      final dio = ref.read(dioProvider);
      await dio.post(
        "/api/student/video-progress",
        data: {
          "videoId": widget.video.id,
          "watchedPercentage": clampedPct,
          "watchedSeconds": _secondsSinceSync,
          "lastPosition": currentTime.toInt(),
          "completed": completed,
        },
      );
      _secondsSinceSync = 0;
    } catch (e) {
      debugPrint("Progress sync error: $e");
    }
  }

  Future<void> _toggleBookmark() async {
    if (_savingBookmark) return;
    final nextVal = !_isBookmarked;
    setState(() {
      _isBookmarked = nextVal;
      _savingBookmark = true;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/api/student/bookmarks',
        data: {
          'videoId': widget.video.id,
          'bookmarked': nextVal,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextVal
                  ? "Added to saved bookmarks"
                  : "Removed from saved bookmarks",
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBookmarked = !nextVal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update bookmark: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _savingBookmark = false);
    }
  }

  Future<void> _toggleCompleted() async {
    if (_savingCompleted) return;
    final nextVal = !_isWatched;
    setState(() {
      _isWatched = nextVal;
      _savingCompleted = true;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/api/student/video-progress',
        data: {
          'videoId': widget.video.id,
          'watchedPercentage': nextVal ? 100 : 0,
          'watchedSeconds': 0,
          'lastPosition': 0,
          'completed': nextVal,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextVal ? "Marked as completed" : "Marked as unwatched",
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWatched = !nextVal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _savingCompleted = false);
    }
  }

  Future<void> _openYouTube() async {
    final uri = Uri.parse("https://www.youtube.com/watch?v=${widget.video.videoUrl}");
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open YouTube link: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeBackScope(
      fallbackLocation: '/student/videos',
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.arrowLeft, size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.folderName,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Video Player
            YoutubePlayer(
              controller: _controller,
            ),

            // Video Details Sheet
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isWatched) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.mintTint,
                            borderRadius: AppRadius.pillBorder,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.playCircle, size: 12, color: AppColors.mint),
                              const SizedBox(width: 6),
                              Text(
                                "Watched",
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.mint,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      Text(
                        widget.video.title,
                        style: AppTypography.h3.copyWith(fontSize: 18, color: AppColors.ink),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      Row(
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.clock, size: 13, color: AppColors.inkFaint),
                              const SizedBox(width: 5),
                              Text(
                                widget.video.duration,
                                style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Row(
                            children: [
                              Icon(LucideIcons.eye, size: 13, color: AppColors.inkFaint),
                              const SizedBox(width: 5),
                              Text(
                                "${widget.video.views} views",
                                style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Quick Actions Bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            AnimatedPressable(
                              pressScale: 0.94,
                              onPress: _toggleBookmark,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isBookmarked ? AppColors.goldTint : AppColors.surfaceMuted,
                                  borderRadius: AppRadius.pillBorder,
                                  border: Border.all(
                                    color: _isBookmarked ? AppColors.gold : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                                      size: 14,
                                      color: _isBookmarked ? AppColors.gold : AppColors.inkMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isBookmarked ? "Bookmarked" : "Bookmark",
                                      style: AppTypography.caption.copyWith(
                                        color: _isBookmarked ? AppColors.gold : AppColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedPressable(
                              pressScale: 0.94,
                              onPress: _toggleCompleted,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isWatched ? AppColors.mintTint : AppColors.surfaceMuted,
                                  borderRadius: AppRadius.pillBorder,
                                  border: Border.all(
                                    color: _isWatched ? AppColors.mint : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isWatched ? LucideIcons.checkCheck : LucideIcons.check,
                                      size: 14,
                                      color: _isWatched ? AppColors.mint : AppColors.inkMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isWatched ? "Completed" : "Mark Done",
                                      style: AppTypography.caption.copyWith(
                                        color: _isWatched ? AppColors.mint : AppColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedPressable(
                              pressScale: 0.94,
                              onPress: _openYouTube,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.coralTint,
                                  borderRadius: AppRadius.pillBorder,
                                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.play,
                                      size: 13,
                                      color: AppColors.coral,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "YouTube",
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.coral,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (widget.video.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          widget.video.description,
                          style: AppTypography.body.copyWith(
                            fontSize: 14,
                            color: AppColors.inkMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
