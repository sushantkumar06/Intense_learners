import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/directory_user.dart';
import '../../../services/api_client.dart';
import '../../../services/cache_service.dart';
import '../../../theme/app_theme.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/app_badge.dart';
import '../../../components/ui/app_input.dart';
import '../../../components/ui/app_avatar.dart';
import '../../../components/ui/animated_pressable.dart';
import '../../../components/ui/progress_ring.dart';
import '../../../components/ui/stat_primitives.dart';

const String _kHeroPhoto =
    "https://images.unsplash.com/photo-1571260899304-425eee4c7efc?w=1200&q=80&auto=format&fit=crop";

enum _StudentFilter { all, active, newThisMonth, incomplete }

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

final List<DirectoryUser> _curatedStudents = [
  DirectoryUser(
    id: "student-curated-1",
    name: "Aarav Sharma",
    email: "aarav.sharma@example.com",
    role: "STUDENT",
    avatar:
        "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&q=80",
    phone: "+91 98765 43210",
    bio:
        "Passionate about political science, international relations, and constitutional law.",
    location: "New Delhi, India",
    dateOfBirth: "2006-04-15",
    qualification: "Class 12th Humanities",
    experience: "Student",
    subjects: "Political Science, History, Economics",
    isActive: true,
    createdAt:
        DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
  ),
  DirectoryUser(
    id: "student-curated-2",
    name: "Priya Patel",
    email: "priya.patel@example.com",
    role: "STUDENT",
    avatar:
        "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80",
    phone: "+91 98123 45678",
    bio: "History enthusiast preparing for civil services exams.",
    location: "Ahmedabad, India",
    dateOfBirth: "2006-08-22",
    qualification: "Class 12th Humanities",
    experience: "Student",
    subjects: "History, Political Science, English",
    isActive: true,
    createdAt:
        DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
  ),
  DirectoryUser(
    id: "student-curated-3",
    name: "Rohan Verma",
    email: "rohan.verma@example.com",
    role: "STUDENT",
    avatar:
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80",
    phone: "+91 97234 56789",
    bio: "Focusing on board exams and competitive entrance tests.",
    location: "Lucknow, India",
    dateOfBirth: "2007-01-10",
    qualification: "Class 12th",
    experience: "Student",
    subjects: "Political Science, History",
    isActive: true,
    createdAt:
        DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
  ),
];

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  List<DirectoryUser> _students = List.from(_curatedStudents);
  bool _loading = false;
  String _searchQuery = "";
  _StudentFilter _filter = _StudentFilter.all;

  @override
  void initState() {
    super.initState();
    _loadCachedStudents();
    _fetchStudents();
  }

  void _loadCachedStudents() {
    final cached =
        CacheService.getSync<List<dynamic>>('cached_teacher_students_v1');
    if (cached != null && cached.isNotEmpty) {
      final valid = cached
          .whereType<Map>()
          .map((n) => DirectoryUser.fromJson(n))
          .toList();
      if (valid.isNotEmpty) {
        _students = valid;
        _loading = false;
        return;
      }
    }
    CacheService.get<List<dynamic>>('cached_teacher_students_v1').then((data) {
      if (data != null && data.isNotEmpty && mounted) {
        final valid = data
            .whereType<Map>()
            .map((n) => DirectoryUser.fromJson(n))
            .toList();
        if (valid.isNotEmpty) {
          setState(() {
            _students = valid;
            _loading = false;
          });
        }
      }
    });
  }

  Future<void> _fetchStudents([bool isRefresh = false]) async {
    if (!isRefresh && _students.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final response =
          await ref.read(dioProvider).get("/api/user/students?role=STUDENT");
      final data = response.data;
      if (data is Map && data['users'] is List) {
        final usersList = (data['users'] as List).whereType<Map>().toList();
        if (usersList.isNotEmpty) {
          if (mounted) {
            setState(() {
              _students = usersList
                  .map((n) => DirectoryUser.fromJson(n))
                  .toList();
            });
          }
          CacheService.set('cached_teacher_students_v1', usersList);
        }
      }
    } catch (e) {
      debugPrint("Error fetching students: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return "N/A";
    try {
      final date = DateTime.parse(d);
      const months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (_) {
      return "N/A";
    }
  }

  int? _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    try {
      final birth = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  bool _isNewThisMonth(String createdAt) {
    try {
      final d = DateTime.parse(createdAt);
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month;
    } catch (_) {
      return false;
    }
  }

  bool _isNewThisWeek(String createdAt) {
    try {
      final d = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(d).inDays;
      return diff <= 7;
    } catch (_) {
      return false;
    }
  }

  bool _hasCompleteProfile(DirectoryUser s) {
    return (s.phone != null && s.phone!.isNotEmpty) &&
        (s.location != null && s.location!.isNotEmpty) &&
        (s.bio != null && s.bio!.isNotEmpty);
  }

  void _showStudentProfileModal(DirectoryUser student) {
    final age = _calculateAge(student.dateOfBirth);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Profile Header Card
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: kGlassCardFillGradient,
                borderRadius: AppRadius.lgBorder,
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: kGlassCardShadow,
              ),
              child: Row(
                children: [
                  AppAvatar(
                    name: student.name,
                    uri: student.avatar,
                    size: AppAvatarSize.lg,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: AppTypography.label.copyWith(
                            fontSize: 16,
                            color: AppColors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          student.email,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedPressable(
                    pressScale: 0.9,
                    onPress: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details scroll
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.userCheck,
                          size: 16,
                          color: AppColors.indigo,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Personal Information",
                          style: AppTypography.label.copyWith(
                            fontSize: 13.5,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Info Tiles Grid
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (student.phone != null &&
                            student.phone!.isNotEmpty)
                          _buildInfoTile(
                            LucideIcons.phone,
                            "Phone",
                            student.phone!,
                          ),
                        if (student.location != null &&
                            student.location!.isNotEmpty)
                          _buildInfoTile(
                            LucideIcons.mapPin,
                            "Location",
                            student.location!,
                          ),
                        if (student.dateOfBirth != null &&
                            student.dateOfBirth!.isNotEmpty)
                          _buildInfoTile(
                            LucideIcons.calendar,
                            "Date of Birth",
                            "${_formatDate(student.dateOfBirth)}${age != null ? " ($age y)" : ""}",
                          ),
                        _buildInfoTile(
                          LucideIcons.calendar,
                          "Member Since",
                          _formatDate(student.createdAt),
                        ),
                      ],
                    ),

                    if (student.bio != null && student.bio!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        "Bio",
                        style: AppTypography.label.copyWith(
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        student.bio!,
                        style: AppTypography.body.copyWith(
                          fontSize: 13,
                          color: AppColors.ink,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    final width = (MediaQuery.of(context).size.width - 40 - 12) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.mdBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.indigo),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.label.copyWith(
              fontSize: 12.5,
              color: AppColors.ink,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _students.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.indigo),
        ),
      );
    }

    final activeCount = _students.where((s) => s.isActive).length;
    final newThisMonth =
        _students.where((s) => _isNewThisMonth(s.createdAt)).length;
    final completeProfiles = _students.where(_hasCompleteProfile).length;
    final activeRatio = _students.isNotEmpty
        ? (activeCount / _students.length).clamp(0.0, 1.0)
        : 0.0;

    final filtered = _students.where((s) {
      if (_filter == _StudentFilter.active && !s.isActive) return false;
      if (_filter == _StudentFilter.newThisMonth &&
          !_isNewThisMonth(s.createdAt)) {
        return false;
      }
      if (_filter == _StudentFilter.incomplete && _hasCompleteProfile(s)) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = s.name.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q) ||
            (s.location?.toLowerCase().contains(q) ?? false) ||
            (s.phone?.toLowerCase().contains(q) ?? false);
        if (!matches) return false;
      }
      return true;
    }).toList();

    final filterTabs = [
      {'val': _StudentFilter.all, 'label': 'All'},
      {'val': _StudentFilter.active, 'label': 'Active'},
      {'val': _StudentFilter.newThisMonth, 'label': 'New This Month'},
      {'val': _StudentFilter.incomplete, 'label': 'Incomplete'},
    ];

    return SafeBackScope(
      fallbackLocation: '/teacher',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: AppColors.indigo,
            onRefresh: () => _fetchStudents(true),
            child: CustomScrollView(
              slivers: [
                // Cinematic Hero Banner
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                    Color(0x991B2C5C),
                                    Color(0xCC1B2C5C),
                                    Color(0xF2101831),
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
                                                  "Student Directory",
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
                                            "My Students",
                                            style: AppTypography.h1.copyWith(
                                              fontSize: 26,
                                              color: AppColors.white,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.3),
                                                  offset: const Offset(0, 2),
                                                  blurRadius: 6,
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

                                // Glass Engagement Panel
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
                                      padding:
                                          const EdgeInsets.all(AppSpacing.lg),
                                      child: Row(
                                        children: [
                                          ProgressRing(
                                            progress: activeRatio,
                                            label: "ACTIVE",
                                          ),
                                          const SizedBox(
                                              width: AppSpacing.lg),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "ENGAGEMENT SNAPSHOT",
                                                  style: AppTypography
                                                      .caption
                                                      .copyWith(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.65),
                                                    fontWeight:
                                                        FontWeight.w600,
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
                                                        LucideIcons.users,
                                                        size: 12,
                                                        color: Colors.white70,
                                                      ),
                                                      value: _students.length,
                                                      label: "total",
                                                    ),
                                                    MiniStat(
                                                      icon: const Icon(
                                                        LucideIcons.trophy,
                                                        size: 12,
                                                        color: Colors.white70,
                                                      ),
                                                      value: newThisMonth,
                                                      label: "new",
                                                    ),
                                                    MiniStat(
                                                      icon: const Icon(
                                                        LucideIcons
                                                            .clipboardList,
                                                        size: 12,
                                                        color: Colors.white70,
                                                      ),
                                                      value: completeProfiles,
                                                      label: "complete",
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
                          AppInput(
                            placeholder:
                                "Search by name, email, phone, location…",
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                            leftIcon: Icon(
                              LucideIcons.search,
                              size: 16,
                              color: AppColors.inkFaint,
                            ),
                            rightIcon: _searchQuery.isNotEmpty
                                ? AnimatedPressable(
                                    pressScale: 0.85,
                                    onPress: () =>
                                        setState(() => _searchQuery = ""),
                                    child: Icon(
                                      LucideIcons.x,
                                      size: 14,
                                      color: AppColors.inkFaint,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: filterTabs.map((t) {
                                final active = _filter == t['val'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: AnimatedPressable(
                                    pressScale: 0.95,
                                    onPress: () => setState(
                                      () => _filter =
                                          t['val'] as _StudentFilter,
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
                                        t['label'] as String,
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

                          Text(
                            "Showing ${filtered.length} of ${_students.length} students",
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

              // Student List
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
                            LucideIcons.users,
                            size: 32,
                            color: AppColors.indigo,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          "No students found",
                          style: AppTypography.label.copyWith(
                            color: AppColors.ink,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isNotEmpty
                              ? "Try adjusting your search"
                              : "No students have enrolled yet",
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
                  padding: const EdgeInsets.only(top: 10, bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final student = filtered[index];
                        final isNew = _isNewThisWeek(student.createdAt);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: AnimatedPressable(
                            pressScale: 0.98,
                            onPress: () =>
                                _showStudentProfileModal(student),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.lgBorder,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      AppAvatar(
                                        name: student.name,
                                        uri: student.avatar,
                                        size: AppAvatarSize.md,
                                      ),
                                      if (student.isActive)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: AppColors.mint,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.surface,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              student.name,
                                              style: AppTypography.label
                                                  .copyWith(
                                                color: AppColors.ink,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (isNew)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.goldTint,
                                                  borderRadius:
                                                      AppRadius.pillBorder,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      LucideIcons.sparkles,
                                                      size: 9,
                                                      color: AppColors.gold,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      "New",
                                                      style: AppTypography
                                                          .caption
                                                          .copyWith(
                                                        color: AppColors.gold,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 9,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (student.isActive)
                                              const AppBadge(
                                                label: "Active",
                                                tone: AppBadgeTone.success,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(
                                              LucideIcons.mail,
                                              size: 11,
                                              color: AppColors.inkFaint,
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                student.email,
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  color: AppColors.inkMuted,
                                                  fontSize: 11.5,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Joined ${_formatDate(student.createdAt)}",
                                          style:
                                              AppTypography.caption.copyWith(
                                            color: AppColors.inkFaint,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 8,
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
                                ],
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
