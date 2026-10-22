class TeacherNoteStats {
  final int totalBookmarks;

  TeacherNoteStats({required this.totalBookmarks});

  factory TeacherNoteStats.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return TeacherNoteStats(
      totalBookmarks: (json['totalBookmarks'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalBookmarks': totalBookmarks,
      };
}

class TeacherNote {
  final String id;
  final String title;
  final String? description;
  final String subject;
  final String className; // 'class' is a reserved keyword
  final String? topic;
  final String? chapter;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final String fileSize;
  final String? thumbnailUrl;
  final bool isPublished;
  final bool isPinned;
  final double price;
  final int downloads;
  final int views;
  final String createdAt;
  final TeacherNoteStats stats;

  TeacherNote({
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
    required this.isPublished,
    required this.isPinned,
    required this.price,
    required this.downloads,
    required this.views,
    required this.createdAt,
    required this.stats,
  });

  factory TeacherNote.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return TeacherNote(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      subject: json['subject']?.toString() ?? '',
      className: (json['class'] ?? json['className'])?.toString() ?? '',
      topic: json['topic']?.toString(),
      chapter: json['chapter']?.toString(),
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'Note.pdf',
      fileType: json['fileType']?.toString() ?? 'pdf',
      fileSize: json['fileSize']?.toString() ?? '1.0 MB',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      isPublished: json['isPublished'] == true,
      isPinned: json['isPinned'] == true,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      downloads: (json['downloads'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
      stats: json['stats'] is Map
          ? TeacherNoteStats.fromJson(json['stats'] as Map)
          : TeacherNoteStats(totalBookmarks: 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subject': subject,
        'class': className,
        'topic': topic,
        'chapter': chapter,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileType': fileType,
        'fileSize': fileSize,
        'thumbnailUrl': thumbnailUrl,
        'isPublished': isPublished,
        'isPinned': isPinned,
        'price': price,
        'downloads': downloads,
        'views': views,
        'createdAt': createdAt,
        'stats': stats.toJson(),
      };
}
