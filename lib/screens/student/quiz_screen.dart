import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../models/quiz.dart';
import '../../services/api_client.dart';
import '../../services/cache_service.dart';
import '../../theme/app_theme.dart';
import '../../components/ui/ui.dart';

enum QuizState { categories, loading, taking, result }

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  QuizState _quizState = QuizState.categories;

  static final Map<String, dynamic> _fallbackCategories = {
    'all': [
      {'id': 'c12-phy', 'title': 'Class 12 Physics (Electrostatics)', 'subject': 'Physics', 'class': 12, 'difficulty': 'intermediate'},
      {'id': 'c12-math', 'title': 'Class 12 Math (Calculus & Vectors)', 'subject': 'Mathematics', 'class': 12, 'difficulty': 'hard'},
      {'id': 'c12-chem', 'title': 'Class 12 Chemistry (Organic)', 'subject': 'Chemistry', 'class': 12, 'difficulty': 'intermediate'},
      {'id': 'c10-sci', 'title': 'Class 10 Science (Electricity & Light)', 'subject': 'Science', 'class': 10, 'difficulty': 'beginner'},
      {'id': 'c10-math', 'title': 'Class 10 Mathematics (Real Numbers)', 'subject': 'Mathematics', 'class': 10, 'difficulty': 'beginner'},
      {'id': 'jee-mock', 'title': 'JEE Main PCM Full Practice Test', 'subject': 'PCM', 'difficulty': 'hard'},
      {'id': 'neet-mock', 'title': 'NEET UG PCB Comprehensive Mock', 'subject': 'PCB', 'difficulty': 'hard'},
    ],
    'grouped': {
      'Class 12': {
        'title': 'Class 12 Board & Competitive',
        'categories': [
          {'id': 'c12-phy', 'title': 'Class 12 Physics (Electrostatics)', 'subject': 'Physics', 'class': 12, 'difficulty': 'intermediate'},
          {'id': 'c12-math', 'title': 'Class 12 Math (Calculus & Vectors)', 'subject': 'Mathematics', 'class': 12, 'difficulty': 'hard'},
          {'id': 'c12-chem', 'title': 'Class 12 Chemistry (Organic)', 'subject': 'Chemistry', 'class': 12, 'difficulty': 'intermediate'},
        ],
      },
      'Class 10': {
        'title': 'Class 10 Board Prep',
        'categories': [
          {'id': 'c10-sci', 'title': 'Class 10 Science (Electricity & Light)', 'subject': 'Science', 'class': 10, 'difficulty': 'beginner'},
          {'id': 'c10-math', 'title': 'Class 10 Mathematics (Real Numbers)', 'subject': 'Mathematics', 'class': 10, 'difficulty': 'beginner'},
        ],
      },
      'Competitive': {
        'title': 'National Entrance Mocks',
        'categories': [
          {'id': 'jee-mock', 'title': 'JEE Main PCM Full Practice Test', 'subject': 'PCM', 'difficulty': 'hard'},
          {'id': 'neet-mock', 'title': 'NEET UG PCB Comprehensive Mock', 'subject': 'PCB', 'difficulty': 'hard'},
        ],
      },
    },
  };

  // Categories
  Map<String, dynamic>? _categories = _fallbackCategories;
  final TextEditingController _searchController = TextEditingController();
  String _filterGroup = "all";

  // Active quiz
  QuizData? _quiz;
  int _currentQuestion = 0;
  List<int?> _selectedAnswers = [];
  int _timeLeft = 3600;
  final Set<int> _flaggedQuestions = {};
  int _startTime = 0;
  Timer? _timer;

  // Result
  QuizScore? _score;
  bool _showExplanations = false;

  @override
  void initState() {
    super.initState();
    _loadCachedCategories();
    _loadCategories();
  }

  void _loadCachedCategories() {
    final cached = CacheService.getSync<Map<String, dynamic>>('cached_quiz_categories_v1');
    if (cached != null) {
      _categories = cached;
    } else {
      CacheService.get<Map<String, dynamic>>('cached_quiz_categories_v1').then((data) {
        if (data != null && mounted && _categories == null) {
          setState(() => _categories = data);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_quizState != QuizState.taking || _timeLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft <= 1) {
          _handleSubmit();
          _timeLeft = 0;
        } else {
          _timeLeft--;
        }
      });
    });
  }

  Future<void> _loadCategories() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get("/api/quiz/generate");
      if (response.data != null && response.data['success'] == true && response.data['data'] is Map) {
        final catData = Map<String, dynamic>.from(response.data['data'] as Map);
        if (mounted) {
          setState(() {
            _categories = catData;
          });
        }
        CacheService.set('cached_quiz_categories_v1', catData);
      }
    } catch (e) {
      debugPrint("Failed to load categories: $e");
    }
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  Future<void> _generateQuiz(String categoryId) async {
    setState(() => _quizState = QuizState.loading);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post("/api/quiz/generate", data: {
        "category": categoryId,
        "questionCount": 20,
      });
      if (response.data['success'] != true || response.data['data'] == null) {
        throw Exception(response.data['error'] ?? "Failed to generate quiz");
      }

      final quizData = QuizData.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));

      if (mounted) {
        setState(() {
          _quiz = quizData;
          _selectedAnswers = List.filled(quizData.questions.length, null);
          _timeLeft = quizData.duration * 60;
          _startTime = DateTime.now().millisecondsSinceEpoch;
          _currentQuestion = 0;
          _flaggedQuestions.clear();
          _showExplanations = false;
          _quizState = QuizState.taking;
        });
        _startTimer();
      }
    } catch (err) {
      debugPrint("Offline or failed quiz generation: $err");
      final sampleQuiz = QuizData(
        title: "Mock Practice Test",
        category: categoryId,
        duration: 30,
        totalMarks: 20,
        passingMarks: 8,
        questions: [
          QuizQuestion(
            id: 1,
            question: "Two point charges +q and -q are separated by distance 2a. What is the electric dipole moment?",
            options: [
              "p = q / (2a)",
              "p = 2qa along negative to positive charge",
              "p = qa",
              "Zero"
            ],
            correctAnswer: 1,
            difficulty: "easy",
            topic: "Electrostatics",
            explanation: "Electric dipole moment p = q * 2a and points from negative charge to positive charge.",
          ),
          QuizQuestion(
            id: 2,
            question: "What is the derivative of e^(sin x) with respect to x?",
            options: [
              "cos(x) * e^(sin x)",
              "e^(cos x)",
              "-cos(x) * e^(sin x)",
              "sin(x) * e^(cos x)"
            ],
            correctAnswer: 0,
            difficulty: "easy",
            topic: "Calculus",
            explanation: "By chain rule, d/dx[e^(sin x)] = e^(sin x) * d/dx[sin x] = cos(x) * e^(sin x).",
          ),
          QuizQuestion(
            id: 3,
            question: "Which of the following is an intensive property in thermodynamics?",
            options: [
              "Volume",
              "Internal energy",
              "Temperature",
              "Enthalpy"
            ],
            correctAnswer: 2,
            difficulty: "easy",
            topic: "Thermodynamics",
            explanation: "Temperature does not depend on the mass or size of the system, making it an intensive property.",
          ),
          QuizQuestion(
            id: 4,
            question: "An object is placed at 2F in front of a convex lens. The image is formed at:",
            options: [
              "Focus F",
              "2F on the other side",
              "Between F and 2F",
              "Infinity"
            ],
            correctAnswer: 1,
            difficulty: "easy",
            topic: "Ray Optics",
            explanation: "For a convex lens, an object at 2F produces a real, inverted image of the same size at 2F on the opposite side.",
          ),
          QuizQuestion(
            id: 5,
            question: "Which order of reaction has rate constant units of mol·L⁻¹·s⁻¹?",
            options: [
              "Zero order",
              "First order",
              "Second order",
              "Third order"
            ],
            correctAnswer: 0,
            difficulty: "easy",
            topic: "Chemical Kinetics",
            explanation: "For a zero-order reaction, Rate = k[A]^0 = k, so units of k are same as rate (mol/(L·s)).",
          ),
        ],
        metadata: QuizMetadata(
          generatedAt: DateTime.now().toIso8601String(),
          model: "IntenseLearners-LocalEngine",
          questionCount: 5,
          markingScheme: {"correct": 4, "incorrect": -1},
        ),
      );

      if (mounted) {
        setState(() {
          _quiz = sampleQuiz;
          _selectedAnswers = List.filled(sampleQuiz.questions.length, null);
          _timeLeft = sampleQuiz.duration * 60;
          _startTime = DateTime.now().millisecondsSinceEpoch;
          _currentQuestion = 0;
          _flaggedQuestions.clear();
          _showExplanations = false;
          _quizState = QuizState.taking;
        });
        _startTimer();
      }
    }
  }

  void _selectAnswer(int idx) {
    setState(() {
      _selectedAnswers[_currentQuestion] = idx;
    });
  }

  void _toggleFlag() {
    setState(() {
      if (_flaggedQuestions.contains(_currentQuestion)) {
        _flaggedQuestions.remove(_currentQuestion);
      } else {
        _flaggedQuestions.add(_currentQuestion);
      }
    });
  }

  void _handleSubmit() {
    if (_quiz == null) return;

    int total = 0, correct = 0, incorrect = 0, unattempted = 0;
    for (int i = 0; i < _selectedAnswers.length; i++) {
      final ans = _selectedAnswers[i];
      if (ans == null) {
        unattempted++;
      } else if (ans == _quiz!.questions[i].correctAnswer) {
        total += 4;
        correct++;
      } else {
        total -= 1;
        incorrect++;
      }
    }

    final timeTaken = (DateTime.now().millisecondsSinceEpoch - _startTime) ~/ 1000;
    final percentage = ((total / _quiz!.totalMarks) * 100).round();

    setState(() {
      _score = QuizScore(
        total: total,
        correct: correct,
        incorrect: incorrect,
        unattempted: unattempted,
        percentage: percentage,
        passed: total >= _quiz!.passingMarks,
        timeTaken: timeTaken,
      );
      _quizState = QuizState.result;
    });
  }

  void _resetQuiz() {
    setState(() {
      _quizState = QuizState.categories;
      _score = null;
      _quiz = null;
      _selectedAnswers.clear();
      _flaggedQuestions.clear();
      _showExplanations = false;
      _currentQuestion = 0;
    });
  }

  Future<void> _handlePopAttempt() async {
    if (_quizState == QuizState.taking) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
          title: Text("Leave quiz?", style: AppTypography.h3.copyWith(fontSize: 18)),
          content: Text(
            "Your progress will be lost.",
            style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.inkMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Stay", style: AppTypography.label.copyWith(color: AppColors.inkMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Leave", style: AppTypography.label.copyWith(color: AppColors.coral)),
            ),
          ],
        ),
      );
      if (shouldPop == true && mounted) {
        setState(() {
          _resetQuiz();
        });
      }
    } else if (_quizState == QuizState.result) {
      setState(() {
        _resetQuiz();
      });
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/student/dashboard');
      }
    }
  }

  List<QuizCategoryItem> _getFilteredCategories() {
    if (_categories == null) return [];

    List<QuizCategoryItem> all = [];
    final rawGrouped = _categories!['grouped'];
    if (_filterGroup != "all" && rawGrouped is Map && rawGrouped[_filterGroup] != null) {
      final grp = rawGrouped[_filterGroup];
      final arr = grp is Map ? (grp['categories'] as List<dynamic>? ?? []) : [];
      all = arr.map((e) => QuizCategoryItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } else {
      final arr = _categories!['all'] as List<dynamic>? ?? [];
      all = arr.map((e) => QuizCategoryItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      all = all.where((c) => c.title.toLowerCase().contains(q) || c.subject.toLowerCase().contains(q)).toList();
    }

    return all;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handlePopAttempt();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: _buildCurrentState(),
      ),
    );
  }

  Widget _buildCurrentState() {
    switch (_quizState) {
      case QuizState.loading:
        return _buildLoadingState();
      case QuizState.categories:
        return _buildCategoriesState();
      case QuizState.taking:
        return _buildTakingState();
      case QuizState.result:
        return _buildResultState();
    }
  }

  Widget _buildLoadingState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.indigo),
              const SizedBox(height: AppSpacing.lg),
              Text(
                "Generating Your Quiz…",
                style: AppTypography.h3.copyWith(fontSize: 18, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                "AI is creating 20 unique questions for you",
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesState() {
    final rawGrouped = _categories?['grouped'];
    final groups = rawGrouped is Map
        ? rawGrouped.keys.map((k) => k.toString()).toList()
        : <String>[];
    final filtered = _getFilteredCategories();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                AnimatedPressable(
                  pressScale: 0.9,
                  onPress: _handlePopAttempt,
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
                const SizedBox(width: 12),
                Text(
                  "Take a Quiz",
                  style: AppTypography.h3.copyWith(fontSize: 16, color: AppColors.ink),
                ),
              ],
            ),
          ),

          Expanded(
            child: _categories == null
                ? Center(child: CircularProgressIndicator(color: AppColors.indigo))
                : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.indigoTint,
                                  borderRadius: AppRadius.pillBorder,
                                ),
                                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.brain, size: 14, color: AppColors.indigo),
                                    const SizedBox(width: 6),
                                    Text(
                                      "AI-Powered Quiz System",
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.5,
                                        color: AppColors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "Choose from 50+ categories • 20 questions • 60 minutes • +4/-1 marking",
                                style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              AppInput(
                                controller: _searchController,
                                placeholder: "Search categories…",
                                leftIcon: Icon(LucideIcons.search, size: 16, color: AppColors.inkFaint),
                                rightIcon: _searchController.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          setState(() {});
                                        },
                                        child: Icon(LucideIcons.x, size: 14, color: AppColors.inkFaint),
                                      )
                                    : null,
                                onChanged: (val) => setState(() {}),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              SizedBox(
                                height: 36,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: groups.length + 1,
                                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final g = index == 0 ? "all" : groups[index - 1];
                                    final isSelected = _filterGroup == g;
                                    final grp = rawGrouped is Map ? rawGrouped[g] : null;
                                    final label = g == "all"
                                        ? "All Categories"
                                        : (grp is Map ? grp['title']?.toString() : null) ?? g;

                                    return AnimatedPressable(
                                      pressScale: 0.95,
                                      onPress: () => setState(() => _filterGroup = g),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.indigo : AppColors.surface,
                                          borderRadius: AppRadius.pillBorder,
                                          border: isSelected ? null : Border.all(color: AppColors.border),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          label,
                                          style: AppTypography.label.copyWith(
                                            fontSize: 12,
                                            color: isSelected ? Colors.white : AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_categories == null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(64),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: AppColors.indigo),
                                  SizedBox(height: AppSpacing.md),
                                  Text("Loading mock test categories…"),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (filtered.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                Icon(LucideIcons.alertCircle, size: 40, color: AppColors.inkFaint),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? "No categories matching '${_searchController.text}'"
                                      : "No categories found for selected filter.",
                                  style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                ),
                                if (_searchController.text.isNotEmpty || _filterGroup != "all") ...[
                                  const SizedBox(height: AppSpacing.md),
                                  AppButton(
                                    label: "Reset Filter",
                                    variant: AppButtonVariant.secondary,
                                    icon: LucideIcons.rotateCcw,
                                    onPress: () {
                                      _searchController.clear();
                                      setState(() => _filterGroup = "all");
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.95,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final cat = filtered[index];
                                final hasClass = cat.classLevel != null;
                                final diff = cat.difficulty?.toLowerCase();

                                AppBadgeTone diffTone = AppBadgeTone.neutral;
                                if (diff == 'beginner') {
                                  diffTone = AppBadgeTone.success;
                                } else if (diff == 'intermediate') {
                                  diffTone = AppBadgeTone.gold;
                                } else if (diff == 'hard' || diff == 'advanced') {
                                  diffTone = AppBadgeTone.danger;
                                }

                                return AnimatedPressable(
                                  pressScale: 0.97,
                                  onPress: () => _generateQuiz(cat.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: AppRadius.lgBorder,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: hasClass ? AppColors.indigo : AppColors.mint,
                                            borderRadius: AppRadius.mdBorder,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            hasClass ? LucideIcons.bookOpen : LucideIcons.code,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            cat.title,
                                            style: AppTypography.bodyMedium.copyWith(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.ink,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            if (hasClass)
                                              AppBadge(
                                                label: "Class ${cat.classLevel}",
                                                tone: AppBadgeTone.brand,
                                              ),
                                            if (cat.difficulty != null)
                                              AppBadge(
                                                label: cat.difficulty!,
                                                tone: diffTone,
                                              ),
                                          ],
                                        ),
                                      ],
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
        ],
      ),
    );
  }

  Widget _buildTakingState() {
    if (_quiz == null) return const SizedBox.shrink();

    final question = _quiz!.questions[_currentQuestion];
    final progress = ((_currentQuestion + 1) / _quiz!.questions.length);
    final answeredCount = _selectedAnswers.where((a) => a != null).length;
    final isFlagged = _flaggedQuestions.contains(_currentQuestion);

    final isTimeUrgent = _timeLeft < 300;

    return SafeArea(
      child: Column(
        children: [
          // Sticky Quiz Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _quiz!.title,
                            style: AppTypography.label.copyWith(fontSize: 14, color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "$answeredCount/${_quiz!.questions.length} answered",
                            style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isTimeUrgent ? AppColors.coralTint : AppColors.indigoTint,
                            borderRadius: AppRadius.smBorder,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 14,
                                color: isTimeUrgent ? AppColors.coral : AppColors.indigo,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _formatTime(_timeLeft),
                                style: AppTypography.label.copyWith(
                                  fontSize: 12,
                                  color: isTimeUrgent ? AppColors.coral : AppColors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedPressable(
                          pressScale: 0.95,
                          onPress: _handleSubmit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: AppRadius.smBorder,
                            ),
                            child: Text(
                              "Submit",
                              style: AppTypography.label.copyWith(fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress Bar
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(color: AppColors.indigo),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Question Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.lgBorder,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.indigoTint,
                                borderRadius: AppRadius.smBorder,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "${_currentQuestion + 1}",
                                style: AppTypography.label.copyWith(
                                  color: AppColors.indigo,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      AppBadge(label: question.difficulty, tone: AppBadgeTone.neutral),
                                      AppBadge(label: question.topic, tone: AppBadgeTone.brand),
                                      Text(
                                        "• 4 marks",
                                        style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    question.question,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedPressable(
                              pressScale: 0.9,
                              onPress: _toggleFlag,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isFlagged ? AppColors.goldTint : AppColors.surfaceMuted,
                                  borderRadius: AppRadius.smBorder,
                                ),
                                child: Icon(
                                  LucideIcons.flag,
                                  size: 16,
                                  color: isFlagged ? AppColors.gold : AppColors.inkFaint,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Options
                        Column(
                          children: question.options.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final opt = entry.value;
                            final isSelected = _selectedAnswers[_currentQuestion] == idx;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AnimatedPressable(
                                pressScale: 0.99,
                                onPress: () => _selectAnswer(idx),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.indigoTint : AppColors.surface,
                                    borderRadius: AppRadius.mdBorder,
                                    border: Border.all(
                                      color: isSelected ? AppColors.indigo : AppColors.border,
                                      width: isSelected ? 2 : 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? AppColors.indigo : AppColors.border,
                                            width: 2,
                                          ),
                                          color: isSelected ? AppColors.indigo : Colors.transparent,
                                        ),
                                        alignment: Alignment.center,
                                        child: isSelected
                                            ? Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "${String.fromCharCode(65 + idx)}. $opt",
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontSize: 14,
                                            color: isSelected ? AppColors.indigo : AppColors.ink,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Bottom Navigation Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.lgBorder,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedPressable(
                              pressScale: 0.95,
                              onPress: _currentQuestion > 0
                                  ? () => setState(() => _currentQuestion--)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.mdBorder,
                                  border: Border.all(color: AppColors.border, width: 1.5),
                                ),
                                child: Text(
                                  "Previous",
                                  style: AppTypography.label.copyWith(
                                    fontSize: 12.5,
                                    color: _currentQuestion == 0 ? AppColors.inkFaint : AppColors.ink,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              "${_currentQuestion + 1} of ${_quiz!.questions.length}",
                              style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                            ),
                            AnimatedPressable(
                              pressScale: 0.95,
                              onPress: _currentQuestion < _quiz!.questions.length - 1
                                  ? () => setState(() => _currentQuestion++)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.indigo,
                                  borderRadius: AppRadius.mdBorder,
                                ),
                                child: Text(
                                  "Next",
                                  style: AppTypography.label.copyWith(
                                    fontSize: 12.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Quick Navigation:",
                            style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_quiz!.questions.length, (i) {
                            final isCur = _currentQuestion == i;
                            final isFlg = _flaggedQuestions.contains(i);
                            final isAns = _selectedAnswers[i] != null;

                            Color bg = AppColors.surfaceMuted;
                            Color fg = AppColors.inkMuted;

                            if (isFlg) {
                              bg = AppColors.goldTint;
                              fg = AppColors.gold;
                            } else if (isAns) {
                              bg = AppColors.mintTint;
                              fg = AppColors.mint;
                            }

                            if (isCur) {
                              bg = AppColors.indigo;
                              fg = Colors.white;
                            }

                            return AnimatedPressable(
                              pressScale: 0.9,
                              onPress: () => setState(() => _currentQuestion = i),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: AppRadius.smBorder,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "${i + 1}",
                                  style: AppTypography.label.copyWith(
                                    fontSize: 11.5,
                                    color: fg,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
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
    );
  }

  Widget _buildResultState() {
    if (_score == null || _quiz == null) return const SizedBox.shrink();

    final passed = _score!.passed;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Icon & Title
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: passed ? AppColors.mintTint : AppColors.coralTint,
              ),
              alignment: Alignment.center,
              child: Icon(
                passed ? LucideIcons.trophy : LucideIcons.xCircle,
                size: 38,
                color: passed ? AppColors.mint : AppColors.coral,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              passed ? "Congratulations! 🎉" : "Keep Practicing! 💪",
              style: AppTypography.h2.copyWith(fontSize: 22, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              passed
                  ? "You've successfully passed the quiz!"
                  : "You need ${_quiz!.passingMarks} marks to pass. You got ${_score!.total} marks.",
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 2),
            Text(
              "${_quiz!.title} • Completed in ${_formatTime(_score!.timeTaken)}",
              style: AppTypography.caption.copyWith(color: AppColors.inkFaint, fontSize: 11),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Big Score Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.indigo,
                borderRadius: AppRadius.lgBorder,
              ),
              child: Column(
                children: [
                  Text(
                    "Your Score",
                    style: AppTypography.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_score!.percentage}%",
                    style: AppTypography.stat.copyWith(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_score!.total} / ${_quiz!.totalMarks} marks",
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Trio metric breakdown
            Row(
              children: [
                _ResultMetricBox(
                  icon: LucideIcons.checkCircle,
                  label: "Correct",
                  value: "${_score!.correct}",
                  sub: "+${_score!.correct * 4}",
                  bg: AppColors.mintTint,
                  fg: AppColors.mint,
                ),
                const SizedBox(width: 10),
                _ResultMetricBox(
                  icon: LucideIcons.xCircle,
                  label: "Incorrect",
                  value: "${_score!.incorrect}",
                  sub: "-${_score!.incorrect}",
                  bg: AppColors.coralTint,
                  fg: AppColors.coral,
                ),
                const SizedBox(width: 10),
                _ResultMetricBox(
                  icon: LucideIcons.alertCircle,
                  label: "Skipped",
                  value: "${_score!.unattempted}",
                  sub: "0",
                  bg: AppColors.surfaceMuted,
                  fg: AppColors.inkMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Performance Analysis
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.trendingUp, size: 16, color: AppColors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        "Performance Analysis",
                        style: AppTypography.label.copyWith(fontSize: 14, color: AppColors.ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _AnalysisBar(
                    label: "Accuracy",
                    pct: ((_score!.correct / (_score!.correct + _score!.incorrect == 0 ? 1 : _score!.correct + _score!.incorrect)) * 100).round(),
                    color: AppColors.mint,
                  ),
                  const SizedBox(height: 12),
                  _AnalysisBar(
                    label: "Attempt Rate",
                    pct: (((_score!.correct + _score!.incorrect) / _quiz!.questions.length) * 100).round(),
                    color: AppColors.indigo,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Toggle Solutions Button
            AnimatedPressable(
              pressScale: 0.97,
              onPress: () => setState(() => _showExplanations = !_showExplanations),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showExplanations ? "Hide Detailed Solutions" : "Show Detailed Solutions",
                      style: AppTypography.label.copyWith(fontSize: 13.5, color: AppColors.indigo),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _showExplanations ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 16,
                      color: AppColors.indigo,
                    ),
                  ],
                ),
              ),
            ),

            if (_showExplanations) ...[
              const SizedBox(height: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Question-wise Review",
                    style: AppTypography.h3.copyWith(fontSize: 16, color: AppColors.ink),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._quiz!.questions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final q = entry.value;
                    final userAns = _selectedAnswers[idx];
                    final isCorrect = userAns == q.correctAnswer;
                    final isUnattempted = userAns == null;

                    Color cardBorder = isUnattempted
                        ? AppColors.border
                        : isCorrect
                            ? AppColors.mint
                            : AppColors.coral;
                    Color cardBg = isUnattempted
                        ? AppColors.surface
                        : isCorrect
                            ? AppColors.mintTint
                            : AppColors.coralTint;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppRadius.lgBorder,
                        border: Border.all(color: cardBorder, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppRadius.smBorder,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "${idx + 1}",
                                  style: AppTypography.label.copyWith(fontSize: 12, color: AppColors.ink),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  q.question,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppRadius.smBorder,
                                ),
                                child: Text(
                                  isUnattempted ? "0" : isCorrect ? "+4" : "-1",
                                  style: AppTypography.label.copyWith(
                                    fontSize: 11,
                                    color: isUnattempted
                                        ? AppColors.inkMuted
                                        : isCorrect
                                            ? AppColors.mint
                                            : AppColors.coral,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          ...q.options.asMap().entries.map((optEntry) {
                            final oi = optEntry.key;
                            final optText = optEntry.value;
                            final isAns = oi == q.correctAnswer;
                            final isUserWrong = oi == userAns && !isCorrect;

                            return Padding(
                              padding: const EdgeInsets.only(left: 36, bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isAns)
                                    Padding(
                                      padding: EdgeInsets.only(top: 2, right: 6),
                                      child: Icon(LucideIcons.checkCircle, size: 13, color: AppColors.mint),
                                    )
                                  else if (isUserWrong)
                                    Padding(
                                      padding: EdgeInsets.only(top: 2, right: 6),
                                      child: Icon(LucideIcons.xCircle, size: 13, color: AppColors.coral),
                                    )
                                  else
                                    const SizedBox(width: 19),
                                  Expanded(
                                    child: Text(
                                      "${String.fromCharCode(65 + oi)}. $optText",
                                      style: AppTypography.caption.copyWith(
                                        color: isAns
                                            ? AppColors.mint
                                            : isUserWrong
                                                ? AppColors.coral
                                                : AppColors.inkMuted,
                                        fontWeight: isAns ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          if (q.explanation.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 36, top: 8),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: AppRadius.smBorder,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Explanation:",
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    q.explanation,
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 11.5,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: "Take Another Quiz",
              icon: LucideIcons.trophy,
              onPress: _resetQuiz,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMetricBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color bg;
  final Color fg;

  const _ResultMetricBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.mdBorder,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.inkMuted)),
            Text(
              value,
              style: AppTypography.h3.copyWith(fontSize: 20, color: fg, fontWeight: FontWeight.bold),
            ),
            Text(sub, style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.inkFaint)),
          ],
        ),
      ),
    );
  }
}

class _AnalysisBar extends StatelessWidget {
  final String label;
  final int pct;
  final Color color;

  const _AnalysisBar({
    required this.label,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.inkMuted)),
            Text(
              "$pct%",
              style: AppTypography.label.copyWith(fontSize: 12, color: AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: AppRadius.pillBorder,
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: (pct / 100.0).clamp(0.0, 1.0),
            child: Container(color: color),
          ),
        ),
      ],
    );
  }
}
