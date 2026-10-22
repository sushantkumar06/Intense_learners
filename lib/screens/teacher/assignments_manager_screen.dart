import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/teacher_assignment.dart';
import '../../services/api_client.dart';
import '../../services/cache_service.dart';
import '../../theme/app_theme.dart';
import '../../components/safe_back_scope.dart';
import '../../components/ui/app_card.dart';
import '../../components/ui/app_badge.dart';
import '../../components/ui/app_button.dart';
import '../../components/ui/app_input.dart';
import '../../components/ui/app_avatar.dart';
import '../../components/ui/animated_pressable.dart';
import '../../components/ui/progress_ring.dart';
import '../../components/ui/skeleton_loader.dart';
import '../../components/teacher/create_assignment_modal.dart';
import '../../components/teacher/student_profile_modal.dart';

const String _kHeroPhoto =
    "https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=1200&q=80&auto=format&fit=crop";

enum _StatusFilter { all, active, overdue, reviewed }

class AssignmentsManagerScreen extends ConsumerStatefulWidget {
  const AssignmentsManagerScreen({super.key});

  @override
  ConsumerState<AssignmentsManagerScreen> createState() =>
      _AssignmentsManagerScreenState();
}

final List<TeacherAssignment> _curatedTeacherAssignments = [
  TeacherAssignment(
    id: "assign-curated-1",
    title: "International Organizations & UN Charter Analysis",
    description:
        "Write an analytical essay on the role and effectiveness of the UN Security Council in conflict resolution.",
    subject: "Political Science",
    className: "Class 12",
    dueDate: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
    fileUrl: "",
    fileName: "UN_Charter_Assignment.pdf",
    fileSize: "1.2 MB",
    isPublished: true,
    createdAt:
        DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    stats: TeacherAssignmentStats(
        totalSubmissions: 12, totalComments: 4),
    submissions: [],
    comments: [],
  ),
  TeacherAssignment(
    id: "assign-curated-2",
    title: "Kinship, Caste and Class in Early Societies",
    description:
        "Read Chapter 3 of History and answer the structured source-based questions provided.",
    subject: "History",
    className: "Class 12th",
    dueDate: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
    fileUrl: "",
    fileName: "History_Chapter3_Questions.pdf",
    fileSize: "2.4 MB",
    isPublished: true,
    createdAt:
        DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
    stats: TeacherAssignmentStats(
        totalSubmissions: 18, totalComments: 6),
    submissions: [],
    comments: [],
  ),
];

class _AssignmentsManagerScreenState
    extends ConsumerState<AssignmentsManagerScreen> {
  List<TeacherAssignment> _assignments = List.from(_curatedTeacherAssignments);
  bool _loading = false;
  String _searchQuery = "";
  String _selectedSubject = "all";
  _StatusFilter _statusFilter = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    _loadCachedAssignments();
    _fetchAssignments();
  }

  void _loadCachedAssignments() {
    final cached =
        CacheService.getSync<List<dynamic>>('cached_teacher_assignments_v1');
    if (cached != null && cached.isNotEmpty) {
      final valid = cached
          .whereType<Map>()
          .map((n) => TeacherAssignment.fromJson(Map<String, dynamic>.from(n)))
          .toList();
      if (valid.isNotEmpty) {
        _assignments = valid;
        _loading = false;
        return;
      }
    }
    CacheService.get<List<dynamic>>('cached_teacher_assignments_v1').then((data) {
      if (data != null && data.isNotEmpty && mounted) {
        final valid = data
            .whereType<Map>()
            .map((n) => TeacherAssignment.fromJson(Map<String, dynamic>.from(n)))
            .toList();
        if (valid.isNotEmpty) {
          setState(() {
            _assignments = valid;
            _loading = false;
          });
        }
      }
    });
  }

  Future<void> _fetchAssignments([bool isRefresh = false]) async {
    if (!isRefresh && _assignments.isEmpty) {
      setState(() => _loading = true);
    }

    try {
      final response =
          await ref.read(dioProvider).get("/api/teacher/assignments");
      final data = response.data;
      if (data is Map && data['success'] == true && data['assignments'] is List) {
        final rawAssignments =
            (data['assignments'] as List).whereType<Map>().toList();
        if (rawAssignments.isNotEmpty) {
          if (mounted) {
            setState(() {
              _assignments = rawAssignments
                  .map((n) => TeacherAssignment.fromJson(
                      Map<String, dynamic>.from(n)))
                  .toList();
            });
          }
          CacheService.set('cached_teacher_assignments_v1', rawAssignments);
          return;
        }
      }
    } catch (e) {
      debugPrint("Teacher assignments error, trying student fallback: $e");
    }

    // Fallback: If teacher endpoint has no assignments or fails, fetch student/published assignments
    try {
      final studentResponse =
          await ref.read(dioProvider).get("/api/student/assignments");
      final studentData = studentResponse.data;
      List rawList = [];
      if (studentData is List) {
        rawList = studentData;
      } else if (studentData is Map && studentData['assignments'] is List) {
        rawList = studentData['assignments'] as List;
      }
      final valid = rawList.whereType<Map>().toList();
      if (valid.isNotEmpty) {
        if (mounted) {
          setState(() {
            _assignments = valid
                .map((n) => TeacherAssignment.fromJson(
                    Map<String, dynamic>.from(n)))
                .toList();
          });
        }
        CacheService.set('cached_teacher_assignments_v1', valid);
        return;
      }
    } catch (e) {
      debugPrint("Student assignments fallback error: $e");
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
      builder: (_) => const CreateAssignmentModal(),
    ).then((res) {
      if (res == true) _fetchAssignments();
    });
  }

  void _showStudentModal(TeacherStudentProfile student) {
    showDialog(
      context: context,
      builder: (_) => StudentProfileModal(student: student),
    );
  }

  Future<void> _handleDelete(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Delete assignment?",
          style: AppTypography.h3.copyWith(color: AppColors.ink),
        ),
        content: Text(
          "All submissions will be deleted too.",
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

    setState(
      () => _assignments = _assignments.where((n) => n.id != id).toList(),
    );
    try {
      final response =
          await ref.read(dioProvider).delete("/api/teacher/assignments?id=$id");
      if (response.data['success'] != true) _fetchAssignments();
    } catch (e) {
      _fetchAssignments();
    }
  }

  Future<void> _handleDeleteComment(
      String assignmentId, String commentId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Delete comment?",
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

    setState(() {
      _assignments = _assignments.map((a) {
        if (a.id == assignmentId) {
          return TeacherAssignment(
            id: a.id,
            title: a.title,
            description: a.description,
            subject: a.subject,
            className: a.className,
            dueDate: a.dueDate,
            fileUrl: a.fileUrl,
            fileName: a.fileName,
            fileSize: a.fileSize,
            isPublished: a.isPublished,
            createdAt: a.createdAt,
            stats: TeacherAssignmentStats(
              totalSubmissions: a.stats.totalSubmissions,
              totalComments: a.stats.totalComments - 1,
            ),
            submissions: a.submissions,
            comments: a.comments.where((c) => c.id != commentId).toList(),
          );
        }
        return a;
      }).toList();
    });
    try {
      await ref.read(dioProvider).delete(
            "/api/assignments/comments?id=$commentId",
          );
    } catch (e) {
      _fetchAssignments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Prepare metadata
    final withMeta = _assignments.map((a) {
      final dueParsed = DateTime.tryParse(a.dueDate);
      final overdue = dueParsed != null && dueParsed.isBefore(now);
      final completedCount =
          a.submissions.where((s) => s.isCompleted).length;
      final fullyReviewed =
          a.submissions.isNotEmpty && completedCount == a.submissions.length;
      return _AssignmentWithMeta(
        assignment: a,
        overdue: overdue,
        completedCount: completedCount,
        fullyReviewed: fullyReviewed,
      );
    }).toList();

    // Subjects
    final subjects = _assignments.map((n) => n.subject).toSet().toList()..sort();

    // Filtering
    final filtered = withMeta.where((m) {
      if (_statusFilter == _StatusFilter.active &&
          (m.overdue || m.fullyReviewed)) {
        return false;
      }
      if (_statusFilter == _StatusFilter.overdue && !m.overdue) return false;
      if (_statusFilter == _StatusFilter.reviewed && !m.fullyReviewed) {
        return false;
      }
      if (_selectedSubject != "all" && m.assignment.subject != _selectedSubject) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final a = m.assignment;
        if (!a.title.toLowerCase().contains(q) &&
            !a.description.toLowerCase().contains(q) &&
            !a.subject.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Stats calculations
    final totalAssignments = _assignments.length;
    final totalSubmissions =
        _assignments.fold<int>(0, (s, n) => s + n.stats.totalSubmissions);
    final totalComments =
        _assignments.fold<int>(0, (s, n) => s + n.stats.totalComments);
    final totalCompleted =
        withMeta.fold<int>(0, (s, m) => s + m.completedCount);
    final overallProgress = totalSubmissions > 0
        ? (totalCompleted / totalSubmissions).clamp(0.0, 1.0)
        : 0.0;
    final overdueCount =
        withMeta.where((m) => m.overdue && !m.fullyReviewed).length;
    final reviewedCount = withMeta.where((m) => m.fullyReviewed).length;

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
              onRefresh: () => _fetchAssignments(true),
              child: CustomScrollView(
                slivers: [
                  // Hero & Filter Header
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      totalAssignments: totalAssignments,
                      totalSubmissions: totalSubmissions,
                      totalComments: totalComments,
                      overallProgress: overallProgress,
                      overdueCount: overdueCount,
                      reviewedCount: reviewedCount,
                      subjects: subjects,
                    ),
                  ),

                  // Assignment Cards or Skeletons or Empty
                  if (_loading && _assignments.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: const SkeletonLoader(height: 160),
                            ),
                          ),
                          childCount: 3,
                        ),
                      ),
                    )
                  else if (filtered.isEmpty)
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
                              "No assignments found",
                              style: AppTypography.label.copyWith(
                                color: AppColors.ink,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Try a different filter, or create your first one",
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
                            final item = filtered[index];
                            return _AssignmentCard(
                              assignment: item.assignment,
                              overdue: item.overdue,
                              completedCount: item.completedCount,
                              fullyReviewed: item.fullyReviewed,
                              onDelete: () =>
                                  _handleDelete(item.assignment.id),
                              onDeleteComment: (cId) => _handleDeleteComment(
                                item.assignment.id,
                                cId,
                              ),
                              onViewStudent: _showStudentModal,
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Floating Create Button (Glowing Gold FAB)
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
    required int totalAssignments,
    required int totalSubmissions,
    required int totalComments,
    required double overallProgress,
    required int overdueCount,
    required int reviewedCount,
    required List<String> subjects,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cinematic Hero
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
                                          "Assignment Manager",
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
                                "Track & Grade",
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
                                "$totalAssignments assignments · $totalSubmissions submissions",
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
                          onPress: () => _fetchAssignments(true),
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

                    // Glass panel: aggregate completion ring + live counters
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
                                progress: overallProgress,
                                label: "DONE",
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "OVERALL COMPLETION",
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
                                        _MiniStat(
                                          icon: LucideIcons.fileText,
                                          value: totalAssignments,
                                          label: "assignments",
                                        ),
                                        _MiniStat(
                                          icon: LucideIcons.users,
                                          value: totalSubmissions,
                                          label: "submissions",
                                        ),
                                        _MiniStat(
                                          icon: LucideIcons.messageSquare,
                                          value: totalComments,
                                          label: "comments",
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

        // Insight chips (overdue and reviewed)
        if (overdueCount > 0 || reviewedCount > 0)
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: AppSpacing.lg,
            ),
            child: Row(
              children: [
                if (overdueCount > 0)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.coralTint,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Row(
                        children: [
                          const _AttentionDot(),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              "$overdueCount need attention",
                              style: AppTypography.caption.copyWith(
                                color: AppColors.coral,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (overdueCount > 0 && reviewedCount > 0)
                  const SizedBox(width: 8),
                if (reviewedCount > 0)
                  Expanded(
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
                          Icon(
                            LucideIcons.sparkles,
                            size: 13,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              "$reviewedCount fully reviewed",
                              style: AppTypography.caption.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Search & Filter controls
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
                placeholder: "Search assignments…",
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

              // Segmented Status Tabs
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Row(
                  children: [
                    _buildStatusTab(_StatusFilter.all, "All"),
                    _buildStatusTab(_StatusFilter.active, "Active"),
                    _buildStatusTab(_StatusFilter.overdue, "Overdue"),
                    _buildStatusTab(_StatusFilter.reviewed, "Reviewed"),
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

  Widget _buildStatusTab(_StatusFilter filter, String label) {
    final active = _statusFilter == filter;
    return Expanded(
      child: AnimatedPressable(
        pressScale: 0.97,
        onPress: () => setState(() => _statusFilter = filter),
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

class _AssignmentWithMeta {
  final TeacherAssignment assignment;
  final bool overdue;
  final int completedCount;
  final bool fullyReviewed;

  _AssignmentWithMeta({
    required this.assignment,
    required this.overdue,
    required this.completedCount,
    required this.fullyReviewed,
  });
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          "$value",
          style: AppTypography.label.copyWith(
            color: AppColors.white,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _AttentionDot extends StatefulWidget {
  const _AttentionDot();

  @override
  State<_AttentionDot> createState() => _AttentionDotState();
}

class _AttentionDotState extends State<_AttentionDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + 0.6 * _controller.value,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.coral,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _AssignmentCard extends StatefulWidget {
  final TeacherAssignment assignment;
  final bool overdue;
  final int completedCount;
  final bool fullyReviewed;
  final VoidCallback onDelete;
  final ValueChanged<String> onDeleteComment;
  final ValueChanged<TeacherStudentProfile> onViewStudent;

  const _AssignmentCard({
    required this.assignment,
    required this.overdue,
    required this.completedCount,
    required this.fullyReviewed,
    required this.onDelete,
    required this.onDeleteComment,
    required this.onViewStudent,
  });

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  bool _showSubmissions = false;
  bool _showComments = false;

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
    final a = widget.assignment;
    final total = a.submissions.length;
    final ringProgress = total > 0
        ? (widget.completedCount / total).clamp(0.0, 1.0)
        : 0.0;
    final grad = _gradientForSubject(a.subject);
    final dueParsed = DateTime.tryParse(a.dueDate);
    final dueFormatted = dueParsed != null
        ? "${dueParsed.day}/${dueParsed.month}/${dueParsed.year}"
        : a.dueDate;

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
            // Subject-tinted gradient header strip
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: AppTypography.label.copyWith(
                            color: AppColors.white,
                            fontSize: 15.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: AppRadius.smBorder,
                              ),
                              child: Text(
                                a.subject,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: AppRadius.smBorder,
                              ),
                              child: Text(
                                a.className,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.fullyReviewed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
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
                          const SizedBox(width: 4),
                          Text(
                            "Reviewed",
                            style: AppTypography.caption.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (widget.overdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: AppRadius.pillBorder,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _AttentionDot(),
                          const SizedBox(width: 5),
                          Text(
                            "Overdue",
                            style: AppTypography.caption.copyWith(
                              color: AppColors.coral,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    a.description,
                    style: AppTypography.body.copyWith(
                      color: AppColors.inkMuted,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Calendar Due Date
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 12,
                        color: AppColors.inkFaint,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Due $dueFormatted",
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Completion ring + Avatar stack
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: AppRadius.mdBorder,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.indigo,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: ProgressRing(
                            progress: ringProgress,
                            size: 60,
                            strokeWidth: 5,
                            color: AppColors.mint,
                            trackColor: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: total > 0
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${widget.completedCount}/$total completed",
                                      style: AppTypography.label.copyWith(
                                        color: AppColors.ink,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _AvatarStack(submissions: a.submissions),
                                  ],
                                )
                              : Text(
                                  "No submissions yet",
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.inkFaint,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Submissions Accordion
                  if (a.submissions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    AnimatedPressable(
                      pressScale: 0.98,
                      onPress: () =>
                          setState(() => _showSubmissions = !_showSubmissions),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.users,
                            size: 13,
                            color: AppColors.indigo,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${_showSubmissions ? "Hide" : "View"} Submissions (${a.submissions.length})",
                            style: AppTypography.label.copyWith(
                              color: AppColors.indigo,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showSubmissions) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: AppRadius.mdBorder,
                        ),
                        child: Column(
                          children: a.submissions.map((sub) {
                            final subDue =
                                DateTime.tryParse(sub.submittedAt);
                            final subFormatted = subDue != null
                                ? "${subDue.day}/${subDue.month}/${subDue.year}"
                                : sub.submittedAt;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.mdBorder,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            AppAvatar(
                                              name: sub.student.name ??
                                                  "Student",
                                              uri: sub.student.avatar,
                                              size: AppAvatarSize.sm,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    sub.student.name ??
                                                        "Unknown",
                                                    style: AppTypography.label
                                                        .copyWith(
                                                      color: AppColors.ink,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    sub.student.email ?? "",
                                                    style: AppTypography
                                                        .caption
                                                        .copyWith(
                                                      color: AppColors.inkMuted,
                                                      fontSize: 10,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedPressable(
                                        pressScale: 0.92,
                                        onPress: () =>
                                            widget.onViewStudent(sub.student),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.indigoTint,
                                            borderRadius: AppRadius.smBorder,
                                          ),
                                          child: Text(
                                            "Profile",
                                            style: AppTypography.label.copyWith(
                                              color: AppColors.indigo,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  AnimatedPressable(
                                    pressScale: 0.98,
                                    onPress: () => launchUrl(
                                      Uri.parse(sub.fileUrl),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          LucideIcons.fileText,
                                          size: 12,
                                          color: AppColors.inkFaint,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            sub.fileName,
                                            style: AppTypography.body.copyWith(
                                              color: AppColors.indigo,
                                              fontSize: 11.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          "(${sub.fileSize})",
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.inkFaint,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (sub.remarks != null &&
                                      sub.remarks!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "\"${sub.remarks}\"",
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.inkMuted,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Submitted: $subFormatted",
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.inkFaint,
                                          fontSize: 10,
                                        ),
                                      ),
                                      AppBadge(
                                        label: sub.status,
                                        tone: sub.isCompleted
                                            ? AppBadgeTone.success
                                            : AppBadgeTone.gold,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],

                  // Comments Accordion
                  if (a.comments.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    AnimatedPressable(
                      pressScale: 0.98,
                      onPress: () =>
                          setState(() => _showComments = !_showComments),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.messageSquare,
                            size: 13,
                            color: AppColors.indigo,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${_showComments ? "Hide" : "View"} Comments (${a.comments.length})",
                            style: AppTypography.label.copyWith(
                              color: AppColors.indigo,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showComments) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: AppRadius.mdBorder,
                        ),
                        child: Column(
                          children: a.comments.map((c) {
                            final cDate = DateTime.tryParse(c.createdAt);
                            final cFormatted = cDate != null
                                ? "${cDate.day}/${cDate.month}/${cDate.year}"
                                : c.createdAt;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.mdBorder,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            c.user.name ?? "Unknown",
                                            style: AppTypography.label.copyWith(
                                              color: AppColors.ink,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          AppBadge(
                                            label: c.user.role,
                                            tone: c.user.role == "TEACHER"
                                                ? AppBadgeTone.gold
                                                : AppBadgeTone.brand,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            cFormatted,
                                            style: AppTypography.caption
                                                .copyWith(
                                              color: AppColors.inkFaint,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          AnimatedPressable(
                                            pressScale: 0.85,
                                            onPress: () =>
                                                widget.onDeleteComment(c.id),
                                            child: Icon(
                                              LucideIcons.trash2,
                                              size: 13,
                                              color: AppColors.coral,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    c.content,
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.ink,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // Actions: Download PDF & Delete
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: "Download PDF",
                          icon: LucideIcons.download,
                          variant: AppButtonVariant.primary,
                          onPress: () => launchUrl(
                            Uri.parse(a.fileUrl),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          label: "Delete",
                          icon: LucideIcons.trash2,
                          variant: AppButtonVariant.destructive,
                          onPress: widget.onDelete,
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
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<TeacherSubmission> submissions;

  const _AvatarStack({
    required this.submissions,
  });

  @override
  Widget build(BuildContext context) {
    const max = 4;
    final shown = submissions.take(max).toList();
    final extra = submissions.length - shown.length;

    return Row(
      children: [
        for (int i = 0; i < shown.length; i++)
          Transform.translate(
            offset: Offset(i == 0 ? 0 : -10.0 * i, 0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: AppAvatar(
                name: shown[i].student.name ?? "Student",
                uri: shown[i].student.avatar,
                size: AppAvatarSize.sm,
              ),
            ),
          ),
        if (extra > 0)
          Transform.translate(
            offset: Offset(-10.0 * shown.length, 0),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                "+$extra",
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
