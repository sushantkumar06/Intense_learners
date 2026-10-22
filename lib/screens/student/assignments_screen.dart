import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../models/assignment.dart';
import '../../services/api_client.dart';
import '../../services/cache_service.dart';
import '../../theme/app_theme.dart';
import '../../components/ui/ui.dart';
import '../../components/assignments/assignment_card.dart';
import '../../components/assignments/submit_assignment_modal.dart';
import '../../components/assignments/comments_modal.dart';

const String _heroPhoto =
    "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&q=80&auto=format&fit=crop";

enum _AssignmentFilter { all, pending, submitted }

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  List<StudentAssignment> _allAssignments = List.from(_curatedAssignments);
  bool _loading = false;

  String _searchQuery = "";
  final _searchController = TextEditingController();
  _AssignmentFilter _filter = _AssignmentFilter.all;
  String _selectedSubject = "all";

  @override
  void initState() {
    super.initState();
    _loadCachedAssignments();
    _fetchAssignments();
  }

  void _loadCachedAssignments() {
    final cached = CacheService.getSync<List<dynamic>>('cached_student_assignments_v1');
    if (cached != null && cached.isNotEmpty) {
      try {
        _allAssignments = cached.map((e) => StudentAssignment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        _loading = false;
      } catch (e) {
        debugPrint("Error parsing cached assignments: $e");
        _allAssignments = _curatedAssignments;
        _loading = false;
      }
    } else {
      _allAssignments = _curatedAssignments;
      _loading = false;
      CacheService.get<List<dynamic>>('cached_student_assignments_v1').then((data) {
        if (data != null && data.isNotEmpty && mounted) {
          try {
            setState(() {
              _allAssignments = data.map((e) => StudentAssignment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
            });
          } catch (e) {
            debugPrint("Error parsing async cached assignments: $e");
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

  static List<StudentAssignment> get _curatedAssignments => [
    StudentAssignment(
      id: 'asgn-phy-101',
      title: 'NCERT Electrostatics Problem Set',
      description: 'Solve questions 1.1 to 1.15 from Chapter 1. Pay special attention to vector superposition of Coulomb forces.',
      subject: 'Physics',
      className: 'Class 12',
      dueDate: DateTime.now().add(const Duration(days: 4)),
      totalMarks: 50,
      fileName: 'Electrostatics_Problem_Set.pdf',
      fileSize: '1.4 MB',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      teacher: {
        'name': 'Prakash Jha',
        'avatar': null,
      },
      mySubmission: null,
      stats: {'totalSubmissions': 18, 'totalComments': 3},
    ),
    StudentAssignment(
      id: 'asgn-math-102',
      title: 'Definite Integrals & Area Under Curve Practice',
      description: 'Practice worksheet covering properties of definite integrals and finding bounded areas between parabolas and lines.',
      subject: 'Mathematics',
      className: 'Class 12',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      totalMarks: 40,
      fileName: 'Calculus_Worksheet_04.pdf',
      fileSize: '890 KB',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      teacher: {
        'name': 'Saqib Nadeem',
        'avatar': null,
      },
      mySubmission: null,
      stats: {'totalSubmissions': 24, 'totalComments': 5},
    ),
    StudentAssignment(
      id: 'asgn-chem-103',
      title: 'Chemical Kinetics & Rate Law Mechanisms',
      description: 'Derive integrated rate equations for zero and first order reactions and determine order of reaction from initial rate data.',
      subject: 'Chemistry',
      className: 'Class 12',
      dueDate: DateTime.now().add(const Duration(days: 6)),
      totalMarks: 35,
      fileName: 'Kinetics_Mechanisms.pdf',
      fileSize: '2.1 MB',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      teacher: {
        'name': 'Prakash Jha',
        'avatar': null,
      },
      mySubmission: AssignmentSubmission(
        id: 'sub-demo-1',
        fileUrl: '',
        fileName: 'Aman_Kinetics_Submission.pdf',
        fileSize: '1.8 MB',
        remarks: 'Well presented derivations. Good grasp of Arrhenius equation.',
        status: 'evaluated',
        isCompleted: true,
        submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      stats: {'totalSubmissions': 31, 'totalComments': 7},
    ),
  ];

  Future<void> _fetchAssignments({bool isRefresh = false}) async {
    if (!isRefresh && _allAssignments.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final dio = ref.read(dioProvider);
      List<StudentAssignment> loaded = [];

      try {
        final response = await dio.get("/api/student/assignments");
        final data = response.data;
        if (data != null && data['success'] == true && data['assignments'] is List) {
          final List<dynamic> assignmentsData = data['assignments'];
          if (assignmentsData.isNotEmpty) {
            loaded = assignmentsData
                .map((e) => StudentAssignment.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            CacheService.set('cached_student_assignments_v1', assignmentsData);
          }
        }
      } catch (err) {
        debugPrint("Primary /api/student/assignments error: $err");
      }

      if (loaded.isEmpty && _allAssignments.isEmpty) {
        loaded = _curatedAssignments;
      }

      if (loaded.isNotEmpty && mounted) {
        setState(() {
          _allAssignments = loaded;
        });
      }
    } catch (e) {
      debugPrint("Error fetching assignments: $e");
      if (_allAssignments.isEmpty && mounted) {
        setState(() {
          _allAssignments = _curatedAssignments;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _subjects {
    final Map<String, String> normalizedMap = {};
    for (final assignment in _allAssignments) {
      final trimmed = assignment.subject.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (!normalizedMap.containsKey(key)) {
        normalizedMap[key] = trimmed;
      }
    }
    final list = normalizedMap.values.toList()..sort();
    return list;
  }

  List<StudentAssignment> get _filteredAssignments {
    List<StudentAssignment> list = List.from(_allAssignments);

    if (_filter == _AssignmentFilter.pending) {
      list = list.where((a) => a.mySubmission == null).toList();
    } else if (_filter == _AssignmentFilter.submitted) {
      list = list.where((a) => a.mySubmission != null).toList();
    }

    if (_selectedSubject != "all") {
      final sel = _selectedSubject.trim().toLowerCase();
      list = list.where((a) => a.subject.trim().toLowerCase() == sel).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q) ||
            a.subject.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  Future<void> _handleMarkCompleted(String submissionId) async {
    setState(() {
      _allAssignments = _allAssignments.map((a) {
        if (a.mySubmission?.id == submissionId) {
          return a.copyWith(
            mySubmission: a.mySubmission!.copyWith(
              isCompleted: true,
              status: "completed",
            ),
          );
        }
        return a;
      }).toList();
    });

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.patch(
        "/api/student/assignments",
        data: {"submissionId": submissionId, "isCompleted": true},
      );
      if (res.data?['success'] != true) {
        throw Exception(res.data?['error'] ?? "Failed to mark as complete");
      }
    } catch (e) {
      debugPrint("Error marking as completed: $e");
      _fetchAssignments(isRefresh: true);
    }
  }

  void _handleSubmitSuccess(String assignmentId, AssignmentSubmission submission) {
    setState(() {
      _allAssignments = _allAssignments.map((a) {
        if (a.id == assignmentId) {
          return a.copyWith(mySubmission: submission);
        }
        return a;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalAssignments = _allAssignments.length;
    final completedAssignments =
        _allAssignments.where((a) => a.mySubmission?.isCompleted == true).length;
    final pendingAssignments =
        _allAssignments.where((a) => a.mySubmission == null).length;
    final submittedAssignments =
        _allAssignments.where((a) => a.mySubmission != null).length;

    final statCards = [
      {
        "icon": LucideIcons.bookOpen,
        "label": "Total",
        "value": totalAssignments,
        "accent": const Color(0xFF8FA6E0),
      },
      {
        "icon": LucideIcons.checkCircle2,
        "label": "Completed",
        "value": completedAssignments,
        "accent": AppColors.mint,
      },
      {
        "icon": LucideIcons.clock,
        "label": "Pending",
        "value": pendingAssignments,
        "accent": AppColors.coral,
      },
      {
        "icon": LucideIcons.activity,
        "label": "Submitted",
        "value": submittedAssignments,
        "accent": AppColors.gold,
      },
    ];

    if (_loading && _allAssignments.isEmpty) {
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
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.indigo),
                SizedBox(height: AppSpacing.md),
                Text("Loading assignments…"),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _filteredAssignments;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/student/dashboard');
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
      body: RefreshIndicator(
        color: AppColors.indigo,
        onRefresh: () => _fetchAssignments(isRefresh: true),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Hero Header
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
                        top: 56,
                        left: 20,
                        right: 20,
                        bottom: 28,
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
                                  borderRadius: AppRadius.mdBorder,
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  LucideIcons.fileText,
                                  size: 22,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "My Assignments",
                                      style: AppTypography.h2.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      "View, submit, and discuss your work",
                                      style: AppTypography.body.copyWith(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Glass Stat Grid
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: AppRadius.lgBorder,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 1,
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final cardWidth =
                                    (constraints.maxWidth - AppSpacing.sm) / 2;
                                return Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: statCards.map((s) {
                                    final accent = s['accent'] as Color;
                                    return Container(
                                      width: cardWidth,
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.06),
                                        borderRadius: AppRadius.mdBorder,
                                        border: Border(
                                          left: BorderSide(color: accent, width: 3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              borderRadius: AppRadius.smBorder,
                                              color: accent.withValues(alpha: 0.2),
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
                                            "${s['value']}",
                                            style: AppTypography.h3.copyWith(
                                              color: AppColors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            s['label'] as String,
                                            style: AppTypography.caption.copyWith(
                                              color: Colors.white.withValues(alpha: 0.6),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search & Filter Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppInput(
                      controller: _searchController,
                      placeholder: "Search assignments…",
                      onChanged: (v) => setState(() => _searchQuery = v),
                      leftIcon: Icon(
                        LucideIcons.search,
                        size: 18,
                        color: AppColors.inkFaint,
                      ),
                      rightIcon: _searchQuery.isNotEmpty
                          ? AnimatedPressable(
                              pressScale: 0.85,
                              onPress: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                              child: Icon(
                                LucideIcons.x,
                                size: 16,
                                color: AppColors.inkFaint,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Filter Tabs (All, Pending, Submitted)
                    Row(
                      children: [
                        _buildFilterTab(
                          filter: _AssignmentFilter.all,
                          label: "All",
                          icon: LucideIcons.bookOpen,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          filter: _AssignmentFilter.pending,
                          label: "Pending",
                          icon: LucideIcons.clock,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          filter: _AssignmentFilter.submitted,
                          label: "Submitted",
                          icon: LucideIcons.checkCircle2,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Subject Chips
                    if (_subjects.isNotEmpty) ...[
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _subjects.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final s = idx == 0 ? "all" : _subjects[idx - 1];
                            final active = _selectedSubject == s;
                            return AnimatedPressable(
                              pressScale: 0.95,
                              onPress: () => setState(() => _selectedSubject = s),
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
                                alignment: Alignment.center,
                                child: Text(
                                  s == "all" ? "All Subjects" : s,
                                  style: AppTypography.caption.copyWith(
                                    color: active
                                        ? AppColors.indigo
                                        : AppColors.inkMuted,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    Text(
                      "Showing ${filtered.length} of $totalAssignments assignments",
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkFaint,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),

            // Assignments List / Empty State
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 64,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceMuted,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.fileText,
                          size: 30,
                          color: AppColors.inkFaint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        "No assignments found",
                        style: AppTypography.label.copyWith(
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _searchQuery.isNotEmpty || _selectedSubject != "all"
                            ? "Try adjusting your filters."
                            : "Your teachers haven't assigned any work yet.",
                        style: AppTypography.body.copyWith(
                          fontSize: 13,
                          color: AppColors.inkMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    return RepaintBoundary(
                      child: AssignmentCard(
                        assignment: item,
                        onSubmit: () {
                          SubmitAssignmentModal.show(
                            context,
                            assignment: item,
                            onSuccess: (id, sub) =>
                                _handleSubmitSuccess(id, sub),
                          );
                        },
                        onViewComments: () {
                          CommentsModal.show(
                            context,
                            assignment: item,
                          );
                        },
                        onMarkCompleted: _handleMarkCompleted,
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 96),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFilterTab({
    required _AssignmentFilter filter,
    required String label,
    required IconData icon,
  }) {
    final active = _filter == filter;
    return Expanded(
      child: AnimatedPressable(
        pressScale: 0.95,
        onPress: () => setState(() => _filter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.indigo : AppColors.surface,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(
              color: active ? AppColors.indigo : AppColors.border,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: active ? AppColors.white : AppColors.inkMuted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: active ? AppColors.white : AppColors.ink,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
