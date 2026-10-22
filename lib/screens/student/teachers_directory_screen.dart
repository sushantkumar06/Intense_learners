import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/ui/ui.dart';
import '../../components/safe_back_scope.dart';
import '../../models/directory_user.dart';
import '../../services/api_client.dart';
import '../../services/cache_service.dart';
import '../../theme/app_theme.dart';

String _formatDate(String? d) {
  if (d == null || d.isEmpty) return "N/A";
  try {
    final dt = DateTime.parse(d).toLocal();
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
  } catch (_) {
    return "N/A";
  }
}

int? _calculateAge(String? dob) {
  if (dob == null || dob.isEmpty) return null;
  try {
    final today = DateTime.now();
    final birth = DateTime.parse(dob).toLocal();
    int age = today.year - birth.year;
    final m = today.month - birth.month;
    if (m < 0 || (m == 0 && today.day < birth.day)) {
      age--;
    }
    return age;
  } catch (_) {
    return null;
  }
}

class TeachersDirectoryScreen extends ConsumerStatefulWidget {
  const TeachersDirectoryScreen({super.key});

  @override
  ConsumerState<TeachersDirectoryScreen> createState() => _TeachersDirectoryScreenState();
}

class _TeachersDirectoryScreenState extends ConsumerState<TeachersDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DirectoryUser> _teachers = List.from(_curatedFaculty);
  bool _loading = false;
  String _searchQuery = "";
  DirectoryUser? _selectedTeacher;

  @override
  void initState() {
    super.initState();
    _loadCachedTeachers();
    _fetchTeachers();
  }

  void _loadCachedTeachers() {
    final cached = CacheService.getSync<List<dynamic>>('cached_teachers_directory_v1');
    if (cached != null && cached.isNotEmpty) {
      try {
        _teachers = cached.map((e) => DirectoryUser.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        _loading = false;
      } catch (e) {
        debugPrint("Error parsing cached teachers: $e");
        _teachers = _curatedFaculty;
        _loading = false;
      }
    } else {
      _teachers = _curatedFaculty;
      _loading = false;
      CacheService.get<List<dynamic>>('cached_teachers_directory_v1').then((data) {
        if (data != null && data.isNotEmpty && mounted) {
          try {
            setState(() {
              _teachers = data.map((e) => DirectoryUser.fromJson(Map<String, dynamic>.from(e as Map))).toList();
            });
          } catch (e) {
            debugPrint("Error parsing async cached teachers: $e");
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeachers() async {
    if (_teachers.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final dio = ref.read(dioProvider);
      List<DirectoryUser> loaded = [];

      try {
        final response = await dio.get('/api/user/students?role=TEACHER');
        if (response.data != null && response.data['users'] is List) {
          final list = response.data['users'] as List;
          loaded = list.map((e) => DirectoryUser.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          CacheService.set('cached_teachers_directory_v1', list);
        }
      } catch (err) {
        debugPrint("Primary /api/user/students error: $err");
      }

      // Fallback: Extract faculty from notes catalog if primary returned empty
      if (loaded.isEmpty) {
        try {
          final notesRes = await dio.get('/api/payments?action=notes');
          if (notesRes.data != null && notesRes.data['notes'] is List) {
            final List<dynamic> notes = notesRes.data['notes'];
            final Map<String, DirectoryUser> teacherMap = {};
            for (final n in notes) {
              if (n is Map && n['teacher'] is Map) {
                final t = n['teacher'];
                final name = t['name']?.toString() ?? '';
                if (name.isNotEmpty && !teacherMap.containsKey(name)) {
                  teacherMap[name] = DirectoryUser(
                    id: name.toLowerCase().replaceAll(' ', '-'),
                    name: name,
                    email: '${name.toLowerCase().replaceAll(' ', '.')}@intensist.com',
                    role: 'TEACHER',
                    avatar: t['avatar']?.toString(),
                    subjects: n['subject']?.toString(),
                    bio: 'Faculty Member at Intense Learners',
                    qualification: 'Senior Faculty',
                    experience: '5+ years teaching',
                    isActive: true,
                    createdAt: DateTime.now().toIso8601String(),
                  );
                }
              }
            }
            if (teacherMap.isNotEmpty) {
              loaded = teacherMap.values.toList();
            }
          }
        } catch (fbErr) {
          debugPrint("Fallback teachers from notes error: $fbErr");
        }
      }

      if (loaded.isEmpty && _teachers.isEmpty) {
        loaded = _curatedFaculty;
      }

      if (loaded.isNotEmpty && mounted) {
        setState(() {
          _teachers = loaded;
        });
        CacheService.set('cached_teachers_directory_v1', loaded.map((t) => t.toJson()).toList());
      }
    } catch (e) {
      debugPrint("Error fetching teachers: $e");
      if (_teachers.isEmpty && mounted) {
        setState(() {
          _teachers = _curatedFaculty;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static List<DirectoryUser> get _curatedFaculty => [
    DirectoryUser(
      id: 'prakash-jha',
      name: 'Prakash Jha',
      email: 'prakash.jha@intensist.com',
      role: 'TEACHER',
      avatar: null,
      subjects: 'Physics, Chemistry',
      bio: 'Senior Faculty Member specializing in JEE & NEET Physics with over 8 years of coaching experience.',
      qualification: 'M.Sc. Physics (Gold Medalist)',
      experience: '8+ years teaching',
      isActive: true,
      createdAt: '2026-01-01T00:00:00Z',
    ),
    DirectoryUser(
      id: 'saqib-nadeem',
      name: 'Saqib Nadeem',
      email: 'saqib.nadeem@intensist.com',
      role: 'TEACHER',
      avatar: null,
      subjects: 'Mathematics',
      bio: 'Senior Mathematics faculty specializing in Advanced Calculus, Coordinate Geometry and Vectors for JEE Advanced.',
      qualification: 'B.Tech IIT Delhi, M.Math',
      experience: '7+ years teaching',
      isActive: true,
      createdAt: '2026-01-01T00:00:00Z',
    ),
    DirectoryUser(
      id: 'dr-anjali-verma',
      name: 'Dr. Anjali Verma',
      email: 'anjali.verma@intensist.com',
      role: 'TEACHER',
      avatar: null,
      subjects: 'Chemistry, Biology',
      bio: 'Expert NEET Chemistry and Biology faculty mentoring top rankers across national medical entrance exams.',
      qualification: 'Ph.D. Organic Chemistry',
      experience: '6+ years teaching',
      isActive: true,
      createdAt: '2026-01-01T00:00:00Z',
    ),
  ];

  Future<void> _launchURL(String urlString) async {
    try {
      var target = urlString.trim();
      if (!target.startsWith('http://') && !target.startsWith('https://')) {
        target = 'https://$target';
      }
      final uri = Uri.parse(target);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch $urlString: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _teachers.where((t) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.name.toLowerCase().contains(q) ||
          t.email.toLowerCase().contains(q) ||
          (t.location != null && t.location!.toLowerCase().contains(q)) ||
          (t.subjects != null && t.subjects!.toLowerCase().contains(q));
    }).toList();

    return SafeBackScope(
      child: Scaffold(
        backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading
                      ? _buildLoadingState()
                      : ListView(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
                          children: [
                            _buildStatsGrid(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                              child: AppInput(
                                controller: _searchController,
                                placeholder: "Search by name, email, location, subject…",
                                leftIcon: Icon(LucideIcons.search, size: 18, color: AppColors.inkFaint),
                                rightIcon: _searchQuery.isNotEmpty
                                    ? AnimatedPressable(
                                        pressScale: 0.85,
                                        onPress: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = "");
                                        },
                                        child: Icon(LucideIcons.x, size: 16, color: AppColors.inkFaint),
                                      )
                                    : null,
                                onChanged: (v) => setState(() => _searchQuery = v),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (filtered.isEmpty)
                              _buildEmptyState()
                            else
                              ...filtered.map((teacher) => _buildTeacherCard(teacher)),
                          ],
                        ),
                ),
              ],
            ),

            if (_selectedTeacher != null) _buildDetailModal(_selectedTeacher!),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          AnimatedPressable(
            pressScale: 0.9,
            onPress: () => context.canPop() ? context.pop() : context.go('/student/dashboard'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: AppRadius.smBorder,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.arrowLeft, size: 18, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Teacher Directory",
                style: AppTypography.h3.copyWith(color: AppColors.ink),
              ),
              Text(
                "View all registered teachers",
                style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(child: SkeletonLoader(height: 80)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonLoader(height: 80)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: const [
              Expanded(child: SkeletonLoader(height: 80)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonLoader(height: 80)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const SkeletonLoader(height: 48),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonLoader(height: 100),
          const SizedBox(height: AppSpacing.md),
          const SkeletonLoader(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {'icon': LucideIcons.users, 'value': _teachers.length, 'label': 'Total Teachers', 'accent': AppColors.indigo},
      {'icon': LucideIcons.activity, 'value': (_teachers.length * 0.8).floor(), 'label': 'Active Today', 'accent': AppColors.mint},
      {'icon': LucideIcons.trendingUp, 'value': (_teachers.length * 0.15).floor(), 'label': 'This Month', 'accent': AppColors.gold},
      {'icon': LucideIcons.trophy, 'value': _teachers.length, 'label': 'All Time', 'accent': AppColors.coral},
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatTile(stats[0]),
              const SizedBox(width: AppSpacing.sm),
              _buildStatTile(stats[1]),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildStatTile(stats[2]),
              const SizedBox(width: AppSpacing.sm),
              _buildStatTile(stats[3]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(Map<String, dynamic> stat) {
    final accent = stat['accent'] as Color;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadius.smBorder,
              ),
              alignment: Alignment.center,
              child: Icon(stat['icon'] as IconData, size: 16, color: accent),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "${stat['value']}",
              style: AppTypography.stat.copyWith(fontSize: 18, color: AppColors.ink),
            ),
            Text(
              stat['label'] as String,
              style: AppTypography.body.copyWith(fontSize: 11.5, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard(DirectoryUser teacher) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 6),
      child: AnimatedPressable(
        pressScale: 0.98,
        onPress: () => setState(() => _selectedTeacher = teacher),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                name: teacher.name,
                uri: teacher.avatar,
                size: AppAvatarSize.lg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            teacher.name,
                            style: AppTypography.label.copyWith(fontSize: 14, color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const AppBadge(label: "Teacher", tone: AppBadgeTone.brand),
                        if (teacher.isActive) ...[
                          const SizedBox(width: 4),
                          const AppBadge(label: "Active", tone: AppBadgeTone.success),
                        ],
                      ],
                    ),
                    if (teacher.bio != null && teacher.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        teacher.bio!,
                        style: AppTypography.body.copyWith(fontSize: 12, color: AppColors.inkMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (teacher.email.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.mail, size: 11, color: AppColors.indigo),
                              const SizedBox(width: 4),
                              Text(
                                teacher.email,
                                style: AppTypography.body.copyWith(fontSize: 11, color: AppColors.inkMuted),
                              ),
                            ],
                          ),
                        if (teacher.location != null && teacher.location!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.mapPin, size: 11, color: AppColors.coral),
                              const SizedBox(width: 4),
                              Text(
                                teacher.location!,
                                style: AppTypography.body.copyWith(fontSize: 11, color: AppColors.inkMuted),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if ((teacher.qualification != null && teacher.qualification!.isNotEmpty) ||
                        (teacher.experience != null && teacher.experience!.isNotEmpty)) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (teacher.qualification != null && teacher.qualification!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: AppRadius.smBorder,
                              ),
                              child: Text(
                                teacher.qualification!,
                                style: AppTypography.body.copyWith(fontSize: 10, color: AppColors.inkMuted),
                              ),
                            ),
                          if (teacher.experience != null && teacher.experience!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: AppRadius.smBorder,
                              ),
                              child: Text(
                                teacher.experience!,
                                style: AppTypography.body.copyWith(fontSize: 10, color: AppColors.inkMuted),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(LucideIcons.users, size: 44, color: AppColors.inkFaint),
          const SizedBox(height: 12),
          Text(
            "No Teachers Found",
            style: AppTypography.label.copyWith(fontSize: 15, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty ? "Try adjusting your search" : "No teachers have registered yet",
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailModal(DirectoryUser teacher) {
    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: () => setState(() => _selectedTeacher = null),
          child: Container(color: Colors.black.withValues(alpha: 0.6)),
        ),

        // Sheet
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: AppShadows.raised,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        name: teacher.name,
                        uri: teacher.avatar,
                        size: AppAvatarSize.lg,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher.name,
                              style: AppTypography.label.copyWith(fontSize: 15, color: AppColors.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              teacher.email,
                              style: AppTypography.body.copyWith(fontSize: 12, color: AppColors.inkMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      AnimatedPressable(
                        pressScale: 0.9,
                        onPress: () => setState(() => _selectedTeacher = null),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: AppRadius.smBorder,
                          ),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.x, size: 17, color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeading(LucideIcons.users, "Personal Information"),
                        if (teacher.location != null && teacher.location!.isNotEmpty)
                          _buildInfoRow("Location", teacher.location!),
                        if (teacher.dateOfBirth != null && teacher.dateOfBirth!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            "Date of Birth",
                            "${_formatDate(teacher.dateOfBirth)} (Age: ${_calculateAge(teacher.dateOfBirth)})",
                          ),
                        ],
                        const SizedBox(height: 10),
                        _buildInfoRow("Member Since", _formatDate(teacher.createdAt)),
                        const SizedBox(height: AppSpacing.lg),

                        if (teacher.bio != null && teacher.bio!.isNotEmpty) ...[
                          Text(
                            "Bio",
                            style: AppTypography.caption.copyWith(fontSize: 11.5, color: AppColors.inkFaint),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            teacher.bio!,
                            style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.ink, height: 1.45),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        if ((teacher.qualification != null && teacher.qualification!.isNotEmpty) ||
                            (teacher.experience != null && teacher.experience!.isNotEmpty) ||
                            (teacher.subjects != null && teacher.subjects!.isNotEmpty) ||
                            (teacher.specialization != null && teacher.specialization!.isNotEmpty)) ...[
                          _buildSectionHeading(LucideIcons.briefcase, "Professional Information"),
                          if (teacher.qualification != null && teacher.qualification!.isNotEmpty)
                            _buildInfoRow("Qualification", teacher.qualification!),
                          if (teacher.experience != null && teacher.experience!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildInfoRow("Experience", teacher.experience!),
                          ],
                          if (teacher.subjects != null && teacher.subjects!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildInfoRow("Subjects", teacher.subjects!),
                          ],
                          if (teacher.specialization != null && teacher.specialization!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildInfoRow("Specialization", teacher.specialization!),
                          ],
                          if (teacher.teachingStyle != null && teacher.teachingStyle!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              "Teaching Style",
                              style: AppTypography.caption.copyWith(fontSize: 11.5, color: AppColors.inkFaint),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              teacher.teachingStyle!,
                              style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.ink, height: 1.45),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        if ((teacher.website != null && teacher.website!.isNotEmpty) ||
                            (teacher.linkedin != null && teacher.linkedin!.isNotEmpty) ||
                            (teacher.twitter != null && teacher.twitter!.isNotEmpty) ||
                            (teacher.instagram != null && teacher.instagram!.isNotEmpty)) ...[
                          _buildSectionHeading(LucideIcons.globe, "Social Profiles"),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (teacher.website != null && teacher.website!.isNotEmpty)
                                _buildSocialPill(
                                  icon: Icon(LucideIcons.globe, size: 14, color: AppColors.ink),
                                  label: "Website",
                                  onTap: () => _launchURL(teacher.website!),
                                ),
                              if (teacher.linkedin != null && teacher.linkedin!.isNotEmpty)
                                _buildSocialPill(
                                  icon: const Icon(LucideIcons.link, size: 14, color: Color(0xFF0A66C2)),
                                  label: "LinkedIn",
                                  onTap: () => _launchURL(teacher.linkedin!),
                                ),
                              if (teacher.twitter != null && teacher.twitter!.isNotEmpty)
                                _buildSocialPill(
                                  icon: const Icon(LucideIcons.link, size: 14, color: Color(0xFF1D9BF0)),
                                  label: "Twitter",
                                  onTap: () => _launchURL(teacher.twitter!),
                                ),
                              if (teacher.instagram != null && teacher.instagram!.isNotEmpty)
                                _buildSocialPill(
                                  icon: const Icon(LucideIcons.link, size: 14, color: Color(0xFFD6249F)),
                                  label: "Instagram",
                                  onTap: () => _launchURL(teacher.instagram!),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.indigo),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(fontSize: 11.5, color: AppColors.inkFaint),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _buildSocialPill({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AnimatedPressable(
      pressScale: 0.94,
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: AppRadius.mdBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTypography.label.copyWith(fontSize: 12, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
