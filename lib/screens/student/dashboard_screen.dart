import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/cache_service.dart';
import '../../theme/app_theme.dart';
import '../../components/dashboard_header.dart';
import '../../components/ui/ui.dart';

const String _heroPhoto =
    "https://images.unsplash.com/photo-1741699427799-3fbb70fce948?w=1200&q=80&auto=format&fit=crop";

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  int _activeTestimonial = 0;
  Timer? _timer;

  int _dailyGoalMinutes = 120;
  int _watchHours = 0;
  int _watchMinutes = 0;
  int _pendingAssignments = 0;
  int _notesCount = 0;
  int _doubtsAsked = 0;
  bool _hasAnyData = false;
  DateTime? _lastBackPressTime;

  void _handlePop() {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
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
          margin: const EdgeInsets.only(bottom: 70, left: 32, right: 32),
        ),
      );
      return;
    }
    SystemNavigator.pop();
  }

  bool _slideForward = true;
  double _testimonialDragDistance = 0;

  void _startTestimonialTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _nextTestimonial(fromTimer: true);
      }
    });
  }

  void _nextTestimonial({bool fromTimer = false}) {
    if (_testimonials.isEmpty) return;
    setState(() {
      _slideForward = true;
      _activeTestimonial = (_activeTestimonial + 1) % _testimonials.length;
    });
    if (!fromTimer) _startTestimonialTimer();
  }

  void _prevTestimonial() {
    if (_testimonials.isEmpty) return;
    setState(() {
      _slideForward = false;
      _activeTestimonial =
          (_activeTestimonial - 1 + _testimonials.length) % _testimonials.length;
    });
    _startTestimonialTimer();
  }

  final List<Map<String, dynamic>> _testimonials = [
    {
      "name": "Tanzeel",
      "role": "JEE Aspirant",
      "text":
          "It is not just an ordinary coaching centre. Every teacher is fully dedicated to teach the students.",
      "rating": 5,
      "course": "JEE Mains 2025"
    },
    {
      "name": "Amit Sharma",
      "role": "Student",
      "text": "Best institute for all subjects",
      "rating": 5,
      "course": "NEET 2024"
    },
    {
      "name": "Yash",
      "role": "Student",
      "text":
          "The faculty is highly knowledgeable and always willing to go the extra mile. Highly recommended!",
      "rating": 5,
      "course": "JEE Mains 2024"
    },
  ];

  final List<Map<String, dynamic>> _secondaryFeatures = [
    {
      "id": "notes",
      "icon": LucideIcons.bookOpen,
      "title": "Study Notes",
      "description": "Materials from expert teachers",
      "tag": "Popular",
      "tone": AppBadgeTone.brand,
      "tab": "/student/notes"
    },
    {
      "id": "assignments",
      "icon": LucideIcons.clipboardCheck,
      "title": "Assignments",
      "description": "AI-graded, instant feedback",
      "tag": "Top Rated",
      "tone": AppBadgeTone.gold,
      "tab": "/student/assignments"
    },
    {
      "id": "teacher",
      "icon": LucideIcons.graduationCap,
      "title": "Teachers",
      "description": "Browse teacher profiles",
      "tag": "Professional",
      "tone": AppBadgeTone.brand,
      "special": "teachers"
    },
    {
      "id": "quizzes",
      "icon": LucideIcons.trophy,
      "title": "Mock Tests",
      "description": "Unlimited practice quizzes",
      "tag": "Exam Ready",
      "tone": AppBadgeTone.success,
      "special": "quiz"
    },
    {
      "id": "study-planner",
      "icon": LucideIcons.sparkles,
      "title": "Study Planner",
      "description": "AI-powered custom timetable",
      "tag": "AI Smart",
      "tone": AppBadgeTone.gold,
      "special": "study-planner"
    },
    {
      "id": "videos",
      "icon": LucideIcons.video,
      "title": "Video Library",
      "description": "Recorded lectures, 24/7",
      "tag": "On Demand",
      "tone": AppBadgeTone.brand,
      "tab": "/student/videos"
    },
    {
      "id": "doubts",
      "icon": LucideIcons.messageCircleQuestion,
      "title": "Doubt Solving",
      "description": "Ask teachers directly",
      "tag": "Active",
      "tone": AppBadgeTone.success,
      "special": "doubts"
    },
    {
      "id": "payments",
      "icon": LucideIcons.wallet,
      "title": "Payments",
      "description": "Fees & order tracking",
      "tag": "Protected",
      "tone": AppBadgeTone.brand,
      "special": "payments"
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDailyGoal();
    _loadSavedTestimonials();
    _loadCachedStats();
    _startTestimonialTimer();
    _fetchStats();
  }

  void _loadCachedStats() {
    final cached = CacheService.getSync<Map<String, dynamic>>('cached_student_stats_v1');
    if (cached != null) {
      _applyStats(cached);
    } else {
      CacheService.get<Map<String, dynamic>>('cached_student_stats_v1').then((cachedMap) {
        if (cachedMap != null && mounted) {
          _applyStats(cachedMap);
        }
      });
    }
  }

  void _applyStats(Map<String, dynamic> data) {
    setState(() {
      _watchHours = (data['watchHours'] as num?)?.toInt() ?? _watchHours;
      _watchMinutes = (data['watchMinutes'] as num?)?.toInt() ?? _watchMinutes;
      _pendingAssignments = (data['pendingAssignments'] as num?)?.toInt() ?? _pendingAssignments;
      _notesCount = (data['notesCount'] as num?)?.toInt() ?? _notesCount;
      _doubtsAsked = (data['doubtsAsked'] as num?)?.toInt() ?? _doubtsAsked;
      _hasAnyData = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio
            .get("/api/student/watch-stats")
            .catchError((_) => Response(requestOptions: RequestOptions(path: ''))),
        dio
            .get("/api/student/assignments")
            .catchError((_) => Response(requestOptions: RequestOptions(path: ''))),
        dio
            .get("/api/student/notes")
            .catchError((_) => Response(requestOptions: RequestOptions(path: ''))),
        dio
            .get("/api/doubts")
            .catchError((_) => Response(requestOptions: RequestOptions(path: ''))),
      ]);

      if (!mounted) return;

      int wHours = 0;
      int wMins = 0;
      int pAssign = 0;
      int nC = 0;
      int dAsk = 0;

      final r1 = results[0].data;
      if (r1 is Map && r1['watchTime'] is Map) {
        wHours = r1['watchTime']['hours'] ?? 0;
        wMins = r1['watchTime']['minutes'] ?? 0;
      }

      final r2 = results[1].data;
      if (r2 is Map && r2['success'] == true && r2['assignments'] is List) {
        pAssign = (r2['assignments'] as List)
            .where((a) => a['mySubmission'] == null)
            .length;
      }

      final r3 = results[2].data;
      if (r3 is Map && r3['success'] == true && r3['notes'] is List) {
        nC = (r3['notes'] as List).length;
      }
      if (nC == 0) {
        try {
          final fb = await dio.get("/api/payments?action=notes");
          if (fb.data is Map && fb.data['notes'] is List) {
            nC = (fb.data['notes'] as List).length;
          }
        } catch (_) {}
      }

      final r4 = results[3].data;
      if (r4 is Map && r4['success'] == true && r4['doubts'] is List) {
        dAsk = (r4['doubts'] as List)
            .where((d) => d['isMyDoubt'] == true)
            .length;
      }

      setState(() {
        _watchHours = wHours;
        _watchMinutes = wMins;
        _pendingAssignments = pAssign;
        _notesCount = nC;
        _doubtsAsked = dAsk;
        _hasAnyData = true;
      });

      CacheService.set('cached_student_stats_v1', {
        'watchHours': wHours,
        'watchMinutes': wMins,
        'pendingAssignments': pAssign,
        'notesCount': nC,
        'doubtsAsked': dAsk,
      });
    } catch (_) {
      if (mounted) setState(() => _hasAnyData = true);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  Future<void> _loadDailyGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt("student_daily_goal_minutes");
      if (saved != null && saved > 0 && mounted) {
        setState(() => _dailyGoalMinutes = saved);
      }
    } catch (_) {}
  }

  Future<void> _updateDailyGoal(int minutes) async {
    setState(() => _dailyGoalMinutes = minutes);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("student_daily_goal_minutes", minutes);
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Daily study goal updated to ${_formatGoalText(minutes)}"),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatGoalText(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return "${h}h ${m}m";
    if (h > 0) return "${h}h";
    return "${m}m";
  }

  void _showGoalPickerSheet() {
    final options = [
      {"minutes": 30, "title": "30 minutes", "subtitle": "Quick daily review", "icon": "🌱"},
      {"minutes": 60, "title": "1 hour", "subtitle": "Consistent steady pace", "icon": "📚"},
      {"minutes": 120, "title": "2 hours", "subtitle": "Standard recommended goal", "icon": "⚡"},
      {"minutes": 180, "title": "3 hours", "subtitle": "Intense focused study", "icon": "🔥"},
      {"minutes": 240, "title": "4 hours", "subtitle": "Exam preparation mode", "icon": "🚀"},
      {"minutes": 360, "title": "6 hours", "subtitle": "Full immersion marathon", "icon": "🏆"},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.pillBorder,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Set Daily Study Goal",
                        style: AppTypography.h3.copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Track and pace your learning progress each day",
                        style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(LucideIcons.x, size: 18, color: AppColors.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...options.map((opt) {
                final mins = opt["minutes"] as int;
                final isSelected = mins == _dailyGoalMinutes;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AnimatedPressable(
                    pressScale: 0.98,
                    onPress: () {
                      Navigator.pop(ctx);
                      _updateDailyGoal(mins);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.indigoTint : AppColors.surfaceMuted,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(
                          color: isSelected ? AppColors.indigo : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(opt["icon"] as String, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt["title"] as String,
                                  style: AppTypography.label.copyWith(
                                    color: isSelected ? AppColors.indigo : AppColors.ink,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  opt["subtitle"] as String,
                                  style: AppTypography.caption.copyWith(
                                    color: isSelected
                                        ? AppColors.indigo.withValues(alpha: 0.7)
                                        : AppColors.inkMuted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(LucideIcons.checkCircle, size: 18, color: AppColors.indigo),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSavedTestimonials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList("user_submitted_testimonials_v1");
      if (savedList != null && savedList.isNotEmpty && mounted) {
        final List<Map<String, dynamic>> extra = [];
        for (final item in savedList) {
          try {
            final decoded = jsonDecode(item) as Map<String, dynamic>;
            extra.add(decoded);
          } catch (_) {}
        }
        if (extra.isNotEmpty) {
          setState(() {
            _testimonials.insertAll(0, extra);
          });
        }
      }
    } catch (_) {}
  }

  void _showAddReviewModal() {
    int selectedRating = 5;
    final courseController = TextEditingController(text: "JEE Aspirant");
    final reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            gradient: kGlassModalFillGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
            boxShadow: kGlassCardShadow,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: AppRadius.pillBorder,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.goldTint,
                            borderRadius: AppRadius.smBorder,
                          ),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.star, size: 18, color: AppColors.gold),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Share Your Experience",
                              style: AppTypography.h3.copyWith(fontSize: 17),
                            ),
                            Text(
                              "Help other learners on their journey",
                              style: AppTypography.caption.copyWith(
                                color: AppColors.inkMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Star Rating
                    Text(
                      "YOUR RATING",
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.inkMuted,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (idx) {
                        final star = idx + 1;
                        final isFilled = star <= selectedRating;
                        return AnimatedPressable(
                          pressScale: 0.85,
                          onPress: () => setModalState(() => selectedRating = star),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              LucideIcons.star,
                              size: 28,
                              color: isFilled ? AppColors.gold : AppColors.border,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Course / Target exam
                    Text(
                      "COURSE / TARGET EXAM",
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.inkMuted,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: courseController,
                      cursorColor: const Color(0xFF2EE6C5),
                      decoration: InputDecoration(
                        hintText: "e.g. JEE Mains 2026, NEET, Board Exam",
                        filled: true,
                        fillColor: const Color(0x14FFFFFF),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x992EE6C5), width: 1.5),
                        ),
                      ),
                      style: AppTypography.body.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 18),

                    // Review Text
                    Text(
                      "YOUR STORY / REVIEW",
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.inkMuted,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      cursorColor: const Color(0xFF2EE6C5),
                      decoration: InputDecoration(
                        hintText: "Tell other students what you love about Intense Learners...",
                        filled: true,
                        fillColor: const Color(0x14FFFFFF),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x992EE6C5), width: 1.5),
                        ),
                      ),
                      style: AppTypography.body.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    AppButton(
                      label: "Submit Story",
                      variant: AppButtonVariant.primary,
                      fullWidth: true,
                      icon: LucideIcons.send,
                      onPress: () async {
                        final text = reviewController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please write a short review before submitting.")),
                          );
                          return;
                        }

                        final user = ref.read(authProvider).user;
                        final name = user?['name'] as String? ?? "You";
                        final course = courseController.text.trim().isEmpty ? "Student" : courseController.text.trim();

                        final newStory = {
                          "name": name,
                          "role": "Student",
                          "text": text,
                          "rating": selectedRating,
                          "course": course,
                        };

                        setState(() {
                          _testimonials.insert(0, newStory);
                          _activeTestimonial = 0;
                        });
                        _startTestimonialTimer();

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("Thank you for sharing your journey! Your story is featured ⭐"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        // Persist to SharedPreferences
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final saved = prefs.getStringList("user_submitted_testimonials_v1") ?? [];
                          saved.insert(0, jsonEncode(newStory));
                          await prefs.setStringList("user_submitted_testimonials_v1", saved);
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
  }

  void _openFeature(Map<String, dynamic> feature) {
    if (feature['tab'] != null) {
      context.go(feature['tab'] as String);
    } else if (feature['special'] != null) {
      final special = feature['special'] as String;
      if (special == 'quiz') {
        context.push('/student/quiz');
      } else if (special == 'doubts') {
        context.push('/student/doubts');
      } else if (special == 'teachers') {
        context.push('/student/teachers');
      } else if (special == 'payments') {
        context.push('/student/payments');
      } else if (special == 'study-planner') {
        context.push('/student/study-planner');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${feature['title']} is coming soon")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final fullName = user?['name'] as String? ?? 'there';
    final firstName = fullName.split(' ')[0];

    final todayMinutes = _watchHours * 60 + _watchMinutes;
    final goalProgress = todayMinutes / _dailyGoalMinutes;

    final currentTestimonial = _testimonials[_activeTestimonial];

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
                // 1. Hero with Photography, Gradient & Glass Card
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          _heroPhoto,
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
                              subtitle: "Learn with intensity",
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _getGreeting().toUpperCase(),
                              style: AppTypography.label.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              firstName,
                              style: AppTypography.stat.copyWith(
                                color: AppColors.white,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x4D000000),
                                    offset: Offset(0, 2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 22),

                            // Hero Glass Card with ProgressRing & Today's Goal
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: AppRadius.lgBorder,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedPressable(
                                    pressScale: 0.94,
                                    onPress: _showGoalPickerSheet,
                                    child: ProgressRing(
                                      progress: _hasAnyData ? goalProgress : 0.0,
                                      size: 72,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AnimatedPressable(
                                          pressScale: 0.96,
                                          onPress: _showGoalPickerSheet,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "TODAY'S GOAL",
                                                    style: AppTypography.caption.copyWith(
                                                      color: Colors.white.withValues(alpha: 0.65),
                                                      fontSize: 10.5,
                                                      letterSpacing: 0.4,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Icon(
                                                    LucideIcons.pencil,
                                                    size: 10,
                                                    color: Colors.white.withValues(alpha: 0.55),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    _hasAnyData
                                                        ? "${_watchHours}h ${_watchMinutes}m"
                                                        : "—",
                                                    style: AppTypography.label.copyWith(
                                                      color: AppColors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "/ ${_formatGoalText(_dailyGoalMinutes)} watched",
                                                    style: AppTypography.caption.copyWith(
                                                      color: Colors.white.withValues(alpha: 0.55),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 6,
                                          children: [
                                            _buildMiniStat(
                                              icon: LucideIcons.clipboardCheck,
                                              value: _pendingAssignments,
                                              label: "Pending",
                                              onTap: () => context.go('/student/assignments'),
                                            ),
                                            _buildMiniStat(
                                              icon: LucideIcons.bookOpen,
                                              value: _notesCount,
                                              label: "Notes",
                                              onTap: () => context.go('/student/notes'),
                                            ),
                                            _buildMiniStat(
                                              icon: LucideIcons.messageCircleQuestion,
                                              value: _doubtsAsked,
                                              label: "Doubts",
                                              onTap: () => context.push('/student/doubts'),
                                            ),
                                          ],
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
                    ],
                  ),
                ),

                // 2. Featured Card — AI Study Planner
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 22,
                  ),
                  child: AnimatedPressable(
                    pressScale: 0.98,
                    onPress: () => context.push('/student/study-planner'),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: kGlassCardFillGradient,
                        borderRadius: AppRadius.lgBorder,
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: kGlassCardShadow,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -30,
                            right: -20,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0x332EE6C5),
                              ),
                            ),
                          ),
                          Column(
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
                                      style: AppTypography.label.copyWith(
                                        color: AppColors.white,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Your AI Study Planner",
                                style: AppTypography.h2.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "A personalized, adaptive schedule built around your goals — generated in seconds.",
                                style: AppTypography.body.copyWith(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                  height: 19 / 13,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Text(
                                    "Generate my plan",
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
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Secondary Feature Grid
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 24,
                    bottom: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "More for You",
                        style: AppTypography.h3.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 12.0;
                          final availableWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                              ? constraints.maxWidth
                              : MediaQuery.of(context).size.width - 40;
                          final tileWidth = (availableWidth - gap) / 2;

                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: _secondaryFeatures.map((feature) {
                              return SizedBox(
                                width: tileWidth,
                                child: _buildFeatureCard(feature),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 4. Testimonials Section
                Container(
                  color: Colors.transparent,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 40,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Real Success Stories",
                        style: AppTypography.h2.copyWith(
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "From students who trusted Intense Learners",
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Testimonial Card with Horizontal Swipe Gesture
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (_) {
                          _testimonialDragDistance = 0;
                        },
                        onHorizontalDragUpdate: (details) {
                          _testimonialDragDistance += details.delta.dx;
                        },
                        onHorizontalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity < -80 || _testimonialDragDistance < -30) {
                            // Swiped left -> show next comment
                            _nextTestimonial();
                          } else if (velocity > 80 || _testimonialDragDistance > 30) {
                            // Swiped right -> show previous comment
                            _prevTestimonial();
                          }
                          _testimonialDragDistance = 0;
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          transitionBuilder: (child, animation) {
                            final isCurrent = child.key == ValueKey(_activeTestimonial);
                            final offset = _slideForward
                                ? (isCurrent ? const Offset(0.25, 0) : const Offset(-0.25, 0))
                                : (isCurrent ? const Offset(-0.25, 0) : const Offset(0.25, 0));
                            return SlideTransition(
                              position: Tween<Offset>(begin: offset, end: Offset.zero).animate(
                                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                              ),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            key: ValueKey(_activeTestimonial),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: AppRadius.xlBorder,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    currentTestimonial['rating'] as int,
                                    (_) => Padding(
                                      padding: EdgeInsets.only(right: 2),
                                      child: Icon(
                                        LucideIcons.star,
                                        size: 16,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '"${currentTestimonial['text']}"',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.white,
                                    fontSize: 15,
                                    height: 23 / 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    AppAvatar(
                                      name: currentTestimonial['name'] as String,
                                      size: AppAvatarSize.md,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentTestimonial['name'] as String,
                                          style: AppTypography.label.copyWith(
                                            color: AppColors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          currentTestimonial['role'] as String,
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          currentTestimonial['course'] as String,
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.white.withValues(alpha: 0.45),
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Testimonial indicator pills with previous/next arrows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedPressable(
                            pressScale: 0.85,
                            onPress: _prevTestimonial,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.chevronLeft,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(
                            _testimonials.length,
                            (idx) {
                              final isActive = idx == _activeTestimonial;
                              return AnimatedPressable(
                                pressScale: 0.85,
                                onPress: () {
                                  setState(() {
                                    _slideForward = idx >= _activeTestimonial;
                                    _activeTestimonial = idx;
                                  });
                                  _startTestimonialTimer();
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  height: 8,
                                  width: isActive ? 28 : 8,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.white
                                        : Colors.white.withValues(alpha: 0.3),
                                    borderRadius: AppRadius.pillBorder,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          AnimatedPressable(
                            pressScale: 0.85,
                            onPress: () => _nextTestimonial(),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.chevronRight,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // "Share Your Story" Button
                      AnimatedPressable(
                        pressScale: 0.96,
                        onPress: _showAddReviewModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: AppRadius.pillBorder,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.penLine,
                                size: 13,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                "Share Your Story",
                                style: AppTypography.label.copyWith(
                                  color: AppColors.white,
                                  fontSize: 12.5,
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

                // 5. Footer
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Intense Learners",
                        style: AppTypography.label.copyWith(
                          color: AppColors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Learn with intensity",
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Contact Support Pill
                      AnimatedPressable(
                        pressScale: 0.96,
                        onPress: () => context.go('/student/contact'),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: AppRadius.lgBorder,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.indigo,
                                      borderRadius: AppRadius.smBorder,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      LucideIcons.mail,
                                      size: 16,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Need help?",
                                        style: AppTypography.label.copyWith(
                                          color: AppColors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        "Contact our support team",
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.white.withValues(alpha: 0.45),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Social Icons
                      Row(
                        children: [
                          _buildSocialButton(
                            icon: LucideIcons.globe,
                            url: "https://www.facebook.com/share/1E77DTHG5w/",
                          ),
                          const SizedBox(width: 12),
                          _buildSocialButton(
                            icon: LucideIcons.camera,
                            url: "https://www.instagram.com/intense_learners?igsh=MTVtNTV2Znd6cGVrZQ==",
                          ),
                          const SizedBox(width: 12),
                          _buildSocialButton(
                            icon: LucideIcons.playCircle,
                            url: "https://youtube.com/@intense_learners?si=PKpm1w_PnuAImiYG",
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.only(top: 20),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
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
                              "Made with care in India",
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 84),
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

  Widget _buildMiniStat({
    required IconData icon,
    required int value,
    required String label,
    VoidCallback? onTap,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 5),
        Text(
          _hasAnyData ? "$value" : "–",
          style: AppTypography.label.copyWith(
            color: AppColors.white,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return AnimatedPressable(
      pressScale: 0.92,
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: AppRadius.pillBorder,
        ),
        child: content,
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    final tone = feature['tone'] as AppBadgeTone;
    Color toneColor;
    Color toneBg;

    switch (tone) {
      case AppBadgeTone.brand:
        toneColor = AppColors.indigo;
        toneBg = AppColors.indigoTint;
        break;
      case AppBadgeTone.gold:
        toneColor = AppColors.gold;
        toneBg = AppColors.goldTint;
        break;
      case AppBadgeTone.success:
        toneColor = AppColors.mint;
        toneBg = AppColors.mintTint;
        break;
      case AppBadgeTone.danger:
        toneColor = AppColors.coral;
        toneBg = AppColors.coralTint;
        break;
      case AppBadgeTone.neutral:
        toneColor = AppColors.inkMuted;
        toneBg = AppColors.surfaceMuted;
        break;
    }

    return RepaintBoundary(
      child: AnimatedPressable(
        onPress: () => _openFeature(feature),
        pressScale: 0.98,
      child: Container(
        height: 174,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              color: toneColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: toneBg,
                            borderRadius: AppRadius.mdBorder,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            feature['icon'] as IconData,
                            size: 21,
                            color: toneColor,
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
                            height: 15 / 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppBadge(
                          label: feature['tag'] as String,
                          tone: tone,
                        ),
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
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required IconData icon, required String url}) {
    return AnimatedPressable(
      pressScale: 0.9,
      onPress: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: AppRadius.mdBorder,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 19,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
