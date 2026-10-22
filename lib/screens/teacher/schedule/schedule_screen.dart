import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/schedule.dart';
import '../../../services/api_client.dart';
import '../../../services/cache_service.dart';
import '../../../theme/app_theme.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/animated_pressable.dart';
import '../../../components/ui/progress_ring.dart';
import '../../../components/ui/stat_primitives.dart';
import '../../../components/teacher/session_form_modal.dart';
import '../../../components/teacher/holiday_form_modal.dart';

const String _kHeroPhoto =
    "https://images.unsplash.com/photo-1506784983877-45594efa4cbe?w=1200&q=80&auto=format&fit=crop";

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  List<ScheduleSession> _sessions = [];
  List<CustomHoliday> _customHolidays = [];
  List<NationalHoliday> _nationalHolidays = [];
  bool _loading = true;
  String _loadError = "";

  late int _viewYear;
  late int _viewMonth; // 1-12
  String? _selectedDateKey;

  final DateTime _today = DateTime.now();
  late final String _todayKey;

  List<ScheduleSession> _getCuratedSessions(DateTime now) {
    final y = now.year;
    final m = now.month;
    final d = now.day;
    return [
      ScheduleSession(
        id: "curated-session-1",
        title: "Contemporary World Politics - Lecture",
        subject: "Political Science",
        classLevel: "Class 12",
        date: DateTime(y, m, d).toIso8601String(),
        startTime: "10:00 AM",
        endTime: "11:30 AM",
        color: "#6366F1",
        notes: "Discussion on UN Security Council restructuring.",
      ),
      ScheduleSession(
        id: "curated-session-2",
        title: "Themes in Indian History - Doubt Clearing",
        subject: "History",
        classLevel: "Class 12th",
        date: DateTime(y, m, d + 1 <= 28 ? d + 1 : 1).toIso8601String(),
        startTime: "02:00 PM",
        endTime: "03:30 PM",
        color: "#10B981",
        notes: "Source-based questions and timeline review.",
      ),
      ScheduleSession(
        id: "curated-session-3",
        title: "Weekly Assessment & Review",
        subject: "Political Science",
        classLevel: "Class 12",
        date: DateTime(y, m, d + 3 <= 28 ? d + 3 : 2).toIso8601String(),
        startTime: "11:00 AM",
        endTime: "12:30 PM",
        color: "#F59E0B",
        notes: "Answer evaluation for Chapter 4 assignment.",
      ),
    ];
  }

  static const List<NationalHoliday> _defaultNationalHolidays = [
    NationalHoliday(title: "Republic Day", date: "2026-01-26"),
    NationalHoliday(title: "Independence Day", date: "2026-08-15"),
    NationalHoliday(title: "Gandhi Jayanti", date: "2026-10-02"),
    NationalHoliday(title: "Diwali", date: "2026-11-08"),
  ];

  @override
  void initState() {
    super.initState();
    _todayKey = _toDateKey(_today.year, _today.month, _today.day);
    _selectedDateKey = _todayKey;
    _viewYear = _today.year;
    _viewMonth = _today.month;
    _sessions = _getCuratedSessions(_today);
    _nationalHolidays = List.from(_defaultNationalHolidays);
    _loading = false;
    _loadCachedSchedule(_viewYear);
    _fetchData(_viewYear);
  }

  void _loadCachedSchedule(int year) {
    final cached =
        CacheService.getSync<dynamic>('cached_teacher_schedule_${year}_v1');
    if (cached is Map) {
      _applyScheduleData(cached);
      _loading = false;
      return;
    }
    CacheService.get<dynamic>('cached_teacher_schedule_${year}_v1').then((data) {
      if (data is Map && mounted) {
        _applyScheduleData(data);
        setState(() => _loading = false);
      }
    });
  }

  void _applyScheduleData(Map<dynamic, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw);
    final rawSessions = (data['sessions'] as List?)
            ?.whereType<Map>()
            .map((e) => ScheduleSession.fromJson(e))
            .toList() ??
        [];
    final rawCustomHolidays = (data['customHolidays'] as List?)
            ?.whereType<Map>()
            .map((e) => CustomHoliday.fromJson(e))
            .toList() ??
        [];
    final rawNationalHolidays = (data['nationalHolidays'] as List?)
            ?.whereType<Map>()
            .map((e) => NationalHoliday.fromJson(e))
            .toList() ??
        [];

    setState(() {
      _sessions =
          rawSessions.isNotEmpty ? rawSessions : _getCuratedSessions(_today);
      _customHolidays = rawCustomHolidays;
      _nationalHolidays = rawNationalHolidays.isNotEmpty
          ? rawNationalHolidays
          : List.from(_defaultNationalHolidays);
    });
  }

  String _toDateKey(int y, int m, int d) {
    return "$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchData(int year) async {
    if (_sessions.isEmpty) {
      setState(() {
        _loading = true;
        _loadError = "";
      });
    }
    try {
      final response =
          await ref.read(dioProvider).get("/api/teacher/schedule?year=$year");
      if (response.data is Map && response.data['success'] == true) {
        if (mounted) {
          _applyScheduleData(response.data as Map);
        }
        CacheService.set('cached_teacher_schedule_${year}_v1', response.data);
      } else {
        if (mounted && _sessions.isEmpty) {
          setState(() {
            _sessions = _getCuratedSessions(_today);
            _nationalHolidays = List.from(_defaultNationalHolidays);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching schedule: $e");
      if (mounted && _sessions.isEmpty) {
        setState(() {
          _sessions = _getCuratedSessions(_today);
          _nationalHolidays = List.from(_defaultNationalHolidays);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    int m = _viewMonth + delta;
    int y = _viewYear;
    if (m < 1) {
      m = 12;
      y -= 1;
    }
    if (m > 12) {
      m = 1;
      y += 1;
    }

    bool needsFetch = (y != _viewYear);
    setState(() {
      _viewMonth = m;
      _viewYear = y;
    });
    if (needsFetch) _fetchData(y);
  }

  void _goToToday() {
    bool needsFetch = (_today.year != _viewYear);
    setState(() {
      _viewYear = _today.year;
      _viewMonth = _today.month;
      _selectedDateKey = _todayKey;
    });
    if (needsFetch) _fetchData(_today.year);
  }

  static const _dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  static const _dayNamesFull = [
    "Sunday", "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday"
  ];
  static const _monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  String _formatDateLabel(String dateKey) {
    try {
      final d = DateTime.parse("${dateKey}T00:00:00");
      return "${_dayNamesFull[d.weekday % 7]}, ${_monthNames[d.month - 1]} ${d.day}";
    } catch (_) {
      return dateKey;
    }
  }

  Future<void> _handleDeleteSession(String id) async {
    try {
      await ref
          .read(dioProvider)
          .delete("/api/teacher/schedule?type=session&id=$id");
      _fetchData(_viewYear);
    } catch (e) {
      debugPrint("Error deleting session: $e");
    }
  }

  Future<void> _handleDeleteHoliday(String id) async {
    try {
      await ref
          .read(dioProvider)
          .delete("/api/teacher/schedule?type=holiday&id=$id");
      _fetchData(_viewYear);
    } catch (e) {
      debugPrint("Error deleting holiday: $e");
    }
  }

  void _showSessionModal(BuildContext context, String dateKey,
      [ScheduleSession? session]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SessionFormModal(
        dateKey: dateKey,
        session: session,
        onSave: (payload) async {
          try {
            final response = payload['id'] != null
                ? await ref
                    .read(dioProvider)
                    .put("/api/teacher/schedule", data: payload)
                : await ref.read(dioProvider).post(
                    "/api/teacher/schedule",
                    data: {...payload, "type": "session"},
                  );
            if (response.data['success'] == true) {
              _fetchData(_viewYear);
              return true;
            }
          } catch (e) {
            debugPrint("Error saving session: $e");
          }
          return false;
        },
        onDelete: session != null
            ? () {
                Navigator.pop(ctx);
                _handleDeleteSession(session.id);
              }
            : null,
      ),
    );
  }

  void _showHolidayModal(BuildContext context, String dateKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HolidayFormModal(
        dateKey: dateKey,
        onSave: (title, date) async {
          try {
            final response = await ref.read(dioProvider).post(
              "/api/teacher/schedule",
              data: {"type": "holiday", "title": title, "date": date},
            );
            if (response.data['success'] == true) {
              _fetchData(_viewYear);
              return true;
            }
          } catch (e) {
            debugPrint("Error saving holiday: $e");
          }
          return false;
        },
      ),
    );
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return AppColors.indigo;
    try {
      String hex = colorStr.replaceAll("#", "");
      if (hex.length == 6) hex = "FF$hex";
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _sessions.isEmpty && _nationalHolidays.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.indigo),
        ),
      );
    }

    // Build Maps
    final Map<String, _HolidayInfo> holidaysByDate = {};
    for (var h in _nationalHolidays) {
      holidaysByDate[h.date] =
          _HolidayInfo(title: h.title, isCustom: false, tentative: h.tentative);
    }
    for (var h in _customHolidays) {
      final key = h.date.length >= 10 ? h.date.substring(0, 10) : h.date;
      holidaysByDate[key] =
          _HolidayInfo(title: h.title, isCustom: true, id: h.id);
    }

    final Map<String, List<ScheduleSession>> sessionsByDate = {};
    for (var s in _sessions) {
      final key = s.date.length >= 10 ? s.date.substring(0, 10) : s.date;
      sessionsByDate.putIfAbsent(key, () => []).add(s);
    }
    for (var list in sessionsByDate.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    // Calendar generation
    final firstDayWeekday = DateTime(_viewYear, _viewMonth, 1).weekday % 7;
    final daysInMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;
    final List<_CalendarCell> calendarCells = [];
    for (int i = 0; i < firstDayWeekday; i++) {
      calendarCells.add(const _CalendarCell(day: null, dateKey: null));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      calendarCells.add(_CalendarCell(
        day: d,
        dateKey: _toDateKey(_viewYear, _viewMonth, d),
      ));
    }

    // Statistics
    final totalSessions = _sessions.length;
    final holidaysThisMonth = calendarCells
        .where((c) => c.dateKey != null && holidaysByDate.containsKey(c.dateKey))
        .length;
    final scheduledDaysThisMonth = calendarCells
        .where((c) => c.dateKey != null && sessionsByDate.containsKey(c.dateKey))
        .length;
    final subjectCount = _sessions.map((s) => s.subject).toSet().length;
    final coverageRatio = daysInMonth > 0
        ? (scheduledDaysThisMonth / daysInMonth).clamp(0.0, 1.0)
        : 0.0;

    final selectedSessions = _selectedDateKey != null
        ? sessionsByDate[_selectedDateKey!] ?? []
        : <ScheduleSession>[];
    final selectedHoliday = _selectedDateKey != null
        ? holidaysByDate[_selectedDateKey!]
        : null;
    final selectedIsPast = _selectedDateKey != null
        ? _selectedDateKey!.compareTo(_todayKey) < 0
        : false;

    final cellWidth = (MediaQuery.of(context).size.width - 40 - 2) / 7;

    return SafeBackScope(
      fallbackLocation: '/teacher',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: AppColors.indigo,
            onRefresh: () => _fetchData(_viewYear),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Cinematic Hero Banner
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
                                Color(0x990F2027),
                                Color(0xCC203A43),
                                Color(0xF20F2027),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.14),
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.14),
                                          borderRadius: AppRadius.pillBorder,
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
                                              "Teaching Schedule",
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "${_monthNames[_viewMonth - 1]} $_viewYear",
                                        style: AppTypography.h1.copyWith(
                                          fontSize: 24,
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

                            // Glass Covered Panel
                            ClipRRect(
                              borderRadius: AppRadius.lgBorder,
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 16,
                                  sigmaY: 16,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    borderRadius: AppRadius.lgBorder,
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      ProgressRing(
                                        progress: coverageRatio,
                                        color: AppColors.mint,
                                        label: "COVERED",
                                      ),
                                      const SizedBox(width: AppSpacing.lg),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "THIS MONTH",
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: Colors.white
                                                    .withValues(alpha: 0.65),
                                                fontWeight: FontWeight.w600,
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
                                                    LucideIcons.bookOpen,
                                                    size: 12,
                                                    color: Colors.white70,
                                                  ),
                                                  value: totalSessions,
                                                  label: "sessions",
                                                ),
                                                MiniStat(
                                                  icon: const Icon(
                                                    LucideIcons.partyPopper,
                                                    size: 12,
                                                    color: Colors.white70,
                                                  ),
                                                  value: holidaysThisMonth,
                                                  label: "holidays",
                                                ),
                                                MiniStat(
                                                  icon: const Icon(
                                                    LucideIcons.calendar,
                                                    size: 12,
                                                    color: Colors.white70,
                                                  ),
                                                  value: subjectCount,
                                                  label: "subjects",
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

                // Error alert
                if (_loadError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: AppSpacing.md,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.coralTint,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.circleAlert,
                            size: 16,
                            color: AppColors.coral,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _loadError,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.coral,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 2. Calendar Card
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: AppSpacing.lg,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.lgBorder,
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Month Nav header
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              AnimatedPressable(
                                pressScale: 0.9,
                                onPress: () => _changeMonth(-1),
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    LucideIcons.chevronLeft,
                                    size: 20,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    "${_monthNames[_viewMonth - 1]} $_viewYear",
                                    style: AppTypography.label.copyWith(
                                      fontSize: 15,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  AnimatedPressable(
                                    pressScale: 0.95,
                                    onPress: _goToToday,
                                    child: Text(
                                      "Jump to Today",
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 11.5,
                                        color: AppColors.indigo,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedPressable(
                                pressScale: 0.9,
                                onPress: () => _changeMonth(1),
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    LucideIcons.chevronRight,
                                    size: 20,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: AppColors.border),

                        // Weekday Row
                        Row(
                          children: _dayNames
                              .map((d) => SizedBox(
                                    width: cellWidth,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        d,
                                        textAlign: TextAlign.center,
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.inkMuted,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        Divider(height: 1, color: AppColors.border),

                        // Date Grid
                        Wrap(
                          children: calendarCells.map((cell) {
                            if (cell.day == null) {
                              return Container(
                                width: cellWidth,
                                height: cellWidth,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom:
                                        BorderSide(color: AppColors.border),
                                    right:
                                        BorderSide(color: AppColors.border),
                                  ),
                                ),
                              );
                            }

                            final isToday = cell.dateKey == _todayKey;
                            final isPast =
                                cell.dateKey!.compareTo(_todayKey) < 0;
                            final isSelected =
                                cell.dateKey == _selectedDateKey;
                            final holiday = holidaysByDate[cell.dateKey!];
                            final daySessions =
                                sessionsByDate[cell.dateKey!] ?? [];

                            return AnimatedPressable(
                              pressScale: 0.94,
                              onPress: isPast
                                  ? null
                                  : () => setState(
                                        () => _selectedDateKey = cell.dateKey,
                                      ),
                              child: Container(
                                width: cellWidth,
                                height: cellWidth,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom:
                                        BorderSide(color: AppColors.border),
                                    right:
                                        BorderSide(color: AppColors.border),
                                  ),
                                  color: isSelected && !isPast
                                      ? AppColors.indigoTint
                                      : holiday != null && !isPast
                                          ? AppColors.coralTint
                                          : Colors.transparent,
                                ),
                                child: Opacity(
                                  opacity: isPast ? 0.35 : 1.0,
                                  child: Stack(
                                    children: [
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: isToday
                                            ? Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: AppColors.indigo,
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  "${cell.day}",
                                                  style: AppTypography.caption
                                                      .copyWith(
                                                    color: AppColors.white,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                "${cell.day}",
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: isPast
                                                      ? AppColors.inkFaint
                                                      : holiday != null
                                                          ? AppColors.coral
                                                          : AppColors.ink,
                                                ),
                                              ),
                                      ),
                                      if (holiday != null)
                                        Positioned(
                                          top: 18,
                                          left: 0,
                                          right: 0,
                                          child: Text(
                                            "🎉 ${holiday.title}",
                                            style: AppTypography.caption
                                                .copyWith(
                                              fontSize: 7,
                                              color: isPast
                                                  ? AppColors.inkFaint
                                                  : AppColors.coral,
                                              height: 1.1,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      if (daySessions.isNotEmpty)
                                        Positioned(
                                          bottom: 2,
                                          left: 2,
                                          child: Row(
                                            children: daySessions
                                                .take(3)
                                                .map((s) => Container(
                                                      width: 5,
                                                      height: 5,
                                                      margin:
                                                          const EdgeInsets.only(
                                                              right: 2),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: isPast
                                                            ? AppColors.inkFaint
                                                            : _parseColor(
                                                                s.color),
                                                      ),
                                                    ))
                                                .toList(),
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
                ),

                // 3. Selected Day Panel
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: AppSpacing.lg,
                    bottom: 32,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.lgBorder,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _selectedDateKey != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateLabel(_selectedDateKey!),
                                style: AppTypography.label.copyWith(
                                  fontSize: 14,
                                  color: AppColors.ink,
                                ),
                              ),
                              if (selectedIsPast)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.lg,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "This date has passed. Past sessions can't be modified.",
                                      style: AppTypography.body.copyWith(
                                        fontSize: 13,
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ),
                                )
                              else ...[
                                // Holiday banner or mark button
                                if (selectedHoliday != null)
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: AppSpacing.sm,
                                      bottom: AppSpacing.md,
                                    ),
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.coralTint,
                                      border: Border.all(
                                        color: AppColors.coral
                                            .withValues(alpha: 0.25),
                                      ),
                                      borderRadius: AppRadius.mdBorder,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          LucideIcons.partyPopper,
                                          size: 14,
                                          color: AppColors.coral,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            selectedHoliday.title,
                                            style:
                                                AppTypography.label.copyWith(
                                              fontSize: 13,
                                              color: AppColors.coral,
                                            ),
                                          ),
                                        ),
                                        if (selectedHoliday.tentative == true)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.coral
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  AppRadius.pillBorder,
                                            ),
                                            child: Text(
                                              "Tentative",
                                              style: AppTypography.caption
                                                  .copyWith(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.coral,
                                              ),
                                            ),
                                          ),
                                        if (selectedHoliday.isCustom &&
                                            selectedHoliday.id != null)
                                          AnimatedPressable(
                                            pressScale: 0.9,
                                            onPress: () =>
                                                _handleDeleteHoliday(
                                                    selectedHoliday.id!),
                                            child: Icon(
                                              LucideIcons.trash2,
                                              size: 14,
                                              color: AppColors.coral,
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.sm,
                                      bottom: AppSpacing.md,
                                    ),
                                    child: AnimatedPressable(
                                      pressScale: 0.97,
                                      onPress: () => _showHolidayModal(
                                        context,
                                        _selectedDateKey!,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.coral
                                                .withValues(alpha: 0.35),
                                            width: 1.5,
                                          ),
                                          borderRadius: AppRadius.mdBorder,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              LucideIcons.partyPopper,
                                              size: 14,
                                              color: AppColors.coral,
                                            ),
                                            const SizedBox(width: 7),
                                            Text(
                                              "Mark as Holiday",
                                              style:
                                                  AppTypography.label.copyWith(
                                                fontSize: 12.5,
                                                color: AppColors.coral,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                // Session cards
                                if (selectedSessions.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.lg,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "No sessions scheduled for this day.",
                                        style: AppTypography.body.copyWith(
                                          fontSize: 13,
                                          color: AppColors.inkMuted,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: selectedSessions.map((s) {
                                      final c = _parseColor(s.color);
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: AnimatedPressable(
                                          pressScale: 0.97,
                                          onPress: () => _showSessionModal(
                                            context,
                                            _selectedDateKey!,
                                            s,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(
                                              AppSpacing.md,
                                            ),
                                            decoration: BoxDecoration(
                                              color: c.withValues(alpha: 0.08),
                                              border: Border.all(
                                                color:
                                                    c.withValues(alpha: 0.35),
                                                width: 1.5,
                                              ),
                                              borderRadius: AppRadius.mdBorder,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s.title,
                                                  style: AppTypography.label
                                                      .copyWith(
                                                    fontSize: 13,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      LucideIcons.clock,
                                                      size: 11,
                                                      color: AppColors.inkFaint,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "${s.startTime} - ${s.endTime}",
                                                      style: AppTypography
                                                          .caption
                                                          .copyWith(
                                                        fontSize: 11.5,
                                                        color:
                                                            AppColors.inkMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 7),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.surface,
                                                        borderRadius:
                                                            AppRadius
                                                                .pillBorder,
                                                        border: Border.all(
                                                          color:
                                                              AppColors.border,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        s.subject,
                                                        style: AppTypography
                                                            .caption
                                                            .copyWith(
                                                          fontSize: 10,
                                                          color: AppColors
                                                              .inkMuted,
                                                        ),
                                                      ),
                                                    ),
                                                    if (s.classLevel != null &&
                                                        s.classLevel!
                                                            .isNotEmpty) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              AppColors.surface,
                                                          borderRadius:
                                                              AppRadius
                                                                  .pillBorder,
                                                          border: Border.all(
                                                            color: AppColors
                                                                .border,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          s.classLevel!,
                                                          style: AppTypography
                                                              .caption
                                                              .copyWith(
                                                            fontSize: 10,
                                                            color: AppColors
                                                                .inkMuted,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                // Add session dashed button
                                AnimatedPressable(
                                  pressScale: 0.97,
                                  onPress: () => _showSessionModal(
                                    context,
                                    _selectedDateKey!,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    margin: const EdgeInsets.only(
                                      top: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1.5,
                                      ),
                                      borderRadius: AppRadius.mdBorder,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.plus,
                                          size: 14,
                                          color: AppColors.inkMuted,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          "Add Session for This Day",
                                          style: AppTypography.label.copyWith(
                                            fontSize: 12.5,
                                            color: AppColors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xl,
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.indigoTint,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      LucideIcons.calendar,
                                      size: 26,
                                      color: AppColors.indigo,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    "Tap a date on the calendar to see or add sessions.",
                                    style: AppTypography.body.copyWith(
                                      fontSize: 13,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

class _CalendarCell {
  final int? day;
  final String? dateKey;
  const _CalendarCell({required this.day, required this.dateKey});
}

class _HolidayInfo {
  final String title;
  final bool isCustom;
  final bool? tentative;
  final String? id;

  _HolidayInfo({
    required this.title,
    required this.isCustom,
    this.tentative,
    this.id,
  });
}
