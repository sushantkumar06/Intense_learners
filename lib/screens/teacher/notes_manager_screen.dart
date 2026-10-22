import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/teacher_note.dart';
import '../../services/api_client.dart';
import '../../services/cache_service.dart';
import '../../theme/app_theme.dart';
import '../../components/safe_back_scope.dart';
import '../../components/ui/app_card.dart';
import '../../components/ui/app_badge.dart';
import '../../components/ui/app_input.dart';
import '../../components/ui/animated_pressable.dart';
import '../../components/ui/progress_ring.dart';
import '../../components/ui/stat_primitives.dart';
import '../../components/ui/skeleton_loader.dart';
import '../../components/teacher/note_form_modal.dart';

const String _kHeroPhoto =
    "https://images.unsplash.com/photo-1727812100173-b33044cd3071?w=1200&q=80&auto=format&fit=crop";

enum _PublishFilter { all, published, draft }

class NotesManagerScreen extends ConsumerStatefulWidget {
  const NotesManagerScreen({super.key});

  @override
  ConsumerState<NotesManagerScreen> createState() => _NotesManagerScreenState();
}

class _NotesManagerScreenState extends ConsumerState<NotesManagerScreen> {
  static final List<TeacherNote> _curatedTeacherNotes = [
    TeacherNote(
      id: "21f80a2a-c0a5-4659-b648-ffcdc97c54e2",
      title: "Chapter 4 International organization",
      subject: "Political Science",
      className: "Class 12",
      topic: "English medium",
      chapter: "Chapter 4",
      fileUrl: "",
      fileName: "CH-6 INTERNET ORGANISATION ENG MED.pdf",
      fileType: "pdf",
      fileSize: "2.17 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7EhAsqHPOtDkgNljhrbIMy92iSXWpA3TLadFR",
      isPublished: true,
      isPinned: true,
      price: 0,
      downloads: 6,
      views: 40,
      createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      stats: TeacherNoteStats(totalBookmarks: 3),
    ),
    TeacherNote(
      id: "843cda30-9b1f-44a6-9937-6fa43e6663f9",
      title: "Chapter 4 अन्तर्राष्ट्रीय संगठन (Hindi Medium)",
      subject: "Political Science",
      className: "Class 12",
      topic: "Hindi medium",
      chapter: "Chapter 4",
      fileUrl: "",
      fileName: "ch 6 class 12th hindi med..pdf",
      fileType: "pdf",
      fileSize: "1.91 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7IqhvJWk6bdnqms4WvA7fZM9awlyk1eg2K3NO",
      isPublished: true,
      isPinned: false,
      price: 0,
      downloads: 2,
      views: 26,
      createdAt: DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
      stats: TeacherNoteStats(totalBookmarks: 1),
    ),
    TeacherNote(
      id: "0c9ff82a-6a38-4841-979f-0469c73d287c",
      title: "Chapter 3 Kingship, Caste & Class (राजशाही, जाति और वर्ग)",
      subject: "History",
      className: "Class 12th",
      topic: "Hindi and English medium",
      chapter: "Chapter 3",
      fileUrl: "",
      fileName: "HISTORY CHAPTER 3 CLASS 12TH .pdf",
      fileType: "pdf",
      fileSize: "4.46 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7rZiD7ukGD1zV2uxwQZvENAY4bdXgaP69OtRT",
      isPublished: true,
      isPinned: false,
      price: 0,
      downloads: 4,
      views: 70,
      createdAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      stats: TeacherNoteStats(totalBookmarks: 2),
    ),
  ];

  List<TeacherNote> _allNotes = List.from(_curatedTeacherNotes);
  bool _loading = false;

  String _searchQuery = "";
  String _selectedSubject = "all";
  _PublishFilter _publishFilter = _PublishFilter.all;

  @override
  void initState() {
    super.initState();
    _loadCachedNotes();
    _fetchNotes();
  }

  void _loadCachedNotes() {
    final cached = CacheService.getSync<List<dynamic>>('cached_teacher_notes_v1');
    if (cached != null && cached.isNotEmpty) {
      final valid = cached
          .whereType<Map>()
          .map((n) => TeacherNote.fromJson(Map<String, dynamic>.from(n)))
          .toList();
      if (valid.isNotEmpty) {
        _allNotes = valid;
        _loading = false;
      }
    } else {
      CacheService.get<List<dynamic>>('cached_teacher_notes_v1').then((data) {
        if (data != null && data.isNotEmpty && mounted && _allNotes.isEmpty) {
          final valid = data
              .whereType<Map>()
              .map((n) => TeacherNote.fromJson(Map<String, dynamic>.from(n)))
              .toList();
          if (valid.isNotEmpty) {
            setState(() {
              _allNotes = valid;
              _loading = false;
            });
          }
        }
      });
    }
  }

  Future<void> _fetchNotes([bool isRefresh = false]) async {
    if (!isRefresh && _allNotes.isEmpty) {
      setState(() => _loading = true);
    }

    try {
      final response = await ref.read(dioProvider).get("/api/teacher/notes");
      final data = response.data;
      if (data is Map && data['success'] == true && data['notes'] is List) {
        final rawNotes = (data['notes'] as List).whereType<Map>().toList();
        if (rawNotes.isNotEmpty) {
          if (mounted) {
            setState(() {
              _allNotes = rawNotes
                  .map((n) => TeacherNote.fromJson(Map<String, dynamic>.from(n)))
                  .toList();
            });
          }
          CacheService.set('cached_teacher_notes_v1', rawNotes);
          return;
        }
      }
    } catch (e) {
      debugPrint("Teacher notes endpoint error, trying student notes fallback: $e");
    }

    // Fallback: If teacher endpoint had no notes or failed, fetch public notes
    try {
      final studentResponse = await ref.read(dioProvider).get("/api/student/notes");
      final studentData = studentResponse.data;
      List rawStudentNotes = [];
      if (studentData is List) {
        rawStudentNotes = studentData;
      } else if (studentData is Map && studentData['notes'] is List) {
        rawStudentNotes = studentData['notes'] as List;
      }
      final valid = rawStudentNotes.whereType<Map>().toList();
      if (valid.isNotEmpty) {
        if (mounted) {
          setState(() {
            _allNotes = valid
                .map((n) => TeacherNote.fromJson(Map<String, dynamic>.from(n)))
                .toList();
          });
        }
        CacheService.set('cached_teacher_notes_v1', valid);
        return;
      }
    } catch (e) {
      debugPrint("Student notes fallback error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NoteFormModal(mode: "create"),
    ).then((newNote) {
      if (newNote != null && newNote is TeacherNote) {
        setState(() {
          _allNotes = [newNote, ..._allNotes];
        });
      }
    });
  }

  void _showEditModal(TeacherNote note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteFormModal(mode: "edit", note: note),
    ).then((updatedNote) {
      if (updatedNote != null && updatedNote is TeacherNote) {
        setState(() {
          _allNotes = _allNotes
              .map((n) => n.id == updatedNote.id ? updatedNote : n)
              .toList();
        });
      }
    });
  }

  Future<void> _handleDelete(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Delete note?",
          style: AppTypography.h3.copyWith(color: AppColors.ink),
        ),
        content: Text(
          "This can't be undone.",
          style: AppTypography.body.copyWith(color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancel",
              style: AppTypography.label.copyWith(color: AppColors.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Delete",
              style: AppTypography.label.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _allNotes = _allNotes.where((n) => n.id != id).toList());
    try {
      final response =
          await ref.read(dioProvider).delete("/api/teacher/notes?id=$id");
      if (response.data['success'] != true) _fetchNotes();
    } catch (e) {
      _fetchNotes();
    }
  }

  Future<void> _handleTogglePublish(String id) async {
    setState(() {
      _allNotes = _allNotes.map((n) {
        if (n.id == id) {
          return TeacherNote(
            id: n.id,
            title: n.title,
            description: n.description,
            subject: n.subject,
            className: n.className,
            topic: n.topic,
            chapter: n.chapter,
            fileUrl: n.fileUrl,
            fileName: n.fileName,
            fileType: n.fileType,
            fileSize: n.fileSize,
            thumbnailUrl: n.thumbnailUrl,
            isPublished: !n.isPublished,
            isPinned: n.isPinned,
            price: n.price,
            downloads: n.downloads,
            views: n.views,
            createdAt: n.createdAt,
            stats: n.stats,
          );
        }
        return n;
      }).toList();
    });
    try {
      final response = await ref.read(dioProvider).patch(
        "/api/teacher/notes",
        data: {"noteId": id, "action": "toggle-publish"},
      );
      if (response.data['success'] != true) _fetchNotes();
    } catch (e) {
      _fetchNotes();
    }
  }

  Future<void> _handleTogglePin(String id) async {
    setState(() {
      _allNotes = _allNotes.map((n) {
        if (n.id == id) {
          return TeacherNote(
            id: n.id,
            title: n.title,
            description: n.description,
            subject: n.subject,
            className: n.className,
            topic: n.topic,
            chapter: n.chapter,
            fileUrl: n.fileUrl,
            fileName: n.fileName,
            fileType: n.fileType,
            fileSize: n.fileSize,
            thumbnailUrl: n.thumbnailUrl,
            isPublished: n.isPublished,
            isPinned: !n.isPinned,
            price: n.price,
            downloads: n.downloads,
            views: n.views,
            createdAt: n.createdAt,
            stats: n.stats,
          );
        }
        return n;
      }).toList();
    });
    try {
      final response = await ref.read(dioProvider).patch(
        "/api/teacher/notes",
        data: {"noteId": id, "action": "toggle-pin"},
      );
      if (response.data['success'] != true) _fetchNotes();
    } catch (e) {
      _fetchNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Subject categories
    final subjects =
        _allNotes.map((n) => n.subject).toSet().toList()..sort();

    // Filter notes
    final filteredNotes = _allNotes.where((n) {
      if (_publishFilter == _PublishFilter.published && !n.isPublished) {
        return false;
      }
      if (_publishFilter == _PublishFilter.draft && n.isPublished) {
        return false;
      }
      if (_selectedSubject != "all" && n.subject != _selectedSubject) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = n.title.toLowerCase().contains(q) ||
            (n.description?.toLowerCase().contains(q) ?? false) ||
            n.subject.toLowerCase().contains(q) ||
            (n.topic?.toLowerCase().contains(q) ?? false);
        if (!matches) return false;
      }
      return true;
    }).toList();

    // Aggregate statistics
    final totalDownloads =
        _allNotes.fold<int>(0, (s, n) => s + n.downloads);
    final totalViews = _allNotes.fold<int>(0, (s, n) => s + n.views);
    final totalBookmarks =
        _allNotes.fold<int>(0, (s, n) => s + n.stats.totalBookmarks);
    final publishedCount = _allNotes.where((n) => n.isPublished).length;
    final draftCount = _allNotes.length - publishedCount;
    final publishRatio = _allNotes.isNotEmpty
        ? (publishedCount / _allNotes.length).clamp(0.0, 1.0)
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
              onRefresh: () => _fetchNotes(true),
              child: CustomScrollView(
                slivers: [
                  // Hero & Filter Header
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      totalNotes: _allNotes.length,
                      publishedCount: publishedCount,
                      draftCount: draftCount,
                      publishRatio: publishRatio,
                      totalDownloads: totalDownloads,
                      totalViews: totalViews,
                      totalBookmarks: totalBookmarks,
                      subjects: subjects,
                    ),
                  ),

                  // Notes List or Skeletons or Empty
                  if (_loading && _allNotes.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AppCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  const SkeletonLoader(
                                    height: 128,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.lg),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        SkeletonLoader(
                                          width: 180,
                                          height: 16,
                                        ),
                                        SizedBox(height: 8),
                                        SkeletonLoader(
                                          width: 100,
                                          height: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          childCount: 3,
                        ),
                      ),
                    )
                  else if (filteredNotes.isEmpty)
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
                                color: AppColors.indigoTint,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                LucideIcons.fileText,
                                size: 32,
                                color: AppColors.indigo,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              "No notes found",
                              style: AppTypography.label.copyWith(
                                color: AppColors.ink,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Try a different filter, or upload your first note",
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
                            final note = filteredNotes[index];
                            return _NoteCard(
                              note: note,
                              onDelete: () => _handleDelete(note.id),
                              onTogglePublish: () =>
                                  _handleTogglePublish(note.id),
                              onTogglePin: () => _handleTogglePin(note.id),
                              onEdit: () => _showEditModal(note),
                            );
                          },
                          childCount: filteredNotes.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Floating Upload Note Button (Glowing Gold FAB)
            Positioned(
              bottom: 24,
              right: 20,
              child: AnimatedPressable(
                pressScale: 0.9,
                onPress: _showCreateModal,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.5),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.plus,
                    size: 26,
                    color: AppColors.ink,
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
    required int totalNotes,
    required int publishedCount,
    required int draftCount,
    required double publishRatio,
    required int totalDownloads,
    required int totalViews,
    required int totalBookmarks,
    required List<String> subjects,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AnimatedPressable(
                                    pressScale: 0.9,
                                    onPress: () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/teacher');
                                      }
                                    },
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.14),
                                        borderRadius: AppRadius.smBorder,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        LucideIcons.arrowLeft,
                                        size: 18,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
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
                                          "Notes Manager",
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Study Materials",
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
                                "$totalNotes notes · $publishedCount published",
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
                          onPress: () => _fetchNotes(true),
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

                    // Glass panel: publish ring + live counts
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
                                progress: publishRatio,
                                label: "LIVE",
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "LIBRARY REACH",
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
                                            LucideIcons.download,
                                            size: 12,
                                            color: Colors.white70,
                                          ),
                                          value: totalDownloads,
                                          label: "downloads",
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
                                        MiniStat(
                                          icon: const Icon(
                                            LucideIcons.bookmark,
                                            size: 12,
                                            color: Colors.white70,
                                          ),
                                          value: totalBookmarks,
                                          label: "saved",
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

        // Drafts Insight Chip
        if (draftCount > 0)
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: AppSpacing.lg,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.goldTint,
                borderRadius: AppRadius.mdBorder,
              ),
              child: Row(
                children: [
                  AttentionDot(color: AppColors.gold),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      "$draftCount draft${draftCount == 1 ? "" : "s"} not yet visible to students",
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF8A6816),
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Search & Filters
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(
                placeholder: "Search by title, subject, topic…",
                onChanged: (v) => setState(() => _searchQuery = v),
                leftIcon: Icon(
                  LucideIcons.search,
                  size: 16,
                  color: AppColors.inkFaint,
                ),
                rightIcon: _searchQuery.isNotEmpty
                    ? AnimatedPressable(
                        pressScale: 0.85,
                        onPress: () => setState(() => _searchQuery = ""),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: AppColors.inkFaint,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Segmented Publish Filter Tabs
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Row(
                  children: [
                    _buildPublishTab(_PublishFilter.all, "All"),
                    _buildPublishTab(_PublishFilter.published, "Published"),
                    _buildPublishTab(_PublishFilter.draft, "Drafts"),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Subject Pills
              if (subjects.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["all", ...subjects].map((s) {
                      final active = _selectedSubject == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AnimatedPressable(
                          pressScale: 0.94,
                          onPress: () =>
                              setState(() => _selectedSubject = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.indigoTint
                                  : AppColors.surface,
                              borderRadius: AppRadius.pillBorder,
                              border: Border.all(
                                color: active
                                    ? AppColors.indigo
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              s == "all" ? "All Subjects" : s,
                              style: AppTypography.caption.copyWith(
                                color: active
                                    ? AppColors.indigo
                                    : AppColors.inkMuted,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPublishTab(_PublishFilter filter, String label) {
    final active = _publishFilter == filter;
    return Expanded(
      child: AnimatedPressable(
        pressScale: 0.97,
        onPress: () => setState(() => _publishFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.indigo : Colors.transparent,
            borderRadius: AppRadius.smBorder,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: active ? AppColors.white : AppColors.inkMuted,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatefulWidget {
  final TeacherNote note;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublish;
  final VoidCallback onTogglePin;
  final VoidCallback onEdit;

  const _NoteCard({
    required this.note,
    required this.onDelete,
    required this.onTogglePublish,
    required this.onTogglePin,
    required this.onEdit,
  });

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  List<Color> _gradientForSubject(String subject) {
    final list = [
      [AppColors.indigo, AppColors.indigoDark],
      [const Color(0xFF8A6D1F), const Color(0xFF5C4813)],
      [AppColors.mint, const Color(0xFF1F6B45)],
      [AppColors.coral, const Color(0xFF8E2E24)],
    ];
    int hash = 0;
    for (int i = 0; i < subject.length; i++) {
      hash = subject.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return list[hash.abs() % list.length];
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final grad = _gradientForSubject(note.subject);
    final createdParsed = DateTime.tryParse(note.createdAt);
    final createdFormatted = createdParsed != null
        ? "${createdParsed.day}/${createdParsed.month}/${createdParsed.year}"
        : note.createdAt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
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
            // Thumbnail or Subject gradient cover
            Stack(
              children: [
                if (note.thumbnailUrl != null &&
                    note.thumbnailUrl!.isNotEmpty)
                  SizedBox(
                    height: 128,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          note.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: grad,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.fileText,
                              size: 32,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x73000000), Colors.transparent],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: grad,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.fileText,
                      size: 32,
                      color: Colors.white70,
                    ),
                  ),

                // Pinned pill badge
                if (note.isPinned)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: AppRadius.smBorder,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.star,
                            size: 10,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Pinned",
                            style: AppTypography.caption.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Published/Draft pill badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: note.isPublished
                          ? const Color(0xE62F8F5B)
                          : const Color(0xD9171923),
                      borderRadius: AppRadius.smBorder,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          note.isPublished
                              ? LucideIcons.unlock
                              : LucideIcons.lock,
                          size: 10,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          note.isPublished ? "Published" : "Draft",
                          style: AppTypography.caption.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
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
                      AppBadge(label: note.subject, tone: AppBadgeTone.brand),
                      AppBadge(label: note.className, tone: AppBadgeTone.gold),
                      AppBadge(
                        label: note.fileType.toUpperCase(),
                        tone: AppBadgeTone.neutral,
                      ),
                    ],
                  ),
                  if (note.description != null &&
                      note.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      note.description!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),

                  // Mini Stat Bar: Downloads, Views, Saved, Price
                  Row(
                    children: [
                      _buildMiniTile("Downloads", "${note.downloads}"),
                      const SizedBox(width: 6),
                      _buildMiniTile("Views", "${note.views}"),
                      const SizedBox(width: 6),
                      _buildMiniTile("Saved", "${note.stats.totalBookmarks}"),
                      const SizedBox(width: 6),
                      _buildMiniTile("Price", "₹${note.price.toInt()}"),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Action Buttons: Pin, Publish, Preview, Edit, Delete
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedPressable(
                          pressScale: 0.88,
                          onPress: widget.onTogglePin,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: note.isPinned
                                  ? AppColors.goldTint
                                  : AppColors.surfaceMuted,
                              borderRadius: AppRadius.smBorder,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.pin,
                              size: 15,
                              color: note.isPinned
                                  ? AppColors.gold
                                  : AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedPressable(
                          pressScale: 0.88,
                          onPress: widget.onTogglePublish,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: note.isPublished
                                  ? AppColors.mintTint
                                  : AppColors.surfaceMuted,
                              borderRadius: AppRadius.smBorder,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              note.isPublished
                                  ? LucideIcons.unlock
                                  : LucideIcons.lock,
                              size: 15,
                              color: note.isPublished
                                  ? AppColors.mint
                                  : AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedPressable(
                          pressScale: 0.88,
                          onPress: () => launchUrl(
                            Uri.parse(note.fileUrl),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.indigoTint,
                              borderRadius: AppRadius.smBorder,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.eye,
                              size: 15,
                              color: AppColors.indigo,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedPressable(
                          pressScale: 0.88,
                          onPress: widget.onEdit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.indigoTint,
                              borderRadius: AppRadius.smBorder,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.pencil,
                              size: 15,
                              color: AppColors.indigo,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedPressable(
                          pressScale: 0.88,
                          onPress: widget.onDelete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.coralTint,
                              borderRadius: AppRadius.smBorder,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.trash2,
                              size: 15,
                              color: AppColors.coral,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Center(
                    child: Text(
                      "Added $createdFormatted",
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkFaint,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTile(String label, String value) {
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
