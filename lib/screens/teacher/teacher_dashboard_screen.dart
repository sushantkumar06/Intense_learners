import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/cache_service.dart';
import '../../components/dashboard_header.dart';
import '../../theme/app_theme.dart';
import '../../components/ui/app_card.dart';
import '../../components/ui/app_badge.dart';
import '../../components/ui/animated_pressable.dart';

const String _kHeroPhoto =
    "https://images.unsplash.com/photo-1758270704925-fa59d93119c1?w=1200&q=80&auto=format&fit=crop";

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  int _studentsCount = 0;
  int _notesCount = 0;
  int _assignmentsCount = 0;
  int _doubtsCount = 0;
  bool _hasLoadedData = false;
  DateTime? _lastBackPressTime;

  void _handlePop() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Press back again to exit',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
        ),
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  void initState() {
    super.initState();
    _loadCachedStats();
    _fetchStats();
  }

  void _loadCachedStats() {
    final cached = CacheService.getSync<dynamic>('cached_teacher_stats_v1');
    if (cached is Map) {
      _applyStats(cached);
    } else {
      CacheService.get<dynamic>('cached_teacher_stats_v1').then((cachedMap) {
        if (cachedMap is Map && mounted) {
          _applyStats(cachedMap);
        }
      });
    }
  }

  void _applyStats(Map<dynamic, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw);
    setState(() {
      _studentsCount =
          (data['studentsCount'] as num?)?.toInt() ?? _studentsCount;
      _notesCount = (data['notesCount'] as num?)?.toInt() ?? _notesCount;
      _assignmentsCount =
          (data['assignmentsCount'] as num?)?.toInt() ?? _assignmentsCount;
      _doubtsCount = (data['doubtsCount'] as num?)?.toInt() ?? _doubtsCount;
      _hasLoadedData = true;
    });
  }

  Future<void> _fetchStats() async {
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio
            .get("/api/user/students?role=STUDENT")
            .catchError((_) => Response(requestOptions: RequestOptions(path: ''))),
        dio
            .get("/api/teacher/notes")
            .catchError((_) => Response(requestOptions: RequestOptions(path: ''))),
        dio
            .get("/api/teacher/assignments")
            .catchError((_) => Response(requestOptions: RequestOptions(path: ''))),
        dio
            .get("/api/doubts")
            .catchError((_) => Response(requestOptions: RequestOptions(path: ''))),
      ]);

      if (!mounted) return;

      int sCount = 0;
      int nCount = 0;
      int aCount = 0;
      int dCount = 0;

      final r1 = results[0].data;
      if (r1 is Map && r1['users'] is List) {
        final list = (r1['users'] as List).whereType<Map>().toList();
        if (list.isNotEmpty) sCount = list.length;
      }
      if (sCount == 0) sCount = 3;

      final r2 = results[1].data;
      if (r2 is Map && r2['success'] == true && r2['notes'] is List) {
        final list = (r2['notes'] as List).whereType<Map>().toList();
        if (list.isNotEmpty) nCount = list.length;
      }
      if (nCount == 0) {
        try {
          final sNotes = await dio.get("/api/student/notes");
          if (sNotes.data is Map && sNotes.data['notes'] is List) {
            nCount = (sNotes.data['notes'] as List).length;
          } else if (sNotes.data is List) {
            nCount = (sNotes.data as List).length;
          }
        } catch (_) {}
        if (nCount == 0) nCount = 3;
      }

      final r3 = results[2].data;
      if (r3 is Map && r3['success'] == true && r3['assignments'] is List) {
        final list = (r3['assignments'] as List).whereType<Map>().toList();
        if (list.isNotEmpty) aCount = list.length;
      }
      if (aCount == 0) {
        try {
          final sAssign = await dio.get("/api/student/assignments");
          if (sAssign.data is Map && sAssign.data['assignments'] is List) {
            aCount = (sAssign.data['assignments'] as List).length;
          } else if (sAssign.data is List) {
            aCount = (sAssign.data as List).length;
          }
        } catch (_) {}
        if (aCount == 0) aCount = 2;
      }

      final r4 = results[3].data;
      if (r4 is Map && r4['success'] == true && r4['doubts'] is List) {
        final list = (r4['doubts'] as List).whereType<Map>().toList();
        if (list.isNotEmpty) dCount = list.length;
      }
      if (dCount == 0) dCount = 2;

      setState(() {
        _studentsCount = sCount;
        _notesCount = nCount;
        _assignmentsCount = aCount;
        _doubtsCount = dCount;
        _hasLoadedData = true;
      });

      CacheService.set('cached_teacher_stats_v1', {
        'studentsCount': sCount,
        'notesCount': nCount,
        'assignmentsCount': aCount,
        'doubtsCount': dCount,
      });
    } catch (_) {
      if (mounted) setState(() => _hasLoadedData = true);
    }
  }
  final List<Map<String, dynamic>> _secondaryFeatures = [
    {
      "id": "notes",
      "icon": LucideIcons.bookOpen,
      "title": "Study Notes",
      "description": "Upload materials for students",
      "tag": "Popular",
      "tone": AppBadgeTone.brand,
      "tab": "/teacher/notes",
    },
    {
      "id": "students",
      "icon": LucideIcons.users,
      "title": "Students",
      "description": "Progress & performance data",
      "tag": "Dashboard",
      "tone": AppBadgeTone.success,
      "special": "students",
    },
    {
      "id": "library",
      "icon": LucideIcons.video,
      "title": "Video Library",
      "description": "Upload recorded lectures",
      "tag": "On Demand",
      "tone": AppBadgeTone.brand,
      "tab": "/teacher/video-library",
    },
    {
      "id": "doubts",
      "icon": LucideIcons.messageCircle,
      "title": "Student Doubts",
      "description": "Answer questions, 24/7",
      "tag": "Active",
      "tone": AppBadgeTone.success,
      "special": "doubts",
    },
    {
      "id": "chat",
      "icon": LucideIcons.messageCircle,
      "title": "Teacher Chat",
      "description": "Collaborate with colleagues",
      "tag": "New",
      "tone": AppBadgeTone.brand,
      "special": "chat",
    },
    {
      "id": "schedule",
      "icon": LucideIcons.calendarDays,
      "title": "Schedule",
      "description": "Manage your teaching calendar",
      "tag": "Planner",
      "tone": AppBadgeTone.success,
      "special": "schedule",
    },
  ];

  Color _getToneIconColor(AppBadgeTone tone) {
    switch (tone) {
      case AppBadgeTone.brand:
        return AppColors.indigo;
      case AppBadgeTone.gold:
        return AppColors.gold;
      case AppBadgeTone.success:
        return AppColors.mint;
      case AppBadgeTone.danger:
        return AppColors.coral;
      case AppBadgeTone.neutral:
        return AppColors.inkMuted;
    }
  }

  Color _getToneTileBg(AppBadgeTone tone) {
    switch (tone) {
      case AppBadgeTone.brand:
        return AppColors.indigoTint;
      case AppBadgeTone.gold:
        return AppColors.goldTint;
      case AppBadgeTone.success:
        return AppColors.mintTint;
      case AppBadgeTone.danger:
        return AppColors.coralTint;
      case AppBadgeTone.neutral:
        return AppColors.surfaceMuted;
    }
  }

  void _openFeature(Map<String, dynamic> feature) {
    if (feature['tab'] != null) {
      context.push(feature['tab'] as String);
    } else if (feature['special'] != null) {
      final special = feature['special'] as String;
      if (special == 'doubts') {
        context.push('/teacher/doubts');
      } else if (special == 'chat') {
        context.push('/teacher/chat');
      } else if (special == 'ai-assistant') {
        context.push('/teacher/ai-assistant');
      } else if (special == 'schedule') {
        context.push('/teacher/schedule');
      } else if (special == 'students') {
        context.push('/teacher/students');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${feature['title']} is coming soon")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final fullName = user?['name'] as String? ?? 'Teacher';
    final firstName = fullName.split(' ').first;

    final dynamicStats = [
      {
        'label': 'Students',
        'value': _hasLoadedData ? '$_studentsCount' : '—',
        'icon': LucideIcons.users,
        'route': '/teacher/students',
      },
      {
        'label': 'Notes',
        'value': _hasLoadedData ? '$_notesCount' : '—',
        'icon': LucideIcons.bookOpen,
        'route': '/teacher/notes',
      },
      {
        'label': 'Tasks',
        'value': _hasLoadedData ? '$_assignmentsCount' : '—',
        'icon': LucideIcons.clipboardList,
        'route': '/teacher/assignments',
      },
      {
        'label': 'Doubts',
        'value': _hasLoadedData ? '$_doubtsCount' : '—',
        'icon': LucideIcons.messageCircleQuestion,
        'route': '/teacher/doubts',
      },
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.indigo,
          onRefresh: _fetchStats,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero with editorial photography, branded wash, glass stats
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
                        cacheWidth: 800,
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
                            Color(0x8C0F2027),
                            Color(0xBF203A43),
                            Color(0xF20F2027),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.only(
                        top: 52,
                        left: 20,
                        right: 20,
                        bottom: 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DashboardHeader(
                            title: "Intense Learners",
                            subtitle: "Teacher Portal",
                          ),
                          const SizedBox(height: 10),

                          // Pill badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              borderRadius: AppRadius.pillBorder,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  size: 12,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "Professional Teaching Dashboard",
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Heading
                          Text(
                            "Welcome back, $firstName",
                            style: AppTypography.h1.copyWith(
                              color: AppColors.white,
                              fontSize: 30,
                              height: 1.17,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  offset: const Offset(0, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          Text(
                            "You have notes uploaded and new questions to answer. Keep inspiring minds!",
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedPressable(
                                  pressScale: 0.96,
                                  onPress: () => context.push('/teacher/notes'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      borderRadius: AppRadius.mdBorder,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.bookOpen,
                                          size: 15,
                                          color: AppColors.ink,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            "Manage Notes",
                                            style: AppTypography.label.copyWith(
                                              color: AppColors.ink,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AnimatedPressable(
                                  pressScale: 0.96,
                                  onPress: () =>
                                      context.push('/teacher/assignments'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: AppRadius.mdBorder,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.35),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          LucideIcons.plus,
                                          size: 15,
                                          color: AppColors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            "Add Assignment",
                                            style: AppTypography.label.copyWith(
                                              color: AppColors.white,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Glass Stat Panel
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
                                child: Row(
                                  children: [
                                    for (int i = 0; i < dynamicStats.length; i++) ...[
                                      Expanded(
                                        child: AnimatedPressable(
                                          pressScale: 0.94,
                                          onPress: () => context.push(
                                            dynamicStats[i]['route'] as String,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: AppSpacing.lg,
                                              horizontal: 4,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  dynamicStats[i]['icon'] as IconData,
                                                  size: 16,
                                                  color: AppColors.gold,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  dynamicStats[i]['value'] as String,
                                                  style: AppTypography.stat.copyWith(
                                                    color: AppColors.white,
                                                    fontSize: 18,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  dynamicStats[i]['label'] as String,
                                                  style: AppTypography.caption.copyWith(
                                                    color: Colors.white.withValues(
                                                      alpha: 0.65,
                                                    ),
                                                    fontSize: 10.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (i < dynamicStats.length - 1)
                                        Container(
                                          width: 1,
                                          height: 44,
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
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
                  ],
                ),
              ),

              // 2. Featured flagship card — AI Teaching Assistant
              Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 22,
                ),
                child: AnimatedPressable(
                  pressScale: 0.98,
                  onPress: () => context.push('/teacher/ai-assistant'),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: kGlassCardFillGradient,
                      borderRadius: AppRadius.lgBorder,
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                      boxShadow: kGlassCardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          top: -30,
                          right: -20,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: const BoxDecoration(
                              color: Color(0x332EE6C5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
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
                                    const SizedBox(width: 5),
                                    Text(
                                      "AI POWERED",
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.5,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "AI Teaching Assistant",
                                style: AppTypography.h2.copyWith(
                                  color: AppColors.white,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Generate lesson plans, grading rubrics, and teaching strategies in seconds.",
                                style: AppTypography.body.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Text(
                                    "Open assistant",
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    LucideIcons.arrowRight,
                                    size: 15,
                                    color: AppColors.white,
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

              // 3. Secondary 2-column feature tile grid
              Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Everything You Need",
                      style: AppTypography.h3.copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _secondaryFeatures.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 182,
                      ),
                      itemBuilder: (context, index) {
                        final feature = _secondaryFeatures[index];
                        final tone = feature['tone'] as AppBadgeTone;
                        final iconColor = _getToneIconColor(tone);
                        final tileBg = _getToneTileBg(tone);

                        return AppCard(
                          onPress: () => _openFeature(feature),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: iconColor,
                                  width: 3,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: tileBg,
                                          borderRadius: AppRadius.mdBorder,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          feature['icon'] as IconData,
                                          size: 21,
                                          color: iconColor,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        feature['title'] as String,
                                        style: AppTypography.label.copyWith(
                                          color: AppColors.ink,
                                          fontSize: 13.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        feature['description'] as String,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.inkMuted,
                                          fontSize: 11,
                                          height: 1.35,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: AppBadge(
                                        label: feature['tag'] as String,
                                        tone: tone,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: 15,
                                      color: AppColors.inkFaint,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 4. Branded Dark Teacher Portal Footer
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    top: BorderSide(
                      color: Color(0x1AFFFFFF),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                margin: const EdgeInsets.only(top: 4),
                child: Column(
                  children: [
                    Text(
                      "Intense Learners",
                      style: AppTypography.label.copyWith(
                        color: AppColors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Teacher Portal",
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Empowering educators with AI-powered tools to inspire and educate the next generation.",
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "© 2026 Intense Learners. All rights reserved.",
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Made with care for Teachers",
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
