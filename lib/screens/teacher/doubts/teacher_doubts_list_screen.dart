import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/doubt.dart';
import '../../../services/api_client.dart';
import '../../../services/cache_service.dart';
import '../../../theme/app_theme.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/app_badge.dart';
import '../../../components/ui/app_avatar.dart';
import '../../../components/ui/animated_pressable.dart';

class TeacherDoubtsListScreen extends ConsumerStatefulWidget {
  const TeacherDoubtsListScreen({super.key});

  @override
  ConsumerState<TeacherDoubtsListScreen> createState() =>
      _TeacherDoubtsListScreenState();
}

final List<Doubt> _curatedTeacherDoubts = [
  Doubt(
    id: "curated-doubt-1",
    title:
        "Difference between Veto power and collective security in UN charter?",
    description:
        "Can permanent members veto procedural matters in the UN Security Council, or does veto only apply to substantive decisions?",
    subject: "Political Science",
    classLevel: "Class 12",
    priority: "high",
    status: "open",
    isSolved: false,
    upvotes: 8,
    views: 45,
    createdAt:
        DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
    student: DoubtUser(
      id: "u-doubt-1",
      name: "Aarav Sharma",
      avatar:
          "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&q=80",
      email: "aarav.sharma@example.com",
      role: "STUDENT",
    ),
    isMyDoubt: false,
    hasUpvoted: false,
    stats: DoubtStats(totalReplies: 1, totalUpvotes: 8),
    replies: [
      DoubtReply(
        id: "rep-1",
        content:
            "Under Article 27 of the UN Charter, veto applies strictly to substantive resolutions, not procedural matters.",
        isPinned: false,
        isAccepted: false,
        upvotes: 3,
        createdAt:
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        user: DoubtUser(id: "t-1", name: "Faculty", role: "TEACHER"),
        isMyReply: true,
        hasUpvoted: false,
      ),
    ],
  ),
  Doubt(
    id: "curated-doubt-2",
    title:
        "How did archaeologists identify social differences in Harappan burials?",
    description:
        "Are ornaments and pottery in graves considered evidence of wealth disparity or afterlife beliefs in early societies?",
    subject: "History",
    classLevel: "Class 12th",
    priority: "normal",
    status: "open",
    isSolved: false,
    upvotes: 5,
    views: 32,
    createdAt:
        DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    student: DoubtUser(
      id: "u-doubt-2",
      name: "Priya Patel",
      avatar:
          "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80",
      email: "priya.patel@example.com",
      role: "STUDENT",
    ),
    isMyDoubt: false,
    hasUpvoted: false,
    stats: DoubtStats(totalReplies: 0, totalUpvotes: 5),
    replies: [],
  ),
];

class _TeacherDoubtsListScreenState
    extends ConsumerState<TeacherDoubtsListScreen> {
  List<Doubt> _allDoubts = List.from(_curatedTeacherDoubts);
  bool _loading = false;
  String _searchQuery = "";
  String _statusFilter = "all"; // 'all', 'open', 'solved'
  String _subjectFilter = "All";

  @override
  void initState() {
    super.initState();
    _loadCachedDoubts();
    _fetchDoubts();
  }

  void _loadCachedDoubts() {
    final cached =
        CacheService.getSync<List<dynamic>>('cached_teacher_doubts_v1');
    if (cached != null && cached.isNotEmpty) {
      final valid = cached
          .whereType<Map>()
          .map((e) => Doubt.fromJson(e))
          .toList();
      if (valid.isNotEmpty) {
        _allDoubts = valid;
        _loading = false;
        return;
      }
    }
    CacheService.get<List<dynamic>>('cached_teacher_doubts_v1').then((data) {
      if (data != null && data.isNotEmpty && mounted) {
        final valid = data
            .whereType<Map>()
            .map((e) => Doubt.fromJson(e))
            .toList();
        if (valid.isNotEmpty) {
          setState(() {
            _allDoubts = valid;
            _loading = false;
          });
        }
      }
    });
  }

  Future<void> _fetchDoubts() async {
    if (_allDoubts.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final response = await ref.read(dioProvider).get("/api/doubts");
      if (response.data is Map && response.data['success'] == true) {
        final rawDoubts = response.data['doubts'];
        if (rawDoubts is List) {
          final doubtsData = rawDoubts.whereType<Map>().toList();
          if (doubtsData.isNotEmpty) {
            if (mounted) {
              setState(() {
                _allDoubts =
                    doubtsData.map((e) => Doubt.fromJson(e)).toList();
              });
            }
            CacheService.set('cached_teacher_doubts_v1', doubtsData);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching doubts: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTimeAgo(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inSeconds < 60) return "just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      if (diff.inDays < 7) return "${diff.inDays}d ago";
      if (diff.inDays < 28) return "${diff.inDays ~/ 7}w ago";
      return "${d.month}/${d.day}/${d.year}";
    } catch (_) {
      return '';
    }
  }

  AppBadgeTone _priorityTone(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return AppBadgeTone.success;
      case 'normal':
        return AppBadgeTone.brand;
      case 'high':
        return AppBadgeTone.gold;
      case 'urgent':
        return AppBadgeTone.danger;
      default:
        return AppBadgeTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _allDoubts.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.indigo),
        ),
      );
    }

    final subjects = ["All", ..._allDoubts.map((d) => d.subject).toSet()];

    final filtered = _allDoubts.where((d) {
      if (_statusFilter == "open" && d.status != "open") return false;
      if (_statusFilter == "solved" && d.status != "solved") return false;
      if (_subjectFilter != "All" && d.subject != _subjectFilter) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!d.title.toLowerCase().contains(q) &&
            !d.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    final stats = {
      'total': _allDoubts.length,
      'pending': _allDoubts.where((d) => !d.isSolved).length,
      'solved': _allDoubts.where((d) => d.isSolved).length,
      'highPriority': _allDoubts
          .where((d) => d.priority == "high" || d.priority == "urgent")
          .length,
    };

    final statCards = [
      {'icon': LucideIcons.messageSquare, 'value': stats['total'] ?? 0, 'label': 'Total'},
      {'icon': LucideIcons.clock, 'value': stats['pending'] ?? 0, 'label': 'Pending'},
      {'icon': LucideIcons.circleCheck, 'value': stats['solved'] ?? 0, 'label': 'Solved'},
      {'icon': LucideIcons.circleAlert, 'value': stats['highPriority'] ?? 0, 'label': 'Priority'},
    ];

    final filters = [
      {'value': 'all', 'label': 'All Status'},
      {'value': 'open', 'label': 'Open Only'},
      {'value': 'solved', 'label': 'Solved Only'},
    ];

    return SafeBackScope(
      fallbackLocation: '/teacher',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: AppColors.indigo,
            onRefresh: _fetchDoubts,
            child: CustomScrollView(
              slivers: [
                // Cinematic Banner Header
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.indigoDark, AppColors.indigo],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: -50,
                                right: -40,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 40,
                                right: 50,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Padding(
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
                                      children: [
                                        AnimatedPressable(
                                          pressScale: 0.9,
                                          onPress: () => context.canPop()
                                              ? context.pop()
                                              : context.go('/teacher'),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.14),
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
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.14),
                                                borderRadius:
                                                    AppRadius.pillBorder,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    LucideIcons.sparkles,
                                                    size: 10,
                                                    color: AppColors.gold,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    "Doubt Manager",
                                                    style: AppTypography
                                                        .caption
                                                        .copyWith(
                                                      color: AppColors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Answer Students",
                                              style: AppTypography.h2.copyWith(
                                                fontSize: 21,
                                                color: AppColors.white,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.25),
                                                    offset: const Offset(0, 2),
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // Glass Stat Panel
                                  ClipRRect(
                                    borderRadius: AppRadius.lgBorder,
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 16,
                                        sigmaY: 16,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.28),
                                          borderRadius: AppRadius.lgBorder,
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.18),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            for (int i = 0;
                                                i < statCards.length;
                                                i++) ...[
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: AppSpacing.lg,
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        statCards[i]['icon']
                                                            as IconData,
                                                        size: 14,
                                                        color: AppColors.gold,
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        "${statCards[i]['value']}",
                                                        style: AppTypography
                                                            .stat
                                                            .copyWith(
                                                          color:
                                                              AppColors.white,
                                                          fontSize: 17,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        statCards[i]['label']
                                                            as String,
                                                        style: AppTypography
                                                            .caption
                                                            .copyWith(
                                                          color: Colors.white
                                                              .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                          fontSize: 9.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              if (i < statCards.length - 1)
                                                Container(
                                                  width: 1,
                                                  height: 38,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.12),
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
                          ],
                        ),
                      ),
                    ),

                    // Controls: Search & Filters
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
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    cursorColor: const Color(0xFF2EE6C5),
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.ink,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Search doubts…",
                                      hintStyle: AppTypography.body.copyWith(
                                        color: AppColors.inkFaint,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  AnimatedPressable(
                                    pressScale: 0.85,
                                    onPress: () =>
                                        setState(() => _searchQuery = ""),
                                    child: Icon(
                                      LucideIcons.x,
                                      size: 14,
                                      color: AppColors.inkFaint,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Status Filter Pills
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: filters.map((f) {
                                final active = _statusFilter == f['value'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: AnimatedPressable(
                                    pressScale: 0.95,
                                    onPress: () => setState(
                                      () => _statusFilter = f['value']!,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 13,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? AppColors.indigo
                                            : AppColors.surface,
                                        borderRadius: AppRadius.pillBorder,
                                        border: Border.all(
                                          color: active
                                              ? AppColors.indigo
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        f['label']!,
                                        style: AppTypography.label.copyWith(
                                          fontSize: 12,
                                          color: active
                                              ? AppColors.white
                                              : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Subject Pills
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: subjects.map((s) {
                                final active = _subjectFilter == s;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: AnimatedPressable(
                                    pressScale: 0.95,
                                    onPress: () =>
                                        setState(() => _subjectFilter = s),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? AppColors.indigoTint
                                            : AppColors.surfaceMuted,
                                        borderRadius: AppRadius.pillBorder,
                                      ),
                                      child: Text(
                                        s,
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 11.5,
                                          color: active
                                              ? AppColors.indigo
                                              : AppColors.inkMuted,
                                          fontWeight: active
                                              ? FontWeight.w600
                                              : FontWeight.normal,
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
                ),
              ),

              // Doubts Feed
              if (filtered.isEmpty)
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
                            LucideIcons.messageSquare,
                            size: 32,
                            color: AppColors.indigo,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          "No doubts found",
                          style: AppTypography.label.copyWith(
                            color: AppColors.ink,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "No doubts match your current filters.",
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
                  padding: const EdgeInsets.only(top: 14, bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doubt = filtered[index];
                        final isUrgent =
                            doubt.priority.toLowerCase() == "urgent" &&
                                !doubt.isSolved;
                        final borderColor = doubt.isSolved
                            ? AppColors.mint
                            : isUrgent
                                ? AppColors.coral
                                : AppColors.indigo;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: AnimatedPressable(
                            pressScale: 0.98,
                            onPress: () => context.push(
                              '/teacher/doubts/detail',
                              extra: doubt,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.lgBorder,
                                border: Border.all(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: borderColor,
                                      width: 3.5,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppAvatar(
                                      name: doubt.student.name,
                                      uri: doubt.student.avatar,
                                      size: AppAvatarSize.sm,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  doubt.title,
                                                  style: AppTypography.label
                                                      .copyWith(
                                                    color: AppColors.ink,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (doubt.isSolved) ...[
                                                const SizedBox(width: 8),
                                                const AppBadge(
                                                  label: "Solved",
                                                  tone: AppBadgeTone.success,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),

                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                doubt.student.name,
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  color: AppColors.inkMuted,
                                                ),
                                              ),
                                              Text("•",
                                                  style: TextStyle(
                                                      color:
                                                          AppColors.inkFaint)),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    LucideIcons.clock,
                                                    size: 10,
                                                    color: AppColors.inkFaint,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    _formatTimeAgo(
                                                      doubt.createdAt,
                                                    ),
                                                    style: AppTypography.caption
                                                        .copyWith(
                                                      color: AppColors.inkMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              AppBadge(
                                                label: doubt.subject,
                                                tone: AppBadgeTone.brand,
                                              ),
                                              AppBadge(
                                                label: doubt.priority,
                                                tone: _priorityTone(
                                                  doubt.priority,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          Text(
                                            doubt.description,
                                            style: AppTypography.body.copyWith(
                                              color: AppColors.inkMuted,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 10),

                                          Row(
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    LucideIcons.messageSquare,
                                                    size: 13,
                                                    color: AppColors.inkFaint,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    "${doubt.stats.totalReplies} replies",
                                                    style: AppTypography
                                                        .caption
                                                        .copyWith(
                                                      color: AppColors.inkMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 18),
                                              Row(
                                                children: [
                                                  Icon(
                                                    LucideIcons.thumbsUp,
                                                    size: 13,
                                                    color: AppColors.inkFaint,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    "${doubt.stats.totalUpvotes} votes",
                                                    style: AppTypography
                                                        .caption
                                                        .copyWith(
                                                      color: AppColors.inkMuted,
                                                    ),
                                                  ),
                                                ],
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
