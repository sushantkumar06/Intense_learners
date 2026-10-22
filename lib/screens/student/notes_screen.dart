import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';
import '../../services/cache_service.dart';
import '../../theme/app_theme.dart';
import '../../components/ui/ui.dart';

const String _heroPhoto =
    "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=1200&q=80&auto=format&fit=crop";

const List<Map<String, String>> _filters = [
  {"value": "all", "label": "All"},
  {"value": "bookmarked", "label": "Saved"},
  {"value": "recent", "label": "Recent"},
  {"value": "popular", "label": "Popular"},
];

const List<List<Color>> _subjectGradients = [
  [AppColors.indigo, AppColors.indigoDark],
  [Color(0xFF8A6D1F), Color(0xFF5C4813)],
  [AppColors.mint, Color(0xFF1F6B45)],
  [AppColors.coral, Color(0xFF8E2E24)],
];

List<Color> _gradientForSubject(String subject) {
  int hash = 0;
  for (int i = 0; i < subject.length; i++) {
    hash = subject.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return _subjectGradients[hash.abs() % _subjectGradients.length];
}

class Note {
  final String id;
  final String title;
  final String? description;
  final String subject;
  final String className;
  final String? topic;
  final String? chapter;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final String fileSize;
  final String? thumbnailUrl;
  final bool isPinned;
  final int downloads;
  final int views;
  final DateTime createdAt;
  final Map<String, dynamic> teacher;
  final bool isBookmarked;
  final Map<String, dynamic> stats;

  Note({
    required this.id,
    required this.title,
    this.description,
    required this.subject,
    required this.className,
    this.topic,
    this.chapter,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.thumbnailUrl,
    required this.isPinned,
    required this.downloads,
    required this.views,
    required this.createdAt,
    required this.teacher,
    required this.isBookmarked,
    required this.stats,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    final rawTeacher = json['teacher'];
    final rawStats = json['stats'];
    return Note(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      subject: json['subject']?.toString() ?? '',
      className: (json['class'] ?? json['className'])?.toString() ?? '',
      topic: json['topic']?.toString(),
      chapter: json['chapter']?.toString(),
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      fileSize: json['fileSize']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      isPinned: json['isPinned'] == true,
      downloads: (json['downloads'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      teacher: rawTeacher is Map
          ? Map<String, dynamic>.from(rawTeacher)
          : <String, dynamic>{},
      isBookmarked: json['isBookmarked'] == true,
      stats: rawStats is Map
          ? Map<String, dynamic>.from(rawStats)
          : <String, dynamic>{'totalBookmarks': 0},
    );
  }

  Note copyWith({
    bool? isBookmarked,
    Map<String, dynamic>? stats,
    int? downloads,
    int? views,
  }) {
    return Note(
      id: id,
      title: title,
      description: description,
      subject: subject,
      className: className,
      topic: topic,
      chapter: chapter,
      fileUrl: fileUrl,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize,
      thumbnailUrl: thumbnailUrl,
      isPinned: isPinned,
      downloads: downloads ?? this.downloads,
      views: views ?? this.views,
      createdAt: createdAt,
      teacher: teacher,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      stats: stats ?? this.stats,
    );
  }
}

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  List<Note> _allNotes = List.from(_curatedNotes);
  bool _loading = false;

  String _searchQuery = "";
  final _searchController = TextEditingController();
  String _selectedFilter = "all";
  String _selectedSubject = "all";

  static final List<Note> _curatedNotes = [
    Note(
      id: "21f80a2a-c0a5-4659-b648-ffcdc97c54e2",
      title: "Chapter 4 International organization",
      subject: "Political science",
      className: "Class 12",
      topic: "English medium",
      chapter: "Chapter 4",
      fileUrl: "",
      fileName: "CH-6 INTERNET ORGANISATION ENG MED.pdf",
      fileType: "pdf",
      fileSize: "2.17 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7EhAsqHPOtDkgNljhrbIMy92iSXWpA3TLadFR",
      isPinned: true,
      downloads: 6,
      views: 40,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      teacher: const {"name": "Prakash Jha", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 3},
    ),
    Note(
      id: "843cda30-9b1f-44a6-9937-6fa43e6663f9",
      title: "Chapter 4 अन्तर्राष्ट्रीय संगठन (Hindi Medium)",
      subject: "Political science",
      className: "Class 12",
      topic: "Hindi medium",
      chapter: "Chapter 4",
      fileUrl: "",
      fileName: "ch 6 class 12th hindi med..pdf",
      fileType: "pdf",
      fileSize: "1.91 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7IqhvJWk6bdnqms4WvA7fZM9awlyk1eg2K3NO",
      isPinned: false,
      downloads: 2,
      views: 26,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      teacher: const {"name": "Prakash Jha", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 1},
    ),
    Note(
      id: "0c9ff82a-6a38-4841-979f-0469c73d287c",
      title: "Chapter 3 Kingship, Caste & Class (राजशाही, जाति और वर्ग)",
      subject: "History",
      className: "Class 12th",
      topic: "Hindi and English medium",
      chapter: "Chapter 3",
      fileUrl: "",
      fileName: "HISTORY CHAPTER 3 CLASS 12TH .pdf",
      fileType: "pdf",
      fileSize: "4.46 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7rZiD7ukGD1zV2uxwQZvENAY4bdXgaP69OtRT",
      isPinned: false,
      downloads: 4,
      views: 70,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      teacher: const {"name": "Prakash Jha", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 2},
    ),
    Note(
      id: "b2531fba-fd31-42ff-9326-2815fda7b6f3",
      title: "Chapter 3 Contemporary South Asia",
      subject: "Political science",
      className: "Class 12th",
      topic: "English medium",
      chapter: "Chapter 3",
      fileUrl: "",
      fileName: "DOC-20260501-WA0011..pdf",
      fileType: "pdf",
      fileSize: "2.27 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7CxHCp2zV3Ej98BKQLRyh4x7z5tm0OiTpWcsg",
      isPinned: false,
      downloads: 4,
      views: 20,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      teacher: const {"name": "Prakash Jha", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 1},
    ),
    Note(
      id: "f45cf941-114f-498d-a518-1d26c1b45fa5",
      title: "Chapter 3 Contemporary South Asia (Hindi Medium)",
      subject: "Political science",
      className: "Class 12th",
      topic: "Hindi medium",
      chapter: "Chapter 3",
      fileUrl: "",
      fileName: "DOC-20260501-WA0010..pdf",
      fileType: "pdf",
      fileSize: "2.48 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7WDlKYh4qld02kDIwEh5verzHJ1bBUWLG7gnZ",
      isPinned: false,
      downloads: 0,
      views: 16,
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
      teacher: const {"name": "Prakash Jha", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 0},
    ),
    Note(
      id: "44ce1e0a-7fd0-46e5-9492-07b23eb55018",
      title: "Class 12th Chapter 2 New Centre of Power (Hindi Medium)",
      subject: "Political science",
      className: "Class 12th",
      topic: "Hindi medium",
      chapter: "Chapter 2",
      fileUrl: "",
      fileName: "DOC-20260414-WA0001..pdf",
      fileType: "pdf",
      fileSize: "4.65 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7XOkz2l7qPWXDMIx8zU6Ol0NYsf2JtdRyToL3",
      isPinned: false,
      downloads: 0,
      views: 28,
      createdAt: DateTime.now().subtract(const Duration(days: 11)),
      teacher: const {"name": "Prakash Jha", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 0},
    ),
    Note(
      id: "925f491e-5172-4d81-ae4b-21d8bd385a98",
      title: "Class 12th Chapter 2 New Centre of Power (English Medium)",
      subject: "Political science",
      className: "Class 12th",
      topic: "English medium",
      chapter: "Chapter 2",
      fileUrl: "",
      fileName: "DOC-20260414-WA0000..pdf",
      fileType: "pdf",
      fileSize: "5.20 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7jMUpJrXcYsfedwDhXkR9cWxiFnV5O6Sp4Gg7",
      isPinned: false,
      downloads: 2,
      views: 26,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      teacher: const {"name": "Prakash Jha", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 1},
    ),
    Note(
      id: "3edcd417-8c46-4ecc-b92e-88091b155cd4",
      title: "Class 12th Chapter 1 End of Bipolarity (Hindi Medium)",
      subject: "Political science",
      className: "Class 12th",
      topic: "Hindi medium",
      chapter: "Chapter 1",
      fileUrl: "",
      fileName: "DOC-20260404-WA0011..pdf",
      fileType: "pdf",
      fileSize: "2.33 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7cILitxUPODLIuTYEfSwl0v54VWUtjdNzsHZr",
      isPinned: false,
      downloads: 1,
      views: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      teacher: const {"name": "Prakash Jha", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 0},
    ),
    Note(
      id: "760855aa-de6a-4226-ac96-d33670011a5a",
      title: "Class 12th Chapter 1 End of Bipolarity",
      subject: "Political science",
      className: "Class 12th",
      topic: "English medium",
      chapter: "Chapter 1",
      fileUrl: "",
      fileName: "DOC-20260404-WA0010..pdf",
      fileType: "pdf",
      fileSize: "1.88 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7LDI4J165pfsEKR6A2hFwlM5L0TcNUJ7GoxIr",
      isPinned: false,
      downloads: 0,
      views: 22,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      teacher: const {"name": "Prakash Jha", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 0},
    ),
    Note(
      id: "aa2b7fc6-528f-46c7-93cf-283e40a42617",
      title: "Class 12th History Chapter 1 (Bricks, Beads & Bones)",
      subject: "History",
      className: "Class 12th",
      topic: "Harappan Civilization",
      chapter: "Chapter 1",
      fileUrl: "",
      fileName: "DOC-20260409-WA0007..pdf",
      fileType: "pdf",
      fileSize: "5.61 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7uuXmIfJfAeBoyqzghlRrkKDXisE19Jd78TOw",
      isPinned: false,
      downloads: 1,
      views: 28,
      createdAt: DateTime.now().subtract(const Duration(days: 16)),
      teacher: const {"name": "Prakash Jha", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 1},
    ),
    Note(
      id: "53ddf573-1b96-4b9c-8b51-768696f1ccaa",
      title: "Chapter 2 History Class 12th (Kings, Farmers & Towns)",
      subject: "History",
      className: "Class 12",
      topic: "Early States & Economies",
      chapter: "Chapter 2",
      fileUrl: "",
      fileName: "HISTORY CH 2 CLASS 12TH.pdf",
      fileType: "pdf",
      fileSize: "5.71 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7dkEhcsO1oaLWbEM0rUmJXQShHVnICpAKqdec",
      isPinned: false,
      downloads: 4,
      views: 52,
      createdAt: DateTime.now().subtract(const Duration(days: 17)),
      teacher: const {"name": "Prakash Jha", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 2},
    ),
    Note(
      id: "8ed6ce1b-cfb0-4dcd-9c89-ec1c6eaf143a",
      title: "Class 10th NCERT Mathematics Chapter 2 (Polynomials)",
      subject: "Mathematics",
      className: "Class 10th",
      topic: "Polynomials",
      chapter: "Chapter 2",
      fileUrl: "",
      fileName: "CLass-10th Polynomials.pdf",
      fileType: "pdf",
      fileSize: "0.36 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7XZb6WD7qPWXDMIx8zU6Ol0NYsf2JtdRyToL3",
      isPinned: false,
      downloads: 6,
      views: 13,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      teacher: const {"name": "Saqib Nadeem", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 1},
    ),
    Note(
      id: "09df1b19-209c-47fa-b8e0-6df3a1a9af5e",
      title: "Class 10th NCERT Mathematics Chapter 1 (Real Numbers)",
      subject: "Mathematics",
      className: "Class 10th",
      topic: "Real Numbers",
      chapter: "Chapter 1",
      fileUrl: "",
      fileName: "CLass-10th Real Numbers.pdf",
      fileType: "pdf",
      fileSize: "0.37 MB",
      thumbnailUrl: "https://utfs.io/f/hVmmOFsyRMA7I5lmNQk6bdnqms4WvA7fZM9awlyk1eg2K3NO",
      isPinned: false,
      downloads: 3,
      views: 9,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      teacher: const {"name": "Saqib Nadeem", "avatar": null},
      isBookmarked: false,
      stats: const {"totalBookmarks": 1},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedNotes();
    _fetchNotes();
  }

  void _loadCachedNotes() {
    final cached = CacheService.getSync<List<dynamic>>('cached_student_notes_v1');
    if (cached != null && cached.isNotEmpty) {
      try {
        _allNotes = cached.map((e) => Note.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        _loading = false;
      } catch (e) {
        debugPrint("Error reading cached notes: $e");
        _allNotes = _curatedNotes;
        _loading = false;
      }
    } else {
      // Instantly load curated notes so the screen never displays an empty state or wait spinner
      _allNotes = _curatedNotes;
      _loading = false;
      CacheService.get<List<dynamic>>('cached_student_notes_v1').then((data) {
        if (data != null && data.isNotEmpty && mounted) {
          try {
            setState(() {
              _allNotes = data.map((e) => Note.fromJson(Map<String, dynamic>.from(e as Map))).toList();
            });
          } catch (e) {
            debugPrint("Error parsing async cached notes: $e");
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

  Future<void> _fetchNotes({bool isRefresh = false}) async {
    if (!isRefresh && _allNotes.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final dio = ref.read(dioProvider);
      List<dynamic> notesData = [];

      try {
        final response = await dio.get("/api/student/notes");
        if (response.data != null && response.data['success'] == true) {
          final list = response.data['notes'];
          if (list is List && list.isNotEmpty) {
            notesData = list;
          }
        }
      } catch (studentErr) {
        debugPrint("Primary /api/student/notes error: $studentErr");
      }

      // Fallback to public /api/payments?action=notes if primary returned no notes or errored
      if (notesData.isEmpty) {
        try {
          final fallbackRes = await dio.get("/api/payments?action=notes");
          if (fallbackRes.data != null && fallbackRes.data['success'] == true) {
            final list = fallbackRes.data['notes'];
            if (list is List && list.isNotEmpty) {
              notesData = list;
            }
          }
        } catch (fbErr) {
          debugPrint("Fallback /api/payments?action=notes error: $fbErr");
        }
      }

      if (notesData.isNotEmpty && mounted) {
        final parsed = notesData
            .map((e) => Note.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        setState(() {
          _allNotes = parsed;
        });
        CacheService.set('cached_student_notes_v1', notesData);
      } else if (_allNotes.isEmpty && mounted) {
        setState(() {
          _allNotes = _curatedNotes;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notes: $e");
      if (_allNotes.isEmpty && mounted) {
        setState(() {
          _allNotes = _curatedNotes;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _subjects {
    final Map<String, String> normalizedMap = {};
    for (final note in _allNotes) {
      final trimmed = note.subject.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (!normalizedMap.containsKey(key)) {
        normalizedMap[key] = trimmed;
      }
    }
    final list = normalizedMap.values.toList()..sort();
    return list;
  }

  List<Note> get _filteredNotes {
    List<Note> notes = List.from(_allNotes);

    if (_selectedFilter == "bookmarked") {
      notes = notes.where((n) => n.isBookmarked).toList();
    } else if (_selectedFilter == "recent") {
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedFilter == "popular") {
      notes.sort((a, b) => b.downloads.compareTo(a.downloads));
    }

    if (_selectedSubject != "all") {
      final sel = _selectedSubject.trim().toLowerCase();
      notes = notes.where((n) => n.subject.trim().toLowerCase() == sel).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      notes = notes.where((n) {
        return n.title.toLowerCase().contains(q) ||
            (n.description?.toLowerCase().contains(q) ?? false) ||
            (n.topic?.toLowerCase().contains(q) ?? false) ||
            (n.chapter?.toLowerCase().contains(q) ?? false) ||
            n.subject.toLowerCase().contains(q);
      }).toList();
    }

    return notes;
  }

  Future<void> _handleBookmark(String noteId) async {
    setState(() {
      _allNotes = _allNotes.map((n) {
        if (n.id == noteId) {
          final newSaved = !n.isBookmarked;
          final currentCount =
              (n.stats['totalBookmarks'] as num?)?.toInt() ?? 0;
          return n.copyWith(
            isBookmarked: newSaved,
            stats: {
              'totalBookmarks': newSaved ? currentCount + 1 : currentCount - 1,
            },
          );
        }
        return n;
      }).toList();
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.patch("/api/student/notes", data: {"noteId": noteId});
    } catch (e) {
      debugPrint("Bookmark error: $e");
      _fetchNotes(isRefresh: true);
    }
  }

  Future<void> _handleDownload(Note note) async {
    setState(() {
      _allNotes = _allNotes.map((n) {
        return n.id == note.id ? n.copyWith(downloads: n.downloads + 1) : n;
      }).toList();
    });

    if (note.fileUrl.isNotEmpty) {
      final uri = Uri.tryParse(note.fileUrl);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download link is being prepared")),
      );
    }

    try {
      final dio = ref.read(dioProvider);
      await dio.post("/api/student/notes", data: {
        "noteId": note.id,
        "action": "download",
      });
    } catch (e) {
      debugPrint("Download track error: $e");
    }
  }

  Future<void> _handleView(Note note) async {
    setState(() {
      _allNotes = _allNotes.map((n) {
        return n.id == note.id ? n.copyWith(views: n.views + 1) : n;
      }).toList();
    });

    if (note.fileUrl.isNotEmpty) {
      final uri = Uri.tryParse(note.fileUrl);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      _showNoteDetailsModal(note);
    }

    try {
      final dio = ref.read(dioProvider);
      await dio.post("/api/student/notes", data: {
        "noteId": note.id,
        "action": "view",
      });
    } catch (e) {
      debugPrint("View track error: $e");
    }
  }

  void _showNoteDetailsModal(Note note) {
    final gradient = _gradientForSubject(note.subject);
    final teacherName = (note.teacher['name'] ?? 'Faculty Instructor').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.pillBorder,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Top Badges
            Row(
              children: [
                AppBadge(label: note.subject, tone: AppBadgeTone.brand),
                const SizedBox(width: 8),
                AppBadge(label: note.className, tone: AppBadgeTone.neutral),
                if (note.chapter != null) ...[
                  const SizedBox(width: 8),
                  AppBadge(label: note.chapter!, tone: AppBadgeTone.gold),
                ],
                const Spacer(),
                AnimatedPressable(
                  pressScale: 0.85,
                  onPress: () {
                    Navigator.pop(ctx);
                    _handleBookmark(note.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: note.isBookmarked ? AppColors.indigoTint : AppColors.surfaceMuted,
                      borderRadius: AppRadius.smBorder,
                    ),
                    child: Icon(
                      note.isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                      size: 18,
                      color: note.isBookmarked ? AppColors.indigo : AppColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              note.title,
              style: AppTypography.h3.copyWith(
                color: AppColors.ink,
                fontSize: 18,
                height: 1.3,
              ),
            ),
            if (note.topic != null && note.topic!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "Topic: ${note.topic}",
                style: AppTypography.body.copyWith(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Cover Image or Subject Gradient Preview
            if (note.thumbnailUrl != null && note.thumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: AppRadius.mdBorder,
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: Image.network(
                    note.thumbnailUrl!,
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                    errorBuilder: (_, _, _) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.fileText, size: 40, color: Colors.white),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: AppRadius.mdBorder,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.fileText, size: 36, color: Colors.white),
                    const SizedBox(height: 6),
                    Text(
                      "${note.fileType.toUpperCase()} Study Document",
                      style: AppTypography.label.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Details info tiles
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        note.fileSize.isNotEmpty ? note.fileSize : "PDF",
                        style: AppTypography.label.copyWith(color: AppColors.ink, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text("File Size", style: AppTypography.caption.copyWith(color: AppColors.inkFaint, fontSize: 11)),
                    ],
                  ),
                  Container(width: 1, height: 26, color: AppColors.border),
                  Column(
                    children: [
                      Text(
                        "${note.downloads}",
                        style: AppTypography.label.copyWith(color: AppColors.ink, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text("Downloads", style: AppTypography.caption.copyWith(color: AppColors.inkFaint, fontSize: 11)),
                    ],
                  ),
                  Container(width: 1, height: 26, color: AppColors.border),
                  Column(
                    children: [
                      Text(
                        "${note.views}",
                        style: AppTypography.label.copyWith(color: AppColors.ink, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text("Views", style: AppTypography.caption.copyWith(color: AppColors.inkFaint, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Teacher info
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.indigoTint,
                  child: Text(
                    teacherName.isNotEmpty ? teacherName[0].toUpperCase() : "T",
                    style: TextStyle(color: AppColors.indigo, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherName,
                        style: AppTypography.label.copyWith(color: AppColors.ink, fontSize: 13),
                      ),
                      Text(
                        "Faculty Instructor",
                        style: AppTypography.caption.copyWith(color: AppColors.inkMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: note.isBookmarked ? "Saved" : "Bookmark",
                    variant: AppButtonVariant.secondary,
                    icon: note.isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                    onPress: () {
                      Navigator.pop(ctx);
                      _handleBookmark(note.id);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: "Download",
                    variant: AppButtonVariant.primary,
                    icon: LucideIcons.download,
                    onPress: () {
                      Navigator.pop(ctx);
                      _handleDownload(note);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalNotes = _allNotes.length;
    final bookmarkedNotes = _allNotes.where((n) => n.isBookmarked).length;
    final totalDownloads =
        _allNotes.fold<int>(0, (sum, n) => sum + n.downloads);
    final pinnedNotes = _allNotes.where((n) => n.isPinned).length;

    if (_loading && _allNotes.isEmpty) {
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
                Text("Loading your notes…"),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _filteredNotes;

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
        onRefresh: () => _fetchNotes(isRefresh: true),
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
                        bottom: 26,
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
                                  LucideIcons.folderOpen,
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
                                      "Notes Library",
                                      style: AppTypography.h2.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      "Study materials from your teachers",
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
                          const SizedBox(height: 18),

                          // Glass MiniStat Bar
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: AppRadius.lgBorder,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 1,
                              ),
                            ),
                            child: Wrap(
                              spacing: 18,
                              runSpacing: 10,
                              children: [
                                MiniStat(
                                  icon: const Icon(
                                    LucideIcons.fileText,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  value: totalNotes,
                                  label: "notes",
                                ),
                                MiniStat(
                                  icon: const Icon(
                                    LucideIcons.bookmarkCheck,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  value: bookmarkedNotes,
                                  label: "saved",
                                ),
                                MiniStat(
                                  icon: const Icon(
                                    LucideIcons.download,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  value: totalDownloads,
                                  label: "downloads",
                                ),
                                MiniStat(
                                  icon: const Icon(
                                    LucideIcons.star,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  value: pinnedNotes,
                                  label: "pinned",
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

            // Search, Segmented Control & Subject Chips
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
                      placeholder: "Search notes, topics, subjects…",
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

                    // Continuous Segmented Control Filter Bar
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Row(
                        children: _filters.map((f) {
                          final active = _selectedFilter == f['value'];
                          return Expanded(
                            child: AnimatedPressable(
                              pressScale: 0.97,
                              onPress: () =>
                                  setState(() => _selectedFilter = f['value']!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.surface
                                      : Colors.transparent,
                                  borderRadius: AppRadius.smBorder,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  f['label']!,
                                  style: AppTypography.caption.copyWith(
                                    color: active
                                        ? AppColors.indigo
                                        : AppColors.inkMuted,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
                  ],
                ),
              ),
            ),

            // Notes 2-Column Grid / Empty State
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 48,
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
                        _searchQuery.isNotEmpty
                            ? "No matching notes found"
                            : _selectedFilter == "bookmarked"
                                ? "No saved notes yet"
                                : _selectedSubject != "all"
                                    ? "No notes for $_selectedSubject"
                                    : "No notes found",
                        style: AppTypography.label.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _searchQuery.isNotEmpty
                            ? "No notes matched '$_searchQuery'. Try checking spelling or another keyword."
                            : _selectedFilter == "bookmarked"
                                ? "Tap the bookmark icon on any note card to save it for quick revision."
                                : _selectedSubject != "all"
                                    ? "There are currently no notes uploaded under $_selectedSubject."
                                    : "Your teachers haven't uploaded notes yet. Check back soon!",
                        style: AppTypography.body.copyWith(
                          fontSize: 13,
                          color: AppColors.inkMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_searchQuery.isNotEmpty || _selectedFilter != "all" || _selectedSubject != "all")
                        AppButton(
                          label: "Reset All Filters",
                          variant: AppButtonVariant.secondary,
                          icon: LucideIcons.rotateCcw,
                          onPress: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                              _selectedFilter = "all";
                              _selectedSubject = "all";
                            });
                          },
                        ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 12.0;
                    final cardWidth = (constraints.crossAxisExtent - gap) / 2;

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: gap,
                        mainAxisSpacing: gap,
                        childAspectRatio: cardWidth / (cardWidth * 0.80 + 192),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final note = filtered[index];
                          return RepaintBoundary(
                            child: _buildNoteCard(note, cardWidth),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    );
                  },
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

  Widget _buildNoteCard(Note note, double cardWidth) {
    final thumbHeight = cardWidth * 0.80;
    final gradient = _gradientForSubject(note.subject);

    return AnimatedPressable(
      pressScale: 0.98,
      onPress: () => _handleView(note),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail area
          SizedBox(
            height: thumbHeight,
            width: double.infinity,
            child: Stack(
              children: [
                if (note.thumbnailUrl != null && note.thumbnailUrl!.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      note.thumbnailUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                      errorBuilder: (_, _, _) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.fileText,
                          size: 28,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          note.subject,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Pinned tag
                if (note.isPinned)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: AppRadius.smBorder,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.star,
                            size: 9,
                            color: AppColors.white,
                          ),
                          SizedBox(width: 3),
                          Text(
                            "Pinned",
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bookmark action button
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedPressable(
                    pressScale: 0.85,
                    onPress: () => _handleBookmark(note.id),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: note.isBookmarked
                            ? AppColors.indigo
                            : Colors.white.withValues(alpha: 0.92),
                        borderRadius: AppRadius.smBorder,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        note.isBookmarked
                            ? LucideIcons.bookmarkCheck
                            : LucideIcons.bookmark,
                        size: 14,
                        color: note.isBookmarked
                            ? AppColors.white
                            : AppColors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body Details
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppBadge(
                      label: note.subject,
                      tone: AppBadgeTone.brand,
                    ),
                    if (note.chapter != null) ...[
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Ch. ${note.chapter}",
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkFaint,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                SizedBox(
                  height: 34,
                  child: Text(
                    note.title,
                    style: AppTypography.label.copyWith(
                      color: AppColors.ink,
                      fontSize: 12.5,
                      height: 16.5 / 12.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),

                // Downloads & views
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.download,
                          size: 10,
                          color: AppColors.inkFaint,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "${note.downloads}",
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkFaint,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.eye,
                          size: 10,
                          color: AppColors.inkFaint,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "${note.views}",
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkFaint,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // View & Get Buttons
                Row(
                  children: [
                    Expanded(
                      child: AnimatedPressable(
                        pressScale: 0.93,
                        onPress: () => _handleView(note),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.indigo,
                              width: 1.5,
                            ),
                            borderRadius: AppRadius.smBorder,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.eye,
                                size: 12,
                                color: AppColors.indigo,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "View",
                                style: AppTypography.label.copyWith(
                                  color: AppColors.indigo,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedPressable(
                        pressScale: 0.93,
                        onPress: () => _handleDownload(note),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.indigo,
                            borderRadius: AppRadius.smBorder,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                LucideIcons.download,
                                size: 12,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Get",
                                style: AppTypography.label.copyWith(
                                  color: AppColors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                Center(
                  child: Text(
                    "${note.fileType.toUpperCase()} · ${note.fileSize}",
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkFaint,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
