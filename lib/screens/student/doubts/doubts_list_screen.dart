import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/doubt/ask_doubt_modal.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/ui.dart';
import '../../../models/doubt.dart';
import '../../../services/api_client.dart';
import '../../../services/cache_service.dart';
import '../../../theme/app_theme.dart';

String _formatTimeAgo(String d) {
  try {
    final dt = DateTime.parse(d).toLocal();
    final s = DateTime.now().difference(dt).inSeconds;
    if (s < 60) return "just now";
    final m = s ~/ 60;
    if (m < 60) return "${m}m ago";
    final h = m ~/ 60;
    if (h < 24) return "${h}h ago";
    final dy = h ~/ 24;
    if (dy < 7) return "${dy}d ago";
    final w = dy ~/ 7;
    if (w < 4) return "${w}w ago";
    return "${dt.day}/${dt.month}/${dt.year}";
  } catch (_) {
    return d;
  }
}

AppBadgeTone _priorityTone(String priority) {
  switch (priority.toLowerCase()) {
    case 'urgent':
      return AppBadgeTone.danger;
    case 'high':
      return AppBadgeTone.gold;
    case 'low':
      return AppBadgeTone.success;
    case 'normal':
    default:
      return AppBadgeTone.brand;
  }
}

class DoubtsListScreen extends ConsumerStatefulWidget {
  const DoubtsListScreen({super.key});

  @override
  ConsumerState<DoubtsListScreen> createState() => _DoubtsListScreenState();
}

class _DoubtsListScreenState extends ConsumerState<DoubtsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Doubt> _allDoubts = List.from(_curatedDoubts);
  bool _loading = false;
  String _searchQuery = "";
  String _filter = "all";
  bool _showAskModal = false;

  @override
  void initState() {
    super.initState();
    _loadCachedDoubts();
    _fetchDoubts();
  }

  void _loadCachedDoubts() {
    final cached = CacheService.getSync<List<dynamic>>('cached_student_doubts_v1');
    if (cached != null && cached.isNotEmpty) {
      try {
        _allDoubts = cached.map((e) => Doubt.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        _loading = false;
      } catch (e) {
        debugPrint("Error parsing cached doubts: $e");
        _allDoubts = _curatedDoubts;
        _loading = false;
      }
    } else {
      _allDoubts = _curatedDoubts;
      _loading = false;
      CacheService.get<List<dynamic>>('cached_student_doubts_v1').then((data) {
        if (data != null && data.isNotEmpty && mounted) {
          try {
            setState(() {
              _allDoubts = data.map((e) => Doubt.fromJson(Map<String, dynamic>.from(e as Map))).toList();
            });
          } catch (e) {
            debugPrint("Error parsing async cached doubts: $e");
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

  static List<Doubt> get _curatedDoubts => [
    Doubt(
      id: 'doubt-phy-101',
      title: 'How to determine direction of induced EMF using Lenz\'s Law in rotating coils?',
      description: 'When a rectangular coil rotates in a uniform magnetic field, at which angle does the induced EMF become maximum, and why does the current alternate direction every 180 degrees?',
      subject: 'Physics',
      classLevel: 'Class 12',
      priority: 'medium',
      status: 'solved',
      isSolved: true,
      upvotes: 14,
      views: 120,
      isMyDoubt: false,
      hasUpvoted: true,
      createdAt: '2026-10-12T10:30:00Z',
      student: DoubtUser(
        id: 'u-std-1',
        name: 'Aman Gupta',
        role: 'STUDENT',
      ),
      stats: DoubtStats(totalReplies: 2, totalUpvotes: 14),
      replies: [
        DoubtReply(
          id: 'rep-101',
          content: 'The induced EMF is given by e = -dPhi/dt = -d(BA cos(wt))/dt = BAw sin(wt). Thus EMF is maximum when sin(wt) = 1 (wt = 90 deg or 270 deg), meaning when the plane of the coil is parallel to the magnetic field lines. The polarity flips as the magnetic flux begins decreasing instead of increasing.',
          isPinned: true,
          isAccepted: true,
          upvotes: 9,
          createdAt: '2026-10-12T11:15:00Z',
          user: DoubtUser(
            id: 'u-tch-1',
            name: 'Prakash Jha',
            role: 'TEACHER',
          ),
          isMyReply: false,
          hasUpvoted: true,
        ),
      ],
    ),
    Doubt(
      id: 'doubt-math-102',
      title: 'Shortcut evaluation for lim x->0 of (1 + 2x)^(1/x)',
      description: 'Is it valid to directly use e^(lim x->0 2x * (1/x)) = e^2 in CBSE Board Exams, or is taking natural log on both sides required for step marks?',
      subject: 'Mathematics',
      classLevel: 'Class 12',
      priority: 'high',
      status: 'solved',
      isSolved: true,
      upvotes: 8,
      views: 95,
      isMyDoubt: false,
      hasUpvoted: false,
      createdAt: '2026-10-13T09:15:00Z',
      student: DoubtUser(
        id: 'u-std-2',
        name: 'Priya Sharma',
        role: 'STUDENT',
      ),
      stats: DoubtStats(totalReplies: 1, totalUpvotes: 8),
      replies: [
        DoubtReply(
          id: 'rep-102',
          content: 'In Board Exams, write let y = (1+2x)^(1/x), take ln(y) = (1/x)*ln(1+2x), and apply L\'Hospital\'s rule or standard limit expansion ln(1+u)/u -> 1 to secure all 3 step marks. The e^(f*g) shortcut is great for JEE Mains/Mock Tests.',
          isPinned: true,
          isAccepted: true,
          upvotes: 7,
          createdAt: '2026-10-13T10:00:00Z',
          user: DoubtUser(
            id: 'u-tch-2',
            name: 'Saqib Nadeem',
            role: 'TEACHER',
          ),
          isMyReply: false,
          hasUpvoted: false,
        ),
      ],
    ),
    Doubt(
      id: 'doubt-chem-103',
      title: 'Why does ortho-nitrophenol have lower boiling point than para-nitrophenol?',
      description: 'Both have the same chemical formula C6H5NO3, but o-nitrophenol is steam volatile. What is the molecular reason behind this difference?',
      subject: 'Chemistry',
      classLevel: 'Class 12',
      priority: 'medium',
      status: 'open',
      isSolved: false,
      upvotes: 5,
      views: 64,
      isMyDoubt: false,
      hasUpvoted: false,
      createdAt: '2026-10-14T08:00:00Z',
      student: DoubtUser(
        id: 'u-std-3',
        name: 'Rahul Verma',
        role: 'STUDENT',
      ),
      stats: DoubtStats(totalReplies: 1, totalUpvotes: 5),
      replies: [
        DoubtReply(
          id: 'rep-103',
          content: 'In ortho-nitrophenol, intramolecular hydrogen bonding occurs between the -OH and -NO2 groups in the same molecule (forming a 6-membered chelate ring). In para-nitrophenol, the groups are too far apart, leading to intermolecular hydrogen bonding with neighboring molecules, requiring much more energy to boil.',
          isPinned: false,
          isAccepted: false,
          upvotes: 4,
          createdAt: '2026-10-14T08:30:00Z',
          user: DoubtUser(
            id: 'u-tch-1',
            name: 'Prakash Jha',
            role: 'TEACHER',
          ),
          isMyReply: false,
          hasUpvoted: false,
        ),
      ],
    ),
  ];

  Future<void> _fetchDoubts() async {
    if (_allDoubts.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final dio = ref.read(dioProvider);
      List<Doubt> loaded = [];

      try {
        final response = await dio.get('/api/doubts');
        if (response.data != null && response.data['success'] == true && response.data['doubts'] is List) {
          final doubtsList = response.data['doubts'] as List;
          if (doubtsList.isNotEmpty) {
            loaded = doubtsList
                .map((e) => Doubt.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            CacheService.set('cached_student_doubts_v1', doubtsList);
          }
        }
      } catch (err) {
        debugPrint("Primary /api/doubts error: $err");
      }

      if (loaded.isEmpty && _allDoubts.isEmpty) {
        loaded = _curatedDoubts;
      }

      if (loaded.isNotEmpty && mounted) {
        setState(() {
          _allDoubts = loaded;
        });
      }
    } catch (e) {
      debugPrint("Error fetching doubts: $e");
      if (_allDoubts.isEmpty && mounted) {
        setState(() {
          _allDoubts = _curatedDoubts;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleUpvote(String doubtId) async {
    setState(() {
      _allDoubts = _allDoubts.map((d) {
        if (d.id != doubtId) return d;
        final willUpvote = !d.hasUpvoted;
        return d.copyWith(
          hasUpvoted: willUpvote,
          stats: DoubtStats(
            totalReplies: d.stats.totalReplies,
            totalUpvotes: willUpvote ? d.stats.totalUpvotes + 1 : d.stats.totalUpvotes - 1,
          ),
        );
      }).toList();
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/doubts', data: {'doubtId': doubtId, 'action': 'upvote'});
    } catch (e) {
      debugPrint("Upvote failed: $e");
      _fetchDoubts();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SafeBackScope(
        fallbackLocation: '/student/dashboard',
        child: Scaffold(
          backgroundColor: AppColors.paper,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.indigo),
                SizedBox(height: AppSpacing.md),
                Text(
                  "Loading doubts…",
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _allDoubts.where((d) {
      if (_filter == "open" && d.status != "open") return false;
      if (_filter == "solved" && d.status != "solved") return false;
      if (_filter == "myDoubts" && !d.isMyDoubt) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!d.title.toLowerCase().contains(q) && !d.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    final statChips = [
      {'icon': LucideIcons.messageSquare, 'value': _allDoubts.length, 'label': 'Total', 'accent': AppColors.indigo},
      {'icon': LucideIcons.checkCircle2, 'value': _allDoubts.where((d) => d.isSolved).length, 'label': 'Solved', 'accent': AppColors.mint},
      {'icon': LucideIcons.users, 'value': _allDoubts.where((d) => d.isMyDoubt).length, 'label': 'Mine', 'accent': AppColors.gold},
      {'icon': LucideIcons.trendingUp, 'value': _allDoubts.where((d) => !d.isSolved).length, 'label': 'Active', 'accent': AppColors.coral},
    ];

    const filters = [
      {'value': 'all', 'label': 'All'},
      {'value': 'open', 'label': 'Open'},
      {'value': 'solved', 'label': 'Solved'},
      {'value': 'myDoubts', 'label': 'My Doubts'},
    ];

    return SafeBackScope(
      fallbackLocation: '/student/dashboard',
      child: Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
                    children: [
                      // Horizontal Stat Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                        child: Row(
                          children: statChips.map((s) {
                            final accent = s['accent'] as Color;
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.only(left: 6, right: 14, top: 6, bottom: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.pillBorder,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(s['icon'] as IconData, size: 13, color: accent),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${s['value']}",
                                    style: AppTypography.stat.copyWith(fontSize: 15, color: AppColors.ink),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    s['label'] as String,
                                    style: AppTypography.body.copyWith(fontSize: 11.5, color: AppColors.inkMuted),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Search input
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: AppInput(
                          controller: _searchController,
                          placeholder: "Search doubts…",
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
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),

                      // Underline Segmented Tabs
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          margin: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
                          child: Row(
                            children: filters.map((f) {
                              final active = _filter == f['value'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 22),
                                child: AnimatedPressable(
                                  pressScale: 0.96,
                                  onPress: () => setState(() => _filter = f['value'] as String),
                                  child: Container(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: active ? AppColors.indigo : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      f['label'] as String,
                                      style: active
                                          ? AppTypography.label.copyWith(fontSize: 13, color: AppColors.indigo)
                                          : AppTypography.bodyMedium.copyWith(fontSize: 13, color: AppColors.inkMuted),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Doubts List or Empty
                      if (filtered.isEmpty)
                        _buildEmptyState()
                      else
                        ...filtered.map((doubt) => _buildDoubtCard(doubt)),
                    ],
                  ),
                ),
              ],
            ),

            if (_showAskModal)
              AskDoubtModal(
                visible: _showAskModal,
                onClose: () => setState(() => _showAskModal = false),
                onSuccess: () {
                  setState(() => _showAskModal = false);
                  _fetchDoubts();
                },
              ),
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
            onPress: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/student/dashboard');
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: AppRadius.smBorder,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.arrowLeft, size: 18, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Discussion Forum",
                  style: AppTypography.h2.copyWith(fontSize: 19, color: AppColors.ink),
                ),
                Text(
                  "Ask, answer, and help each other",
                  style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          AnimatedPressable(
            pressScale: 0.93,
            onPress: () => setState(() => _showAskModal = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.indigo,
                borderRadius: AppRadius.mdBorder,
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.plus, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    "Ask",
                    style: AppTypography.label.copyWith(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubtCard(Doubt doubt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 7),
      child: AnimatedPressable(
        pressScale: 0.98,
        onPress: () => context.push('/student/doubts/${doubt.id}', extra: doubt),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left 3px accent line
                Container(
                  width: 3.5,
                  color: doubt.isSolved ? AppColors.mint : AppColors.indigo,
                ),
                Expanded(
                  child: Padding(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title & Solved badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      doubt.title,
                                      style: AppTypography.label.copyWith(fontSize: 14, color: AppColors.ink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (doubt.isSolved) ...[
                                    const SizedBox(width: 8),
                                    const AppBadge(label: "Solved", tone: AppBadgeTone.success),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Student metadata row
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    doubt.student.name,
                                    style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                  ),
                                  Text(
                                    "•",
                                    style: AppTypography.caption.copyWith(color: AppColors.inkFaint),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.clock, size: 10, color: AppColors.inkFaint),
                                      const SizedBox(width: 3),
                                      Text(
                                        _formatTimeAgo(doubt.createdAt),
                                        style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                      ),
                                    ],
                                  ),
                                  AppBadge(label: doubt.subject, tone: AppBadgeTone.brand),
                                  AppBadge(label: doubt.priority, tone: _priorityTone(doubt.priority)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // Description snippet
                              Text(
                                doubt.description,
                                style: AppTypography.body.copyWith(
                                  fontSize: 13,
                                  color: AppColors.inkMuted,
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // Attachment chips if any
                              if (doubt.imageUrl != null || doubt.pdfUrl != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    if (doubt.imageUrl != null)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.indigoTint,
                                          borderRadius: AppRadius.smBorder,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(LucideIcons.image, size: 11, color: AppColors.indigo),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Image",
                                              style: AppTypography.bodyMedium.copyWith(fontSize: 10, color: AppColors.indigo),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (doubt.pdfUrl != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.coralTint,
                                          borderRadius: AppRadius.smBorder,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(LucideIcons.fileText, size: 11, color: AppColors.coral),
                                            const SizedBox(width: 4),
                                            Text(
                                              "PDF",
                                              style: AppTypography.bodyMedium.copyWith(fontSize: 10, color: AppColors.coral),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),

                              // Interactions (upvotes & replies)
                              Row(
                                children: [
                                  AnimatedPressable(
                                    pressScale: 0.9,
                                    onPress: () => _handleUpvote(doubt.id),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.thumbsUp,
                                          size: 13,
                                          color: doubt.hasUpvoted ? AppColors.indigo : AppColors.inkFaint,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "${doubt.stats.totalUpvotes}",
                                          style: AppTypography.label.copyWith(
                                            fontSize: 12,
                                            color: doubt.hasUpvoted ? AppColors.indigo : AppColors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.messageSquare, size: 13, color: AppColors.inkFaint),
                                      const SizedBox(width: 5),
                                      Text(
                                        "${doubt.stats.totalReplies}",
                                        style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.messageSquare, size: 30, color: AppColors.inkFaint),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            "No doubts found",
            style: AppTypography.label.copyWith(fontSize: 15, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            "Be the first to ask a question!",
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
