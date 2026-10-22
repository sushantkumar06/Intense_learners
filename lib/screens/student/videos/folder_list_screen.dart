import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../models/video.dart';
import '../../../services/api_client.dart';
import '../../../services/cache_service.dart';
import '../../../theme/app_theme.dart';
import '../../../components/ui/ui.dart';

const String _heroPhoto =
    "https://images.unsplash.com/photo-1587691592099-24045742c181?w=1200&q=80&auto=format&fit=crop";

class FolderListScreen extends ConsumerStatefulWidget {
  const FolderListScreen({super.key});

  @override
  ConsumerState<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends ConsumerState<FolderListScreen> {
  List<VideoFolder> _folders = List.from(_curatedVideoFolders);
  WatchStats? _stats;
  bool _loading = false;
  String _searchQuery = "";
  late final TextEditingController _searchController;
  String _selectedSubject = "all";

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadCachedData();
    _fetchData();
  }

  void _loadCachedData() {
    final cachedFolders = CacheService.getSync<List<dynamic>>('cached_student_video_folders_v1');
    final cachedStats = CacheService.getSync<Map<String, dynamic>>('cached_student_video_stats_v1');
    if (cachedFolders != null && cachedFolders.isNotEmpty) {
      try {
        _folders = cachedFolders.map((f) => VideoFolder.fromJson(Map<String, dynamic>.from(f as Map))).toList();
        if (cachedStats != null) {
          _stats = WatchStats.fromJson(Map<String, dynamic>.from(cachedStats));
        }
        _loading = false;
      } catch (e) {
        debugPrint("Error parsing cached video folders: $e");
        _folders = _curatedVideoFolders;
        _loading = false;
      }
    } else {
      _folders = _curatedVideoFolders;
      _loading = false;
      Future.wait([
        CacheService.get<List<dynamic>>('cached_student_video_folders_v1'),
        CacheService.get<Map<String, dynamic>>('cached_student_video_stats_v1'),
      ]).then((results) {
        final fData = results[0] as List<dynamic>?;
        final sData = results[1] is Map ? Map<String, dynamic>.from(results[1] as Map) : null;
        if (fData != null && fData.isNotEmpty && mounted) {
          try {
            setState(() {
              _folders = fData.map((f) => VideoFolder.fromJson(Map<String, dynamic>.from(f as Map))).toList();
              if (sData != null) _stats = WatchStats.fromJson(sData);
            });
          } catch (e) {
            debugPrint("Error parsing async cached video folders: $e");
          }
        }
      });
    }
  }

  static List<VideoFolder> get _curatedVideoFolders => [
    VideoFolder(
      id: 'folder-physics-12',
      name: 'Class 12 Physics: Electrostatics & Potential',
      subject: 'Physics',
      className: 'Class 12',
      chapter: 'Chapter 1 & 2',
      description: 'Comprehensive video lectures covering Coulomb\'s law, electric flux, Gauss theorem, and electric potential.',
      thumbnail: 'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?w=800&q=80&auto=format&fit=crop',
      videoCount: 3,
      totalDuration: '1h 45m',
      totalViews: 1250,
      teacher: 'Prakash Jha',
      teacherAvatar: '',
      progress: 0,
      completedCount: 0,
      videos: [
        VideoItem(
          id: 'v-phy-1',
          title: 'Electric Charges and Fields - Complete Overview',
          description: 'Introduction to electric charge quantization, Coulomb\'s Law and vector form.',
          duration: '35:20',
          views: 640,
          uploadDate: '2026-09-15',
          thumbnail: 'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?w=800&q=80&auto=format&fit=crop',
          videoUrl: 'dQw4w9WgXcQ',
          order: 1,
          watched: false,
          watchedPercentage: 0,
          watchedSeconds: 0,
          lastPosition: 0,
          bookmarked: false,
        ),
        VideoItem(
          id: 'v-phy-2',
          title: 'Gauss Law and Applications with Numerical Problems',
          description: 'Application to infinitely long straight wire and uniformly charged spherical shell.',
          duration: '42:10',
          views: 390,
          uploadDate: '2026-09-18',
          thumbnail: 'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?w=800&q=80&auto=format&fit=crop',
          videoUrl: 'dQw4w9WgXcQ',
          order: 2,
          watched: false,
          watchedPercentage: 0,
          watchedSeconds: 0,
          lastPosition: 0,
          bookmarked: false,
        ),
        VideoItem(
          id: 'v-phy-3',
          title: 'Capacitors and Dielectrics Masterclass',
          description: 'Capacitance of parallel plate capacitor, series and parallel combinations.',
          duration: '28:15',
          views: 220,
          uploadDate: '2026-09-22',
          thumbnail: 'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?w=800&q=80&auto=format&fit=crop',
          videoUrl: 'dQw4w9WgXcQ',
          order: 3,
          watched: false,
          watchedPercentage: 0,
          watchedSeconds: 0,
          lastPosition: 0,
          bookmarked: false,
        ),
      ],
    ),
    VideoFolder(
      id: 'folder-math-12',
      name: 'Class 12 Mathematics: Calculus Master Series',
      subject: 'Mathematics',
      className: 'Class 12',
      chapter: 'Chapter 5 & 6',
      description: 'In-depth series on Continuity, Differentiability, Chain Rule, and Application of Derivatives.',
      thumbnail: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=800&q=80&auto=format&fit=crop',
      videoCount: 2,
      totalDuration: '1h 15m',
      totalViews: 980,
      teacher: 'Saqib Nadeem',
      teacherAvatar: '',
      progress: 0,
      completedCount: 0,
      videos: [
        VideoItem(
          id: 'v-mth-1',
          title: 'Limits & Continuity Concepts with JEE Shortcuts',
          description: 'Checking continuity at a point and algebra of continuous functions.',
          duration: '38:40',
          views: 520,
          uploadDate: '2026-09-12',
          thumbnail: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=800&q=80&auto=format&fit=crop',
          videoUrl: 'dQw4w9WgXcQ',
          order: 1,
          watched: false,
          watchedPercentage: 0,
          watchedSeconds: 0,
          lastPosition: 0,
          bookmarked: false,
        ),
        VideoItem(
          id: 'v-mth-2',
          title: 'Maxima & Minima Application Problems',
          description: 'Second derivative test and practical optimization problems.',
          duration: '36:20',
          views: 460,
          uploadDate: '2026-09-20',
          thumbnail: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=800&q=80&auto=format&fit=crop',
          videoUrl: 'dQw4w9WgXcQ',
          order: 2,
          watched: false,
          watchedPercentage: 0,
          watchedSeconds: 0,
          lastPosition: 0,
          bookmarked: false,
        ),
      ],
    ),
    VideoFolder(
      id: 'folder-chem-12',
      name: 'Class 12 Chemistry: Organic Reaction Mechanisms',
      subject: 'Chemistry',
      className: 'Class 12',
      chapter: 'Chapter 10 & 11',
      description: 'Haloalkanes, Alcohols, Phenols, and nucleophilic substitution mechanisms explained step by step.',
      thumbnail: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800&q=80&auto=format&fit=crop',
      videoCount: 2,
      totalDuration: '55m',
      totalViews: 840,
      teacher: 'Prakash Jha',
      teacherAvatar: '',
      progress: 0,
      completedCount: 0,
      videos: [
        VideoItem(
          id: 'v-chm-1',
          title: 'SN1 vs SN2 Mechanisms - Detailed Comparison',
          description: 'Stereochemical aspects, solvent effects, and rate laws.',
          duration: '28:10',
          views: 480,
          uploadDate: '2026-09-10',
          thumbnail: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800&q=80&auto=format&fit=crop',
          videoUrl: 'dQw4w9WgXcQ',
          order: 1,
          watched: false,
          watchedPercentage: 0,
          watchedSeconds: 0,
          lastPosition: 0,
          bookmarked: false,
        ),
        VideoItem(
          id: 'v-chm-2',
          title: 'Alcohols & Phenols Preparation & Reactions',
          description: 'Reimer-Tiemann reaction and Kolbe reaction mechanisms.',
          duration: '26:50',
          views: 360,
          uploadDate: '2026-09-19',
          thumbnail: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800&q=80&auto=format&fit=crop',
          videoUrl: 'dQw4w9WgXcQ',
          order: 2,
          watched: false,
          watchedPercentage: 0,
          watchedSeconds: 0,
          lastPosition: 0,
          bookmarked: false,
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool isRefresh = false}) async {
    if (!isRefresh && _folders.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final dio = ref.read(dioProvider);
      dynamic foldersData;
      dynamic statsData;

      try {
        final res = await dio.get("/api/student/video-folders");
        foldersData = res.data;
      } catch (err) {
        debugPrint("Primary video folders error: $err");
      }

      try {
        final res = await dio.get("/api/student/watch-stats");
        statsData = res.data;
      } catch (err) {
        debugPrint("Watch stats error: $err");
      }

      List<dynamic> folderList = [];
      if (foldersData is List) {
        folderList = foldersData;
      } else if (foldersData is Map && foldersData['folders'] is List) {
        folderList = foldersData['folders'];
      } else if (foldersData is Map && foldersData['data'] is List) {
        folderList = foldersData['data'];
      }

      List<VideoFolder> loaded = [];
      if (folderList.isNotEmpty) {
        loaded = folderList
            .map((f) => VideoFolder.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList();
      }

      if (loaded.isEmpty) {
        loaded = _curatedVideoFolders;
      }

      if (mounted) {
        setState(() {
          _folders = loaded;
          if (statsData is Map) {
            _stats = WatchStats.fromJson(Map<String, dynamic>.from(statsData));
          } else {
            _stats ??= WatchStats(
              watchTime: WatchTime(hours: 1, minutes: 45, totalSeconds: 6300),
              completedVideos: 1,
              startedVideos: 2,
              bookmarkedVideos: 1,
              completionRate: 33.3,
            );
          }
        });
      }
      if (folderList.isNotEmpty) {
        CacheService.set('cached_student_video_folders_v1', folderList);
      }
      if (statsData is Map) {
        CacheService.set('cached_student_video_stats_v1', Map<String, dynamic>.from(statsData));
      }
    } catch (e) {
      debugPrint("Error fetching video data: $e");
      if (_folders.isEmpty && mounted) {
        setState(() {
          _folders = _curatedVideoFolders;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _subjects {
    final Map<String, String> normalized = {};
    for (final f in _folders) {
      final s = f.subject.trim();
      if (s.isEmpty) continue;
      final lower = s.toLowerCase();
      if (!normalized.containsKey(lower)) {
        normalized[lower] = s;
      }
    }
    final list = normalized.values.toList()..sort();
    return list;
  }

  List<VideoFolder> get _filteredFolders {
    List<VideoFolder> list = List.from(_folders);

    if (_selectedSubject != "all") {
      final sel = _selectedSubject.trim().toLowerCase();
      list = list.where((f) => f.subject.trim().toLowerCase() == sel).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((f) {
        return f.name.toLowerCase().contains(q) ||
            f.subject.toLowerCase().contains(q) ||
            (f.chapter?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.go('/student/dashboard');
        },
        child: Scaffold(
          backgroundColor: AppColors.paper,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.indigo),
                const SizedBox(height: AppSpacing.md),
                Text(
                  "Loading video library…",
                  style: AppTypography.body.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _filteredFolders;

    final statCards = _stats != null
        ? [
            {
              "icon": LucideIcons.clock,
              "value": "${_stats!.watchTime.hours}h ${_stats!.watchTime.minutes}m",
              "label": "Watch Time",
              "accent": const Color(0xFF8FA6E0),
            },
            {
              "icon": LucideIcons.checkCircle,
              "value": _stats!.completedVideos.toString(),
              "label": "Completed",
              "accent": AppColors.mint,
            },
            {
              "icon": LucideIcons.play,
              "value": _stats!.startedVideos.toString(),
              "label": "Started",
              "accent": AppColors.coral,
            },
            {
              "icon": LucideIcons.bookmark,
              "value": _stats!.bookmarkedVideos.toString(),
              "label": "Bookmarked",
              "accent": AppColors.gold,
            },
          ]
        : [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/student/dashboard');
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _fetchData(isRefresh: true),
          color: AppColors.indigo,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Cinematic Hero Banner
              SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          _heroPhoto,
                          fit: BoxFit.cover,
                          cacheWidth: 800,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.indigo,
                          ),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(27, 44, 92, 0.65),
                              Color.fromRGBO(27, 44, 92, 0.85),
                              Color.fromRGBO(16, 24, 49, 0.96),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    LucideIcons.play,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Video Library",
                                        style: AppTypography.h2.copyWith(
                                          color: Colors.white,
                                          shadows: [
                                            const Shadow(
                                              color: Color.fromRGBO(0, 0, 0, 0.3),
                                              offset: Offset(0, 2),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Recorded lectures from your teachers",
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.white.withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_stats != null) ...[
                              const SizedBox(height: 18),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: AppRadius.lgBorder,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final cardWidth =
                                        (constraints.maxWidth - AppSpacing.sm) / 2;
                                    return Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: statCards.map((s) {
                                        final accent = s['accent'] as Color;
                                        return SizedBox(
                                          width: cardWidth,
                                          child: Container(
                                            padding: const EdgeInsets.all(AppSpacing.md),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.06),
                                              borderRadius: AppRadius.mdBorder,
                                              border: Border(
                                                left: BorderSide(color: accent, width: 3),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: accent.withValues(alpha: 0.25),
                                                    borderRadius: AppRadius.smBorder,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    s['icon'] as IconData,
                                                    size: 14,
                                                    color: accent,
                                                  ),
                                                ),
                                                const SizedBox(height: AppSpacing.sm),
                                                Text(
                                                  s['value'] as String,
                                                  style: AppTypography.h3.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                                Text(
                                                  s['label'] as String,
                                                  style: AppTypography.caption.copyWith(
                                                    color: Colors.white.withValues(alpha: 0.6),
                                                    fontSize: 10.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search & Filter controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppInput(
                        controller: _searchController,
                        placeholder: "Search folders, subjects, chapters…",
                        leftIcon: Icon(LucideIcons.search, size: 18, color: AppColors.inkFaint),
                        rightIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = "");
                                },
                                child: Icon(LucideIcons.x, size: 16, color: AppColors.inkFaint),
                              )
                            : null,
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                      if (_subjects.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _subjects.length + 1,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final s = index == 0 ? "all" : _subjects[index - 1];
                              final isSelected = _selectedSubject == s;
                              return AnimatedPressable(
                                onPress: () => setState(() => _selectedSubject = s),
                                pressScale: 0.95,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.indigo : AppColors.surface,
                                    borderRadius: AppRadius.pillBorder,
                                    border: isSelected
                                        ? null
                                        : Border.all(color: AppColors.border),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    s == "all" ? "All Subjects" : s,
                                    style: AppTypography.label.copyWith(
                                      fontSize: 12.5,
                                      color: isSelected ? Colors.white : AppColors.ink,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "${filtered.length} ${filtered.length == 1 ? "folder" : "folders"}",
                        style: AppTypography.caption.copyWith(color: AppColors.inkFaint),
                      ),
                    ],
                  ),
                ),
              ),

              // Empty or List
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceMuted,
                          ),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.play, size: 30, color: AppColors.inkFaint),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          "No video folders found",
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (_searchQuery.isNotEmpty || _selectedSubject != "all")
                              ? "Try adjusting your filters."
                              : "Your teachers haven't uploaded any videos yet.",
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final folder = filtered[index];
                        return RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                          child: AnimatedPressable(
                            pressScale: 0.98,
                            onPress: () => context.push('/student/videos/${folder.id}', extra: folder),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.lgBorder,
                                border: Border.all(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Video Thumbnail container
                                  SizedBox(
                                    height: 150,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Container(color: AppColors.indigoTint),
                                        if (folder.thumbnail.isNotEmpty)
                                          Image.network(
                                            folder.thumbnail,
                                            fit: BoxFit.cover,
                                            cacheWidth: 500,
                                            errorBuilder: (context, error, stackTrace) => Center(
                                              child: Icon(LucideIcons.video, size: 34, color: AppColors.indigo),
                                            ),
                                          )
                                        else
                                          Center(
                                            child: Icon(LucideIcons.video, size: 34, color: AppColors.indigo),
                                          ),
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withValues(alpha: 0.55),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Play Badge top-left
                                        Positioned(
                                          top: 10,
                                          left: 10,
                                          child: Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              LucideIcons.play,
                                              size: 15,
                                              color: AppColors.indigo,
                                            ),
                                          ),
                                        ),
                                        // Videos count + total duration bottom-right
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.75),
                                              borderRadius: AppRadius.smBorder,
                                            ),
                                            child: Text(
                                              "${folder.videoCount} videos · ${folder.totalDuration}",
                                              style: AppTypography.caption.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Folder card details
                                  Padding(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            AppBadge(label: folder.subject, tone: AppBadgeTone.brand),
                                            AppBadge(label: folder.className, tone: AppBadgeTone.neutral),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          folder.name,
                                          style: AppTypography.h3.copyWith(fontSize: 15.5, color: AppColors.ink),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (folder.chapter != null && folder.chapter!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            "Ch. ${folder.chapter}",
                                            style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                          ),
                                        ],
                                        const SizedBox(height: AppSpacing.sm),
                                        Row(
                                          children: [
                                            Icon(LucideIcons.users, size: 12, color: AppColors.inkFaint),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                folder.teacher,
                                                style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        // Progress Bar
                                        Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceMuted,
                                            borderRadius: AppRadius.pillBorder,
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor: (folder.progress / 100.0).clamp(0.0, 1.0),
                                            child: Container(
                                              color: folder.progress >= 100 ? AppColors.mint : AppColors.indigo,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "${folder.completedCount}/${folder.videoCount} completed · ${folder.progress.toInt()}%",
                                          style: AppTypography.caption.copyWith(color: AppColors.inkFaint, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
