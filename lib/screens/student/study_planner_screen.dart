import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/ui/ui.dart';
import '../../components/safe_back_scope.dart';
import '../../models/study_plan.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

const String _cachedPlanKey = "study_plan_cached_v1";

const _dayOptions = [3, 7, 14, 21, 30, 60, 90];
const _hourOptions = [1, 2, 3, 4, 6, 8];

const _levels = [
  {"value": "beginner", "label": "Beginner", "emoji": "🌱", "desc": "Just starting out"},
  {"value": "intermediate", "label": "Intermediate", "emoji": "⚡", "desc": "Some experience"},
  {"value": "advanced", "label": "Advanced", "emoji": "🚀", "desc": "Deep knowledge"},
];

const _quickPresets = [
  {
    "label": "JEE Physics Mechanics",
    "topics": "Kinematics, Laws of Motion, Work Energy Power, Rotational Dynamics",
    "days": 14,
    "hours": 3,
    "level": "intermediate",
    "goal": "Score 80+ in JEE Physics mechanics section"
  },
  {
    "label": "NEET Biology Genetics",
    "topics": "Mendelian Genetics, Molecular Basis of Inheritance, DNA Replication, Biotechnology",
    "days": 7,
    "hours": 3,
    "level": "intermediate",
    "goal": "Master high-yield NEET Genetics chapters"
  },
  {
    "label": "Class 10 CBSE Math",
    "topics": "Real Numbers, Polynomials, Quadratic Equations, Trigonometry, Statistics",
    "days": 14,
    "hours": 2,
    "level": "beginner",
    "goal": "Ace Class 10 CBSE Board Mathematics exam"
  },
  {
    "label": "Full-Stack Web Dev",
    "topics": "React Hooks, Next.js App Router, TypeScript, Tailwind CSS, REST APIs",
    "days": 21,
    "hours": 3,
    "level": "intermediate",
    "goal": "Build and deploy a full-stack production application"
  },
];

const Map<String, Color> _taskAccents = {
  'theory': AppColors.indigo,
  'practice': AppColors.mint,
  'project': AppColors.gold,
  'review': AppColors.coral,
  'break': AppColors.inkMuted,
};

class StudyPlannerScreen extends ConsumerStatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  ConsumerState<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends ConsumerState<StudyPlannerScreen> {
  final TextEditingController _topicsController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  int _days = 7;
  int _hoursPerDay = 2;
  String _level = "intermediate";

  bool _generating = false;
  String? _error;
  StudyPlanData? _plan;
  Set<int> _expandedDays = {0};

  @override
  void initState() {
    super.initState();
    _loadCachedPlan();
  }

  @override
  void dispose() {
    _topicsController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedPlanKey);
      if (raw != null && raw.isNotEmpty) {
        final cached = StudyPlanData.fromRawJson(raw);
        if (mounted) {
          setState(() {
            _plan = cached;
            _expandedDays = {0};
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading cached study plan: $e");
    }
  }

  Future<void> _savePlan(StudyPlanData plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedPlanKey, plan.toRawJson());
    } catch (e) {
      debugPrint("Error saving study plan: $e");
    }
  }

  Future<void> _clearPlanCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedPlanKey);
    } catch (e) {
      debugPrint("Error clearing cached study plan: $e");
    }
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _topicsController.text = preset['topics'] as String;
      _goalController.text = preset['goal'] as String;
      _days = preset['days'] as int;
      _hoursPerDay = preset['hours'] as int;
      _level = preset['level'] as String;
      _error = null;
    });
  }

  Future<void> _generatePlan() async {
    final topics = _topicsController.text.trim();
    if (topics.isEmpty) {
      setState(() => _error = "Please enter topics to learn");
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final form = StudyFormData(
        topics: topics,
        days: _days,
        hoursPerDay: _hoursPerDay,
        level: _level,
        goal: _goalController.text.trim(),
      );

      final response = await ref.read(dioProvider).post(
        '/api/ai/study-plan',
        data: form.toJson(),
      );

      final data = response.data;
      if (data['success'] != true || data['plan'] == null) {
        throw Exception(data['error'] ?? "Failed to generate plan");
      }

      final generatedPlan =
          StudyPlanData.fromJson(Map<String, dynamic>.from(data['plan'] as Map));

      await _savePlan(generatedPlan);

      if (mounted) {
        setState(() {
          _plan = generatedPlan;
          _expandedDays = {0};
        });
      }
    } catch (err) {
      debugPrint("Offline or failed AI study plan generation: $err");
      final topicsList = topics.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      final generatedSchedule = List.generate(_days, (i) {
        final dayTopic = topicsList.isNotEmpty ? topicsList[i % topicsList.length] : "Core Mastery";
        return StudyDaySchedule(
          day: i + 1,
          title: "Day ${i + 1}: $dayTopic",
          focus: "Deep dive into key concepts, formula derivation and high-yield problem solving.",
          objectives: [
            "Master fundamental definitions and derivations",
            "Solve 15-20 textbook and exemplar problems",
            "Summarize notes in flashcard format for quick recall",
          ],
          tasks: [
            StudyTask(
              time: "09:00 AM",
              task: "Concept Theory & NCERT Chapter Reading",
              type: "theory",
              duration: "45 mins",
              resources: ["Lecture Notes", "NCERT Textbook"],
              completed: false,
            ),
            StudyTask(
              time: "10:00 AM",
              task: "Standard Problem Practice & Numerical Examples",
              type: "practice",
              duration: "45 mins",
              resources: ["Question Bank", "Previous Year Papers"],
              completed: false,
            ),
            StudyTask(
              time: "11:00 AM",
              task: "Short Break & Hydration",
              type: "break",
              duration: "15 mins",
              resources: [],
              completed: false,
            ),
            StudyTask(
              time: "11:15 AM",
              task: "Doubt Resolution & Daily Quiz Revision",
              type: "review",
              duration: "30 mins",
              resources: ["Study Notes Library"],
              completed: false,
            ),
          ],
          milestone: "Completed Day ${i + 1} structured mastery milestone",
        );
      });

      final fallbackPlan = StudyPlanData(
        title: "$topics — $_days-Day Mastery Plan",
        description: "Customized ${_level.toUpperCase()} study timetable prepared for $_hoursPerDay hours/day targeted practice.",
        totalHours: _days * _hoursPerDay,
        schedule: generatedSchedule,
        weeklyGoals: [
          "Solidify theory and standard formula applications",
          "Achieve 80%+ accuracy on practice sets",
          "Regular daily revision to boost long-term retention",
        ],
        tips: [
          "Revise flashcards every morning before starting fresh topics",
          "Maintain an error logbook for questions you get wrong",
          "Take timed 5-minute pauses between 50-minute study sessions",
        ],
        resources: StudyResources(
          documentation: ["Class 12th Syllabus Blueprint", "NCERT Exemplar"],
          tutorials: ["Intense Learners Video Library Lectures"],
          practice: ["Mock Test Series", "Chapterwise Question Banks"],
        ),
      );

      await _savePlan(fallbackPlan);

      if (mounted) {
        setState(() {
          _plan = fallbackPlan;
          _expandedDays = {0};
          _error = null;
        });
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _toggleDay(int index) {
    setState(() {
      if (_expandedDays.contains(index)) {
        _expandedDays.remove(index);
      } else {
        _expandedDays.add(index);
      }
    });
  }

  void _toggleTask(int dayIndex, int taskIndex) {
    if (_plan == null) return;
    setState(() {
      final oldTask = _plan!.schedule[dayIndex].tasks[taskIndex];
      final newTask = oldTask.copyWith(completed: !oldTask.completed);
      _plan!.schedule[dayIndex].tasks[taskIndex] = newTask;
    });
    _savePlan(_plan!);
  }

  Future<void> _handleStartTask(String? link) async {
    if (link == null || link.trim().isEmpty) return;
    try {
      final uri = Uri.parse(link.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showToast("Could not open link: $link");
      }
    } catch (e) {
      _showToast("Invalid link: $link");
    }
  }

  Future<void> _handleOpenResource(String item) async {
    final trimmed = item.trim();
    if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
      try {
        final uri = Uri.parse(trimmed);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
    // Otherwise copy to clipboard
    await Clipboard.setData(ClipboardData(text: trimmed));
    _showToast("Copied to clipboard: $trimmed");
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.indigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleShare() async {
    if (_plan == null) return;
    final buffer = StringBuffer();
    buffer.writeln("📚 ${_plan!.title}");
    buffer.writeln("${_plan!.description}\n");
    buffer.writeln("⏱ Total Hours: ${_plan!.totalHours}h | Days: $_days\n");

    for (final day in _plan!.schedule) {
      buffer.writeln("──────── Day ${day.day}: ${day.title} ────────");
      buffer.writeln("Focus: ${day.focus}");
      if (day.objectives.isNotEmpty) {
        buffer.writeln("Objectives: ${day.objectives.join(', ')}");
      }
      buffer.writeln("Tasks:");
      for (final t in day.tasks) {
        final check = t.completed ? "☑" : "☐";
        buffer.writeln("  $check ${t.time} — ${t.task} (${t.type}, ${t.duration})");
        if (t.link != null && t.link!.isNotEmpty) {
          buffer.writeln("    Link: ${t.link}");
        }
      }
      buffer.writeln("Milestone: ${day.milestone}\n");
    }

    if (_plan!.tips.isNotEmpty) {
      buffer.writeln("💡 Study Tips:");
      for (final tip in _plan!.tips) {
        buffer.writeln("  • $tip");
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    _showToast("Study plan formatted schedule copied to clipboard!");
  }

  void _confirmResetPlan() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Start New Plan?",
          style: AppTypography.h3.copyWith(color: AppColors.ink),
        ),
        content: Text(
          "Creating a new study plan will replace your current schedule and checklist progress.",
          style: AppTypography.body.copyWith(color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: AppTypography.label.copyWith(color: AppColors.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearPlanCache();
              setState(() => _plan = null);
            },
            child: Text(
              "Start New",
              style: AppTypography.label.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeBackScope(
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _plan == null ? _buildForm() : _buildPlanView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.arrowLeft,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.indigoTint,
              borderRadius: AppRadius.mdBorder,
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.brain,
              size: 18,
              color: AppColors.indigo,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Study Planner",
                  style: AppTypography.label.copyWith(
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  _plan != null ? "Active Schedule" : "Personalized Curriculum",
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (_plan != null)
            AnimatedPressable(
              pressScale: 0.92,
              onPress: _confirmResetPlan,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.smBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.plus,
                      size: 12,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "New",
                      style: AppTypography.label.copyWith(
                        fontSize: 11.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final hasTopics = _topicsController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge & Title
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.indigoTint,
                borderRadius: AppRadius.pillBorder,
                border: Border.all(
                  color: AppColors.indigo.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 13,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Powered by Advanced Educational AI",
                    style: AppTypography.label.copyWith(
                      fontSize: 11.5,
                      color: AppColors.indigo,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            "AI Study Planner",
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(color: AppColors.ink, fontSize: 26),
          ),
          const SizedBox(height: 6),
          Text(
            "Get a personalized, adaptive study schedule tailored to your learning pace and goals",
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.inkMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Error Banner
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.coralTint,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    size: 16,
                    color: AppColors.coral,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.coral,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Quick Presets Carousel
          Text(
            "Quick Suggestions",
            style: AppTypography.label.copyWith(fontSize: 12, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickPresets.map((preset) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedPressable(
                    pressScale: 0.95,
                    onPress: () => _applyPreset(preset),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.smBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        preset['label'] as String,
                        style: AppTypography.label.copyWith(
                          fontSize: 11.5,
                          color: AppColors.indigo,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Topics Input
          Row(
            children: [
              Icon(LucideIcons.brain, size: 15, color: AppColors.ink),
              const SizedBox(width: 6),
              Text(
                "What do you want to learn?",
                style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Container(
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
              border: Border.all(color: const Color(0x33FFFFFF), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _topicsController,
              maxLines: 4,
              cursorColor: const Color(0xFF2EE6C5),
              style: AppTypography.body.copyWith(fontSize: 13.5, color: AppColors.ink),
              decoration: InputDecoration(
                hintText:
                    "E.g., React Hooks, TypeScript, Next.js App Router, Tailwind CSS, State Management",
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.inkFaint,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "💡 Tip: Be specific! The more details you provide, the better your schedule.",
            style: AppTypography.caption.copyWith(
              color: AppColors.inkMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Duration & Daily Hours Grid
          Row(
            children: [
              // Study Duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 14, color: AppColors.ink),
                        const SizedBox(width: 5),
                        Text(
                          "Duration",
                          style: AppTypography.label.copyWith(fontSize: 12.5, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _days,
                          isExpanded: true,
                          icon: const Icon(LucideIcons.chevronDown, size: 16),
                          items: _dayOptions.map((d) {
                            return DropdownMenuItem<int>(
                              value: d,
                              child: Text(
                                "$d Days",
                                style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _days = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Daily Study Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 14, color: AppColors.ink),
                        const SizedBox(width: 5),
                        Text(
                          "Daily Hours",
                          style: AppTypography.label.copyWith(fontSize: 12.5, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _hoursPerDay,
                          isExpanded: true,
                          icon: const Icon(LucideIcons.chevronDown, size: 16),
                          items: _hourOptions.map((h) {
                            return DropdownMenuItem<int>(
                              value: h,
                              child: Text(
                                "$h Hours/day",
                                style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _hoursPerDay = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Current Level Selector Cards
          Row(
            children: [
              Icon(LucideIcons.target, size: 14, color: AppColors.ink),
              const SizedBox(width: 5),
              Text(
                "Your Current Level",
                style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _levels.map((lvl) {
              final active = _level == lvl["value"];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: lvl == _levels.last ? 0 : 8),
                  child: AnimatedPressable(
                    pressScale: 0.96,
                    onPress: () => setState(() => _level = lvl["value"] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.indigo : AppColors.surface,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(
                          color: active ? AppColors.indigo : AppColors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(lvl["emoji"] as String, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                            lvl["label"] as String,
                            style: AppTypography.label.copyWith(
                              fontSize: 12,
                              color: active ? Colors.white : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lvl["desc"] as String,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              fontSize: 9.5,
                              color: active
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppColors.inkMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Goal Input
          Row(
            children: [
              Icon(LucideIcons.trophy, size: 14, color: AppColors.ink),
              const SizedBox(width: 5),
              Text(
                "Your Learning Goal (Optional)",
                style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
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
              border: Border.all(color: const Color(0x33FFFFFF), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _goalController,
              cursorColor: const Color(0xFF2EE6C5),
              style: AppTypography.body.copyWith(fontSize: 13.5, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: "E.g., Build a full-stack e-commerce app or score 90+",
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.inkFaint,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Informational Tip Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.indigoTint,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(
                color: AppColors.indigo.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(LucideIcons.lightbulb, size: 16, color: AppColors.indigo),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your plan will include:",
                        style: AppTypography.label.copyWith(
                          fontSize: 12,
                          color: AppColors.indigo,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "• Day-by-day structured schedule with time blocks\n"
                        "• Direct \"Start\" links to free docs, tutorials, & practice\n"
                        "• Theory, practice, projects, breaks, and daily milestones\n"
                        "• Offline checklist progress tracking",
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.ink,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Generate Action Button
          AppButton(
            label: "Generate AI Study Plan",
            icon: LucideIcons.brain,
            onPress: _generatePlan,
            loading: _generating,
            disabled: !hasTopics,
            fullWidth: true,
            size: AppButtonSize.lg,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Powered by Groq Llama 3.3 70B · Free",
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPlanView() {
    final totalTasks =
        _plan!.schedule.fold(0, (sum, d) => sum + d.tasks.length);
    final completedTasks = _plan!.schedule
        .fold(0, (sum, d) => sum + d.tasks.where((t) => t.completed).length);
    final progress =
        totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;
    final completedDays = _plan!.schedule
        .where((d) => d.tasks.isNotEmpty && d.tasks.every((t) => t.completed))
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient Hero Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.indigoDark, AppColors.indigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.lgBorder,
              boxShadow: AppShadows.raised,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.sparkles,
                          size: 11, color: AppColors.gold),
                      const SizedBox(width: 5),
                      Text(
                        "AI Generated Plan",
                        style: AppTypography.label
                            .copyWith(color: Colors.white, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  _plan!.title,
                  style: AppTypography.h2
                      .copyWith(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  _plan!.description,
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Actions row
                Row(
                  children: [
                    Expanded(
                      child: AnimatedPressable(
                        pressScale: 0.95,
                        onPress: _handleShare,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: AppRadius.smBorder,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.share2,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                "Share Plan",
                                style: AppTypography.label.copyWith(
                                    color: Colors.white, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedPressable(
                        pressScale: 0.95,
                        onPress: _confirmResetPlan,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: AppRadius.smBorder,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "New Plan",
                            style: AppTypography.label.copyWith(
                                color: Colors.white, fontSize: 11.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 4-Stat Blocks
                Row(
                  children: [
                    _buildStatBlock(LucideIcons.calendar, "Days", "$_days"),
                    const SizedBox(width: 8),
                    _buildStatBlock(
                        LucideIcons.clock, "Hours", "${_plan!.totalHours}h"),
                    const SizedBox(width: 8),
                    _buildStatBlock(
                        LucideIcons.trophy, "Done", "$completedDays/$_days"),
                    const SizedBox(width: 8),
                    _buildStatBlock(LucideIcons.target, "Progress",
                        "${progress.round()}%"),
                  ],
                ),
              ],
            ),
          ),

          // Overall Progress Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.barChart3,
                            size: 16, color: AppColors.indigo),
                        const SizedBox(width: 6),
                        Text(
                          "Overall Progress",
                          style: AppTypography.label.copyWith(
                              fontSize: 13, color: AppColors.ink),
                        ),
                      ],
                    ),
                    Text(
                      "$completedTasks/$totalTasks tasks completed",
                      style: AppTypography.caption.copyWith(
                          fontSize: 11.5, color: AppColors.inkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (progress / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: progress >= 100
                            ? AppColors.mint
                            : AppColors.indigo,
                        borderRadius: AppRadius.pillBorder,
                      ),
                    ),
                  ),
                ),
                if (progress > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LucideIcons.circleCheck,
                          size: 13, color: AppColors.mint),
                      const SizedBox(width: 5),
                      Text(
                        progress >= 100
                            ? "Congratulations! You have completed all tasks!"
                            : "Keep up the momentum! Progress is automatically saved.",
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: progress >= 100
                              ? AppColors.mint
                              : AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Daily Schedule Title
          Text(
            "Daily Schedule",
            style: AppTypography.h3.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Daily Schedule Accordion Cards
          ..._plan!.schedule.asMap().entries.map((entry) {
            final dayIndex = entry.key;
            final day = entry.value;
            final dayCompleted =
                day.tasks.isNotEmpty && day.tasks.every((t) => t.completed);
            final dayProgress = day.tasks.isEmpty
                ? 0.0
                : (day.tasks.where((t) => t.completed).length /
                    day.tasks.length);
            final isExpanded = _expandedDays.contains(dayIndex);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    AnimatedPressable(
                      pressScale: 0.99,
                      onPress: () => _toggleDay(dayIndex),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: dayCompleted
                              ? AppColors.mintTint
                              : AppColors.surface,
                          border: Border(
                            bottom: BorderSide(
                              color: isExpanded
                                  ? AppColors.border
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                if (dayCompleted)
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.mint,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(LucideIcons.circleCheck,
                                        size: 17, color: Colors.white),
                                  )
                                else
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.indigoTint,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.indigo, width: 1.5),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${day.day}",
                                      style: AppTypography.label.copyWith(
                                        fontSize: 12,
                                        color: AppColors.indigo,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Day ${day.day}: ${day.title}",
                                        style: AppTypography.label.copyWith(
                                            fontSize: 13, color: AppColors.ink),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        day.focus,
                                        style: AppTypography.caption.copyWith(
                                            fontSize: 11,
                                            color: AppColors.inkMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${day.tasks.where((t) => t.completed).length}/${day.tasks.length}",
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 11,
                                    color: AppColors.inkMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AnimatedRotation(
                                  duration: const Duration(milliseconds: 200),
                                  turns: isExpanded ? 0.5 : 0.0,
                                  child: Icon(LucideIcons.chevronDown,
                                      size: 16, color: AppColors.inkFaint),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: AppRadius.pillBorder,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: dayProgress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: dayCompleted
                                        ? AppColors.mint
                                        : AppColors.indigo,
                                    borderRadius: AppRadius.pillBorder,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Learning Objectives
                            if (day.objectives.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                margin:
                                    const EdgeInsets.only(bottom: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.indigoTint,
                                  borderRadius: AppRadius.mdBorder,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(LucideIcons.target,
                                            size: 14, color: AppColors.indigo),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Learning Objectives",
                                          style: AppTypography.label.copyWith(
                                              fontSize: 12,
                                              color: AppColors.indigo),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ...day.objectives.map((obj) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            "• $obj",
                                            style: AppTypography.caption
                                                .copyWith(
                                                    fontSize: 11.5,
                                                    color: AppColors.ink),
                                          ),
                                        )),
                                  ],
                                ),
                              ),

                            // Tasks list
                            ...day.tasks.asMap().entries.map((tEntry) {
                              final taskIndex = tEntry.key;
                              final task = tEntry.value;
                              final accent = _taskAccents[task.type] ??
                                  AppColors.indigo;
                              final hasLink = task.link != null &&
                                  task.link!.trim().isNotEmpty;

                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                margin:
                                    const EdgeInsets.only(bottom: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: task.completed
                                      ? AppColors.mintTint
                                      : AppColors.surface,
                                  borderRadius: AppRadius.mdBorder,
                                  border: Border.all(
                                    color: task.completed
                                        ? AppColors.mint
                                            .withValues(alpha: 0.4)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(LucideIcons.clock,
                                            size: 11,
                                            color: AppColors.inkMuted),
                                        const SizedBox(width: 5),
                                        Text(
                                          task.time,
                                          style: AppTypography.caption.copyWith(
                                              fontSize: 11,
                                              color: AppColors.inkMuted,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                accent.withValues(alpha: 0.12),
                                            borderRadius:
                                                AppRadius.pillBorder,
                                          ),
                                          child: Text(
                                            task.type.toUpperCase(),
                                            style: AppTypography.caption
                                                .copyWith(
                                                    fontSize: 9.5,
                                                    color: accent,
                                                    fontWeight:
                                                        FontWeight.w700),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "(${task.duration})",
                                          style: AppTypography.caption.copyWith(
                                              fontSize: 10,
                                              color: AppColors.inkMuted),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      task.task,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 13,
                                        color: task.completed
                                            ? AppColors.inkMuted
                                            : AppColors.ink,
                                        decoration: task.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    if (task.resources.isNotEmpty) ...[
                                      const SizedBox(height: 7),
                                      Wrap(
                                        spacing: 5,
                                        runSpacing: 5,
                                        children: task.resources
                                            .map((r) => Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 7,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.surfaceMuted,
                                                    border: Border.all(
                                                        color: AppColors.border),
                                                    borderRadius:
                                                        AppRadius.smBorder,
                                                  ),
                                                  child: Text(
                                                    r,
                                                    style: AppTypography.caption
                                                        .copyWith(
                                                            fontSize: 10,
                                                            color: AppColors
                                                                .inkMuted),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                    const SizedBox(height: 10),

                                    // Action buttons: "Start" (external link) & "Complete / Undo"
                                    Row(
                                      children: [
                                        if (hasLink && !task.completed) ...[
                                          AnimatedPressable(
                                            pressScale: 0.94,
                                            onPress: () =>
                                                _handleStartTask(task.link),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.indigo,
                                                borderRadius:
                                                    AppRadius.smBorder,
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    LucideIcons.play,
                                                    size: 11,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "Start",
                                                    style: AppTypography.label
                                                        .copyWith(
                                                      fontSize: 11.5,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 3),
                                                  const Icon(
                                                    LucideIcons.externalLink,
                                                    size: 10,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        AnimatedPressable(
                                          pressScale: 0.94,
                                          onPress: () => _toggleTask(
                                              dayIndex, taskIndex),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: task.completed
                                                  ? AppColors.surfaceMuted
                                                  : AppColors.mint,
                                              borderRadius: AppRadius.smBorder,
                                              border: task.completed
                                                  ? Border.all(
                                                      color: AppColors.border)
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  task.completed
                                                      ? LucideIcons.undo
                                                      : LucideIcons.check,
                                                  size: 11,
                                                  color: task.completed
                                                      ? AppColors.inkMuted
                                                      : Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  task.completed
                                                      ? "Undo"
                                                      : "Complete",
                                                  style: AppTypography.label
                                                      .copyWith(
                                                    fontSize: 11.5,
                                                    color: task.completed
                                                        ? AppColors.inkMuted
                                                        : Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),

                            // Milestone
                            if (day.milestone.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.goldTint,
                                  borderRadius: AppRadius.mdBorder,
                                  border: Border.all(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 1),
                                      child: Icon(LucideIcons.trophy,
                                          size: 14, color: AppColors.gold),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Day ${day.day} Milestone",
                                            style:
                                                AppTypography.label.copyWith(
                                              fontSize: 12,
                                              color: const Color(0xFF8A6816),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            day.milestone,
                                            style:
                                                AppTypography.body.copyWith(
                                              fontSize: 11.5,
                                              color: AppColors.ink,
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
                  ],
                ),
              ),
            );
          }),

          // Tips Card
          if (_plan!.tips.isNotEmpty) ...[
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.lightbulb,
                          size: 16, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Text(
                        "Study Tips",
                        style: AppTypography.label
                            .copyWith(fontSize: 13.5, color: AppColors.ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._plan!.tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          "• $tip",
                          style: AppTypography.body.copyWith(
                              fontSize: 12.5,
                              color: AppColors.inkMuted,
                              height: 1.4),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Recommended Resources
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.bookOpen,
                        size: 16, color: AppColors.indigo),
                    const SizedBox(width: 8),
                    Text(
                      "Recommended Resources",
                      style: AppTypography.label
                          .copyWith(fontSize: 13.5, color: AppColors.ink),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildResourceSection(
                    "Documentation", _plan!.resources.documentation),
                _buildResourceSection(
                    "Tutorials", _plan!.resources.tutorials),
                _buildResourceSection(
                    "Practice", _plan!.resources.practice),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Weekly Goals
          if (_plan!.weeklyGoals.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.indigoDark, AppColors.indigo],
                ),
                borderRadius: AppRadius.lgBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.target,
                          size: 15, color: Colors.white),
                      const SizedBox(width: 7),
                      Text(
                        "Weekly Goals",
                        style: AppTypography.label.copyWith(
                            color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._plan!.weeklyGoals.map((goal) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm + 2),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: AppRadius.smBorder,
                        ),
                        child: Text(
                          goal,
                          style: AppTypography.body.copyWith(
                              color: Colors.white, fontSize: 11.5),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBlock(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: AppRadius.smBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(height: 3),
            Text(
              value,
              style:
                  AppTypography.stat.copyWith(color: Colors.white, fontSize: 14),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceSection(String category, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: AppTypography.label
                .copyWith(fontSize: 11.5, color: AppColors.ink),
          ),
          const SizedBox(height: 3),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: AnimatedPressable(
                  pressScale: 0.98,
                  onPress: () => _handleOpenResource(item),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("→ ",
                          style: TextStyle(
                              color: AppColors.indigo,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                      Expanded(
                        child: Text(
                          item,
                          style: AppTypography.caption.copyWith(
                            fontSize: 11.5,
                            color: item.startsWith("http")
                                ? AppColors.indigo
                                : AppColors.inkMuted,
                            decoration: item.startsWith("http")
                                ? TextDecoration.underline
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
