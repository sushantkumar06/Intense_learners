import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/cache_service.dart';
import '../../theme/app_theme.dart';
import '../../components/safe_back_scope.dart';
import '../../components/ui/ui.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  Map<String, dynamic>? _profile;
  int _watchHours = 0;
  int _watchMinutes = 0;
  int _pendingAssignments = 0;
  int _doubtsAsked = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _fetchData();
  }

  void _loadCachedProfile() {
    final cached = CacheService.getSync("cached_student_profile_v1");
    if (cached is Map) {
      if (cached['profile'] is Map) {
        _profile = Map<String, dynamic>.from(cached['profile'] as Map);
      }
      _watchHours = (cached['watchHours'] as num?)?.toInt() ?? 0;
      _watchMinutes = (cached['watchMinutes'] as num?)?.toInt() ?? 0;
      _pendingAssignments = (cached['pendingAssignments'] as num?)?.toInt() ?? 0;
      _doubtsAsked = (cached['doubtsAsked'] as num?)?.toInt() ?? 0;
    }

    if (_profile == null) {
      final userProfile = CacheService.getSync("cached_user_profile_v1");
      if (userProfile is Map) {
        _profile = Map<String, dynamic>.from(userProfile);
      }
    }

    final authUser = ref.read(authProvider).user;
    if (_profile == null && authUser != null) {
      _profile = Map<String, dynamic>.from(authUser);
    }

    if (_profile != null) {
      _loading = false;
    }
  }

  Future<void> _fetchData() async {
    final dio = ref.read(dioProvider);
    try {
      try {
        final profileRes = await dio.get('/api/user/profile');
        if (profileRes.data != null && profileRes.data is Map) {
          final pData = profileRes.data as Map;
          final userMap = pData['user'] is Map ? pData['user'] as Map : pData;
          _profile = Map<String, dynamic>.from(userMap);
        }
      } catch (err) {
        debugPrint("Error fetching profile: $err");
      }

      _profile ??= ref.read(authProvider).user != null
          ? Map<String, dynamic>.from(ref.read(authProvider).user!)
          : null;

      try {
        final statsRes = await dio.get('/api/student/watch-stats');
        if (statsRes.data != null && statsRes.data is Map) {
          final sData = statsRes.data as Map;
          final watchTime = sData['watchTime'];
          if (watchTime is Map) {
            _watchHours = (watchTime['hours'] as num?)?.toInt() ?? 0;
            _watchMinutes = (watchTime['minutes'] as num?)?.toInt() ?? 0;
          }
        }
      } catch (_) {}

      try {
        final assignmentsRes = await dio.get('/api/student/assignments');
        if (assignmentsRes.data != null && assignmentsRes.data is Map) {
          final aData = assignmentsRes.data as Map;
          if (aData['success'] == true && aData['assignments'] is List) {
            final list = aData['assignments'] as List;
            _pendingAssignments = list.where((a) => a is Map && a['mySubmission'] == null).length;
          }
        }
      } catch (_) {}

      try {
        final doubtsRes = await dio.get('/api/doubts');
        if (doubtsRes.data != null && doubtsRes.data is Map) {
          final dData = doubtsRes.data as Map;
          if (dData['success'] == true && dData['doubts'] is List) {
            final list = dData['doubts'] as List;
            _doubtsAsked = list.where((d) => d is Map && d['isMyDoubt'] == true).length;
          }
        }
      } catch (_) {}

      if (_profile != null) {
        CacheService.set("cached_student_profile_v1", {
          'profile': _profile,
          'watchHours': _watchHours,
          'watchMinutes': _watchMinutes,
          'pendingAssignments': _pendingAssignments,
          'doubtsAsked': _doubtsAsked,
        });
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error in _fetchData: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Log out?",
          style: AppTypography.h3.copyWith(fontSize: 18),
        ),
        content: Text(
          "You'll need to sign in again to access your account.",
          style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              "Cancel",
              style: AppTypography.label.copyWith(color: AppColors.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: Text(
              "Log Out",
              style: AppTypography.label.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    await context.push('/shared/edit-profile');
    if (mounted) {
      _loadCachedProfile();
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    final displayName = _profile?['name']?.toString() ??
        user?['name']?.toString() ??
        'Student';
    final email = _profile?['email']?.toString() ??
        user?['email']?.toString() ??
        '';
    final avatarUrl = _profile?['avatar']?.toString() ??
        user?['avatar']?.toString();
    final phone = _profile?['phone']?.toString();
    final location = _profile?['location']?.toString();
    final bio = _profile?['bio']?.toString();

    return SafeBackScope(
      fallbackLocation: '/student/dashboard',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchData,
            color: AppColors.indigo,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                children: [
                  // Minimal Top Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          AnimatedPressable(
                            pressScale: 0.9,
                            onPress: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/student/dashboard');
                              }
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: AppRadius.smBorder,
                              ),
                              alignment: Alignment.center,
                              child: Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.ink),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "PROFILE",
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkMuted,
                              letterSpacing: 1.2,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      AnimatedPressable(
                        pressScale: 0.9,
                        onPress: () => context.push('/shared/settings'),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: AppRadius.smBorder,
                          ),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.settings, size: 16, color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),

              // Centered Avatar Card
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  children: [
                    AnimatedPressable(
                      pressScale: 0.95,
                      onPress: _navigateToEditProfile,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.indigo,
                              border: Border.all(color: AppColors.surface, width: 3),
                            ),
                            clipBehavior: Clip.antiAlias,
                            alignment: Alignment.center,
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? Image.network(
                                    avatarUrl,
                                    width: 92,
                                    height: 92,
                                    cacheWidth: 184,
                                    cacheHeight: 184,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Text(
                                      displayName.isNotEmpty
                                          ? displayName[0].toUpperCase()
                                          : 'S',
                                      style: AppTypography.stat.copyWith(
                                        color: Colors.white,
                                        fontSize: 32,
                                      ),
                                    ),
                                  )
                                : Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : 'S',
                                    style: AppTypography.stat.copyWith(
                                      color: Colors.white,
                                      fontSize: 32,
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.indigo,
                                border: Border.all(color: AppColors.paper, width: 2.5),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.camera,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      displayName,
                      style: AppTypography.h2.copyWith(fontSize: 20, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                    ),
                    if ((phone != null && phone.isNotEmpty) ||
                        (location != null && location.isNotEmpty)) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (phone != null && phone.isNotEmpty) ...[
                            Icon(LucideIcons.phone, size: 11, color: AppColors.inkFaint),
                            const SizedBox(width: 4),
                            Text(phone, style: AppTypography.caption.copyWith(color: AppColors.inkMuted)),
                          ],
                          if (phone != null &&
                              phone.isNotEmpty &&
                              location != null &&
                              location.isNotEmpty)
                            const SizedBox(width: 14),
                          if (location != null && location.isNotEmpty) ...[
                            Icon(LucideIcons.mapPin, size: 11, color: AppColors.inkFaint),
                            const SizedBox(width: 4),
                            Text(location, style: AppTypography.caption.copyWith(color: AppColors.inkMuted)),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Stat Trio with Dividers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.lgBorder,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _StatColumn(
                        icon: LucideIcons.clock,
                        value: _loading ? "—" : "${_watchHours}h ${_watchMinutes}m",
                        label: "Watch Time",
                      ),
                      Container(width: 1, height: 36, color: AppColors.border),
                      _StatColumn(
                        icon: LucideIcons.fileWarning,
                        value: _loading ? "—" : "$_pendingAssignments",
                        label: "Pending",
                      ),
                      Container(width: 1, height: 36, color: AppColors.border),
                      _StatColumn(
                        icon: LucideIcons.messageCircleQuestion,
                        value: _loading ? "—" : "$_doubtsAsked",
                        label: "Doubts Asked",
                      ),
                    ],
                  ),
                ),
              ),

              // Bio quote
              if (bio != null && bio.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, AppSpacing.lg, 20, 0),
                  child: Text(
                    "\"$bio\"",
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              // iOS-Style Menu Sections
              _MenuSection(
                title: "Account",
                children: [
                  _MenuRow(
                    icon: LucideIcons.userCog,
                    label: "Edit Profile",
                    onPress: _navigateToEditProfile,
                  ),
                  _MenuRow(
                    icon: LucideIcons.settings,
                    label: "Settings",
                    onPress: () => context.push('/shared/settings'),
                    last: true,
                  ),
                ],
              ),

              _MenuSection(
                title: "Academics",
                children: [
                  _MenuRow(
                    icon: LucideIcons.calendarDays,
                    label: "Study Planner",
                    onPress: () => context.push('/student/study-planner'),
                  ),
                  _MenuRow(
                    icon: LucideIcons.wallet,
                    label: "Payments & Fees",
                    onPress: () => context.push('/student/payments'),
                  ),
                  _MenuRow(
                    icon: LucideIcons.users,
                    label: "Find Teachers",
                    onPress: () => context.push('/student/teachers'),
                    last: true,
                  ),
                ],
              ),

              _MenuSection(
                title: "Support",
                children: [
                  _MenuRow(
                    icon: LucideIcons.helpCircle,
                    label: "Contact & Help",
                    onPress: () => context.push('/student/contact'),
                  ),
                  _MenuRow(
                    icon: LucideIcons.shieldCheck,
                    label: "Legal & Policies",
                    onPress: () => context.push('/shared/legal'),
                    last: true,
                  ),
                ],
              ),

              // Logout Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, AppSpacing.lg, 20, 0),
                child: AnimatedPressable(
                  pressScale: 0.97,
                  onPress: _handleLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.coralTint,
                      borderRadius: AppRadius.mdBorder,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.logOut, size: 16, color: AppColors.coral),
                        const SizedBox(width: 8),
                        Text(
                          "Log Out",
                          style: AppTypography.label.copyWith(
                            fontSize: 13.5,
                            color: AppColors.coral,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Text(
                "${user?['role'] == 'STUDENT' ? 'Student' : (user?['role'] ?? 'User')} Account",
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkFaint,
                  fontSize: 10.5,
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

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.indigo),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.h3.copyWith(fontSize: 14, color: AppColors.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _MenuSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, AppSpacing.lg, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
            child: Text(
              title.toUpperCase(),
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkFaint,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPress;
  final bool last;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onPress,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      pressScale: 0.98,
      onPress: onPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 13),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.indigoTint,
                borderRadius: AppRadius.smBorder,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: AppColors.indigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(fontSize: 13.5, color: AppColors.ink),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
