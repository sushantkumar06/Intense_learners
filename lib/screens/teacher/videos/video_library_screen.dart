import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../models/teacher_video.dart';
import '../../../services/api_client.dart';
import '../../../services/cache_service.dart';
import '../../../theme/app_theme.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/app_badge.dart';
import '../../../components/ui/animated_pressable.dart';
import '../../../components/ui/progress_ring.dart';
import '../../../components/ui/stat_primitives.dart';
import '../../../components/teacher/folder_form_modal.dart';

const String _kHeroPhoto =
    "https://images.unsplash.com/photo-1637065463674-4595b7f32adc?w=1200&q=80&auto=format&fit=crop";

enum _VideoTab { library, youtube }

class VideoLibraryScreen extends ConsumerStatefulWidget {
  const VideoLibraryScreen({super.key});

  @override
  ConsumerState<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

final List<TeacherVideoFolder> _curatedVideoFolders = [
  TeacherVideoFolder(
    id: "folder-curated-1",
    name: "Political Science - Class 12 Masterclasses",
    subject: "Political Science",
    className: "Class 12",
    chapter: "Contemporary World Politics",
    description:
        "Complete chapter-wise lecture recordings covering Cold War era and international organizations.",
    thumbnail:
        "https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=600&q=80",
    isPublic: true,
    videoCount: 2,
    totalDuration: "1h 35m",
    totalViews: 340,
    totalWatchTime: "180h 20m",
    createdAt:
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
    videos: [
      TeacherVideoItem(
        id: "vid-curated-1",
        title: "Introduction to International Organizations",
        description:
            "Overview of League of Nations and establishment of the UN.",
        duration: "45:20",
        views: 120,
        uniqueViewers: 85,
        totalWatchTime: "62h 10m",
        uploadDate:
            DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
        thumbnail:
            "https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=600&q=80",
        videoUrl: "dQw4w9WgXcQ",
        size: "245 MB",
        quality: "1080p",
      ),
      TeacherVideoItem(
        id: "vid-curated-2",
        title: "Security Council & Power Dynamics",
        description:
            "Veto power, reform debates, and developing nations representation.",
        duration: "50:15",
        views: 220,
        uniqueViewers: 130,
        totalWatchTime: "118h 10m",
        uploadDate:
            DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
        thumbnail:
            "https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=600&q=80",
        videoUrl: "dQw4w9WgXcQ",
        size: "280 MB",
        quality: "1080p",
      ),
    ],
  ),
  TeacherVideoFolder(
    id: "folder-curated-2",
    name: "History - Themes in Indian History Part I",
    subject: "History",
    className: "Class 12th",
    chapter: "Bricks, Beads and Bones",
    description:
        "In-depth visual analysis of Harappan civilization archaeological discoveries.",
    thumbnail:
        "https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=600&q=80",
    isPublic: true,
    videoCount: 1,
    totalDuration: "42:15",
    totalViews: 210,
    totalWatchTime: "95h 40m",
    createdAt:
        DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
    videos: [
      TeacherVideoItem(
        id: "vid-curated-3",
        title: "Town Planning of Mohenjo-Daro",
        description:
            "Citadel, lower town, drainage system and architectural highlights.",
        duration: "42:15",
        views: 210,
        uniqueViewers: 140,
        totalWatchTime: "95h 40m",
        uploadDate:
            DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
        thumbnail:
            "https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=600&q=80",
        videoUrl: "dQw4w9WgXcQ",
        size: "210 MB",
        quality: "1080p",
      ),
    ],
  ),
];

class _VideoLibraryScreenState extends ConsumerState<VideoLibraryScreen> {
  _VideoTab _tab = _VideoTab.library;
  List<TeacherVideoFolder> _folders = List.from(_curatedVideoFolders);
  bool _loading = false;
  String _searchQuery = "";

  YouTubeSyncStatus? _syncStatus;
  bool _syncLoading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _fetchFolders();
    _fetchSyncStatus();
  }

  void _loadCachedData() {
    final cachedFolders =
        CacheService.getSync("cached_teacher_video_folders_v1");
    if (cachedFolders is List && cachedFolders.isNotEmpty) {
      final valid = cachedFolders
          .whereType<Map>()
          .map((x) => TeacherVideoFolder.fromJson(x))
          .toList();
      if (valid.isNotEmpty) {
        _folders = valid;
        _loading = false;
      }
    }
    final cachedSync = CacheService.getSync("cached_teacher_youtube_sync_v1");
    if (cachedSync is Map) {
      _syncStatus = YouTubeSyncStatus.fromJson(cachedSync);
      _syncLoading = false;
    }
  }

  Future<void> _fetchFolders([bool isRefresh = false]) async {
    if (!isRefresh && _folders.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final response =
          await ref.read(dioProvider).get("/api/teacher/video-folders");
      if (response.data is List) {
        final list = (response.data as List).whereType<Map>().toList();
        if (list.isNotEmpty) {
          CacheService.set("cached_teacher_video_folders_v1", list);
          if (mounted) {
            setState(() {
              _folders = list
                  .map((x) => TeacherVideoFolder.fromJson(x))
                  .toList();
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Teacher video folders error, trying fallback: $e");
    }

    // Fallback: If teacher endpoint had no folders, fetch public/student video folders
    try {
      final studentResponse =
          await ref.read(dioProvider).get("/api/student/video-folders");
      if (studentResponse.data is List) {
        final list = (studentResponse.data as List).whereType<Map>().toList();
        if (list.isNotEmpty) {
          CacheService.set("cached_teacher_video_folders_v1", list);
          if (mounted) {
            setState(() {
              _folders = list
                  .map((x) => TeacherVideoFolder.fromJson(x))
                  .toList();
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Student video folders fallback error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchSyncStatus() async {
    if (_syncStatus == null) {
      setState(() => _syncLoading = true);
    }
    try {
      final response =
          await ref.read(dioProvider).get("/api/teacher/youtube-channel-sync");
      if (response.data is Map) {
        CacheService.set("cached_teacher_youtube_sync_v1", response.data);
        if (mounted) {
          setState(() =>
              _syncStatus = YouTubeSyncStatus.fromJson(response.data as Map));
        }
      }
    } catch (e) {
      debugPrint("Error fetching sync status: $e");
    } finally {
      if (mounted) setState(() => _syncLoading = false);
    }
  }

  Future<void> _handleSync() async {
    setState(() => _syncing = true);
    try {
      final response = await ref
          .read(dioProvider)
          .post("/api/teacher/youtube-channel-sync", data: {});
      final data = response.data;
      if (data['error'] != null) {
        if (mounted) _showAlert("Sync failed", data['error']);
      } else {
        if (mounted) {
          _showAlert(
            "Sync complete",
            "${data['created']} new, ${data['updated']} updated, ${data['removed']} removed out of ${data['total']} videos.",
          );
        }
        _fetchFolders(true);
        _fetchSyncStatus();
      }
    } catch (e) {
      if (mounted) _showAlert("Sync failed", "Something went wrong");
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          title,
          style: AppTypography.h3.copyWith(color: AppColors.ink),
        ),
        content: Text(
          message,
          style: AppTypography.body.copyWith(color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "OK",
              style: AppTypography.label.copyWith(color: AppColors.indigo),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Delete folder?",
          style: AppTypography.h3.copyWith(color: AppColors.ink),
        ),
        content: Text(
          "All videos inside will be deleted too.",
          style: AppTypography.body.copyWith(color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: AppTypography.label.copyWith(color: AppColors.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _folders.removeWhere((f) => f.id == id);
              });
              try {
                await ref
                    .read(dioProvider)
                    .delete("/api/teacher/video-folders/$id");
              } catch (e) {
                _fetchFolders();
              }
            },
            child: Text(
              "Delete",
              style: AppTypography.label.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateModal([TeacherVideoFolder? folder]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => FolderFormModal(
        folder: folder,
        onSuccess: () => _fetchFolders(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _folders.isEmpty) {
      return SafeBackScope(
        fallbackLocation: '/teacher',
        child: Scaffold(
          backgroundColor: AppColors.paper,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.indigo),
          ),
        ),
      );
    }

    final filteredFolders = _folders.where((f) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return f.name.toLowerCase().contains(q) ||
          f.subject.toLowerCase().contains(q) ||
          f.chapter.toLowerCase().contains(q);
    }).toList();

    final totalVideos =
        _folders.fold<int>(0, (s, f) => s + f.videoCount);
    final totalViews =
        _folders.fold<int>(0, (s, f) => s + f.totalViews);
    final youtubeCount =
        _folders.where((f) => f.youtubePlaylistId != null).length;
    final publicCount = _folders.where((f) => f.isPublic).length;
    final publicRatio = _folders.isNotEmpty
        ? (publicCount / _folders.length).clamp(0.0, 1.0)
        : 0.0;

    return SafeBackScope(
      fallbackLocation: '/teacher',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          top: false,
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.indigo,
              onRefresh: () async {
                await _fetchFolders(true);
                await _fetchSyncStatus();
              },
              child: CustomScrollView(
                slivers: [
                  // Hero Header
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      totalVideos: totalVideos,
                      youtubeCount: youtubeCount,
                      totalViews: totalViews,
                      publicRatio: publicRatio,
                    ),
                  ),

                  // Body Tab View
                  if (_tab == _VideoTab.youtube)
                    SliverToBoxAdapter(child: _buildYouTubeSyncTab())
                  else if (filteredFolders.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 64,
                          horizontal: 20,
                        ),
                        child: Column(
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
                                LucideIcons.folder,
                                size: 32,
                                color: AppColors.coral,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              "No folders yet",
                              style: AppTypography.label.copyWith(
                                color: AppColors.ink,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Sync your YouTube channel or create a folder manually",
                              style: AppTypography.body.copyWith(
                                color: AppColors.inkMuted,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        top: 8,
                        bottom: 100,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final folder = filteredFolders[index];
                            return _FolderCard(
                              folder: folder,
                              onTap: () => context.push(
                                '/teacher/video-library/${folder.id}',
                                extra: folder,
                              ),
                              onEdit: () => _showCreateModal(folder),
                              onDelete: () => _handleDelete(folder.id),
                            );
                          },
                          childCount: filteredFolders.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Floating Create Folder Button (Coral FAB)
            if (_tab == _VideoTab.library)
              Positioned(
                bottom: 24,
                right: 20,
                child: AnimatedPressable(
                  pressScale: 0.9,
                  onPress: () => _showCreateModal(),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.coral.withValues(alpha: 0.5),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.folderPlus,
                      size: 24,
                      color: AppColors.white,
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

  Widget _buildHeader({
    required int totalVideos,
    required int youtubeCount,
    required int totalViews,
    required double publicRatio,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cinematic Photo Hero
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  _kHeroPhoto,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.indigoDark,
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x990F2027),
                      Color(0xCC203A43),
                      Color(0xF20F2027),
                    ],
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 50,
                  left: 20,
                  right: 20,
                  bottom: 26,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedPressable(
                          pressScale: 0.9,
                          onPress: () => context.canPop()
                              ? context.pop()
                              : context.go('/teacher'),
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: AppRadius.smBorder,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.arrowLeft,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: AppRadius.pillBorder,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.sparkles,
                                      size: 11,
                                      color: AppColors.gold,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Video Library",
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Lecture Vault",
                                style: AppTypography.h1.copyWith(
                                  color: AppColors.white,
                                  fontSize: 28,
                                  height: 1.15,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.35),
                                      offset: const Offset(0, 2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "${_folders.length} folders · $totalVideos videos",
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedPressable(
                          pressScale: 0.9,
                          onPress: () {
                            _fetchFolders(true);
                            _fetchSyncStatus();
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: AppRadius.smBorder,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.refreshCw,
                              size: 15,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Glass panel: Public ratio + video counters
                    ClipRRect(
                      borderRadius: AppRadius.lgBorder,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              ProgressRing(
                                progress: publicRatio,
                                label: "PUBLIC",
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "LIBRARY OVERVIEW",
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.65),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10.5,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 8,
                                      children: [
                                        MiniStat(
                                          icon: const Icon(
                                            LucideIcons.video,
                                            size: 12,
                                            color: Colors.white70,
                                          ),
                                          value: totalVideos,
                                          label: "videos",
                                        ),
                                        MiniStat(
                                          icon: const Icon(
                                            LucideIcons.play,
                                            size: 12,
                                            color: Colors.white70,
                                          ),
                                          value: youtubeCount,
                                          label: "synced",
                                        ),
                                        MiniStat(
                                          icon: const Icon(
                                            LucideIcons.eye,
                                            size: 12,
                                            color: Colors.white70,
                                          ),
                                          value: totalViews,
                                          label: "views",
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tabs & Search
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      _VideoTab.library,
                      LucideIcons.folder,
                      "Video Library",
                    ),
                    _buildTabButton(
                      _VideoTab.youtube,
                      LucideIcons.play,
                      "YouTube Sync",
                    ),
                  ],
                ),
              ),
              if (_tab == _VideoTab.library) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0x1FFFFFFF),
                        Color(0x0DFFFFFF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0x33FFFFFF),
                      width: 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.search,
                        size: 16,
                        color: AppColors.inkFaint,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          cursorColor: const Color(0xFF2EE6C5),
                          style: AppTypography.body.copyWith(
                            color: AppColors.ink,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search folders, subjects…",
                            hintStyle: AppTypography.body.copyWith(
                              color: AppColors.inkFaint,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(_VideoTab tab, IconData icon, String label) {
    final active = _tab == tab;
    return Expanded(
      child: AnimatedPressable(
        pressScale: 0.97,
        onPress: () => setState(() => _tab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.indigo : Colors.transparent,
            borderRadius: AppRadius.smBorder,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: active ? AppColors.white : AppColors.inkMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: active ? AppColors.white : AppColors.inkMuted,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubeSyncTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: _syncLoading
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(color: AppColors.indigo),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.lgBorder,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (_syncStatus?.channelThumbnail != null &&
                              _syncStatus!.channelThumbnail.isNotEmpty)
                            ClipOval(
                              child: Image.network(
                                _syncStatus!.channelThumbnail,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.coralTint,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                LucideIcons.play,
                                size: 22,
                                color: AppColors.coral,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _syncStatus?.channelTitle ?? "Your Channel",
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.ink,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${_syncStatus?.subscriberCount ?? '0'} subscribers · ${_syncStatus?.videoCount ?? 0} videos",
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.inkMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedPressable(
                        pressScale: 0.96,
                        onPress: _syncing ? null : _handleSync,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.indigo,
                            borderRadius: AppRadius.mdBorder,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_syncing)
                                const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  LucideIcons.refreshCw,
                                  size: 15,
                                  color: AppColors.white,
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _syncing ? "Syncing…" : "Sync Now",
                                style: AppTypography.label.copyWith(
                                  color: AppColors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_syncStatus?.folder != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Builder(
                    builder: (context) {
                      final folderData = _syncStatus!.folder!;
                      final folderId = folderData['id'] as String? ?? '';
                      final folderName = folderData['name'] as String? ?? 'Synced Videos';
                      final folderVideoCount = folderData['videoCount'] ?? 0;
                      final rawVideos = folderData['videos'] as List? ?? [];

                      return AnimatedPressable(
                        pressScale: 0.98,
                        onPress: () {
                          final f = _folders.firstWhere(
                            (x) => x.id == folderId,
                            orElse: () => TeacherVideoFolder.fromJson(folderData),
                          );
                          context.push('/teacher/video-library/${f.id}', extra: f);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                folderName,
                                style: AppTypography.label.copyWith(
                                  color: AppColors.ink,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$folderVideoCount videos synced",
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.inkMuted,
                                  fontSize: 12,
                                ),
                              ),
                              if (rawVideos.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: rawVideos
                                      .take(3)
                                      .map((v) {
                                        final thumb = (v is Map ? v['thumbnail'] : null) as String? ?? '';
                                        return Expanded(
                                          child: Container(
                                            height: 64,
                                            margin: const EdgeInsets.only(right: 8),
                                            child: ClipRRect(
                                              borderRadius: AppRadius.smBorder,
                                              child: thumb.isNotEmpty
                                                  ? Image.network(
                                                      thumb,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, _, _) => Container(
                                                        color: AppColors.coralTint,
                                                      ),
                                                    )
                                                  : Container(color: AppColors.coralTint),
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final TeacherVideoFolder folder;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FolderCard({
    required this.folder,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      child: AnimatedPressable(
        pressScale: 0.98,
        onPress: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Thumbnail
              SizedBox(
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (folder.thumbnail.isNotEmpty)
                      Image.network(
                        folder.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.coralTint,
                          alignment: Alignment.center,
                          child: Icon(
                            LucideIcons.folder,
                            size: 38,
                            color: AppColors.coral,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.coralTint,
                        alignment: Alignment.center,
                        child: Icon(
                          folder.youtubePlaylistId != null
                              ? LucideIcons.play
                              : LucideIcons.folder,
                          size: 38,
                          color: AppColors.coral,
                        ),
                      ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x8C000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppBadge(
                            label: folder.subject,
                            tone: AppBadgeTone.danger,
                          ),
                          Row(
                            children: [
                              if (folder.youtubePlaylistId != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xE6C1443A),
                                    borderRadius: AppRadius.pillBorder,
                                  ),
                                  child: Row(
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
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: AppRadius.pillBorder,
                                ),
                                child: Text(
                                  "${folder.videoCount} videos",
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card Body
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: AppTypography.label.copyWith(
                        color: AppColors.ink,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        AppBadge(
                          label: folder.className,
                          tone: AppBadgeTone.brand,
                        ),
                        AppBadge(
                          label: folder.isPublic ? "Public" : "Private",
                          tone: folder.isPublic
                              ? AppBadgeTone.success
                              : AppBadgeTone.gold,
                        ),
                      ],
                    ),
                    if (folder.chapter.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        folder.chapter,
                        style: AppTypography.body.copyWith(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),

                    // Stats Grid
                    Row(
                      children: [
                        _buildStatBox("Videos", "${folder.videoCount}"),
                        const SizedBox(width: 6),
                        _buildStatBox(
                          "Duration",
                          folder.totalDuration.isNotEmpty
                              ? folder.totalDuration
                              : "--",
                        ),
                        const SizedBox(width: 6),
                        _buildStatBox("Views", "${folder.totalViews}"),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedPressable(
                            pressScale: 0.96,
                            onPress: onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: AppColors.indigo,
                                borderRadius: AppRadius.smBorder,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.play,
                                    size: 13,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    "View Videos",
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedPressable(
                          pressScale: 0.9,
                          onPress: onEdit,
                          child: Container(
                            width: 40,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: AppRadius.smBorder,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.pencil,
                              size: 14,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedPressable(
                          pressScale: 0.9,
                          onPress: onDelete,
                          child: Container(
                            width: 40,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.coralTint,
                              borderRadius: AppRadius.smBorder,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.trash2,
                              size: 14,
                              color: AppColors.coral,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: AppRadius.smBorder,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkFaint,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: AppTypography.label.copyWith(
                color: AppColors.ink,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
