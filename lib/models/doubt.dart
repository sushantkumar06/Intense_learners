class DoubtUser {
  final String id;
  final String name;
  final String? avatar;
  final String? email;
  final String? role;

  DoubtUser({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
    this.role,
  });

  factory DoubtUser.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return DoubtUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      avatar: json['avatar']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class DoubtReply {
  final String id;
  final String content;
  final String? imageUrl;
  final String? imageName;
  final String? pdfUrl;
  final String? pdfName;
  final bool isPinned;
  final bool isAccepted;
  final int upvotes;
  final String createdAt;
  final DoubtUser user;
  final bool isMyReply;
  final bool hasUpvoted;

  DoubtReply({
    required this.id,
    required this.content,
    this.imageUrl,
    this.imageName,
    this.pdfUrl,
    this.pdfName,
    required this.isPinned,
    required this.isAccepted,
    required this.upvotes,
    required this.createdAt,
    required this.user,
    required this.isMyReply,
    required this.hasUpvoted,
  });

  DoubtReply copyWith({
    String? id,
    String? content,
    String? imageUrl,
    String? imageName,
    String? pdfUrl,
    String? pdfName,
    bool? isPinned,
    bool? isAccepted,
    int? upvotes,
    String? createdAt,
    DoubtUser? user,
    bool? isMyReply,
    bool? hasUpvoted,
  }) {
    return DoubtReply(
      id: id ?? this.id,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      imageName: imageName ?? this.imageName,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfName: pdfName ?? this.pdfName,
      isPinned: isPinned ?? this.isPinned,
      isAccepted: isAccepted ?? this.isAccepted,
      upvotes: upvotes ?? this.upvotes,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      isMyReply: isMyReply ?? this.isMyReply,
      hasUpvoted: hasUpvoted ?? this.hasUpvoted,
    );
  }

  factory DoubtReply.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    final rawUser = json['user'];
    return DoubtReply(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      imageName: json['imageName']?.toString(),
      pdfUrl: json['pdfUrl']?.toString(),
      pdfName: json['pdfName']?.toString(),
      isPinned: json['isPinned'] == true,
      isAccepted: json['isAccepted'] == true,
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
      user: DoubtUser.fromJson(
        rawUser is Map ? Map<String, dynamic>.from(rawUser) : {},
      ),
      isMyReply: json['isMyReply'] == true,
      hasUpvoted: json['hasUpvoted'] == true,
    );
  }
}

class DoubtStats {
  final int totalReplies;
  final int totalUpvotes;

  DoubtStats({
    required this.totalReplies,
    required this.totalUpvotes,
  });

  factory DoubtStats.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return DoubtStats(
      totalReplies: (json['totalReplies'] as num?)?.toInt() ?? 0,
      totalUpvotes: (json['totalUpvotes'] as num?)?.toInt() ?? 0,
    );
  }
}

class Doubt {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String? classLevel;
  final String priority;
  final String? imageUrl;
  final String? imageName;
  final String? pdfUrl;
  final String? pdfName;
  final String status;
  final bool isSolved;
  final int upvotes;
  final int views;
  final String createdAt;
  final DoubtUser student;
  final bool isMyDoubt;
  final bool hasUpvoted;
  final DoubtStats stats;
  final List<DoubtReply> replies;

  Doubt({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    this.classLevel,
    required this.priority,
    this.imageUrl,
    this.imageName,
    this.pdfUrl,
    this.pdfName,
    required this.status,
    required this.isSolved,
    required this.upvotes,
    required this.views,
    required this.createdAt,
    required this.student,
    required this.isMyDoubt,
    required this.hasUpvoted,
    required this.stats,
    required this.replies,
  });

  Doubt copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? classLevel,
    String? priority,
    String? imageUrl,
    String? imageName,
    String? pdfUrl,
    String? pdfName,
    String? status,
    bool? isSolved,
    int? upvotes,
    int? views,
    String? createdAt,
    DoubtUser? student,
    bool? isMyDoubt,
    bool? hasUpvoted,
    DoubtStats? stats,
    List<DoubtReply>? replies,
  }) {
    return Doubt(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      classLevel: classLevel ?? this.classLevel,
      priority: priority ?? this.priority,
      imageUrl: imageUrl ?? this.imageUrl,
      imageName: imageName ?? this.imageName,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfName: pdfName ?? this.pdfName,
      status: status ?? this.status,
      isSolved: isSolved ?? this.isSolved,
      upvotes: upvotes ?? this.upvotes,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
      student: student ?? this.student,
      isMyDoubt: isMyDoubt ?? this.isMyDoubt,
      hasUpvoted: hasUpvoted ?? this.hasUpvoted,
      stats: stats ?? this.stats,
      replies: replies ?? this.replies,
    );
  }

  factory Doubt.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    final rawStudent = json['student'];
    final rawStats = json['stats'];
    return Doubt(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      classLevel: (json['class'] ?? json['classLevel'])?.toString(),
      priority: json['priority']?.toString() ?? 'normal',
      imageUrl: json['imageUrl']?.toString(),
      imageName: json['imageName']?.toString(),
      pdfUrl: json['pdfUrl']?.toString(),
      pdfName: json['pdfName']?.toString(),
      status: json['status']?.toString() ?? 'open',
      isSolved: json['isSolved'] == true,
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
      student: DoubtUser.fromJson(
        rawStudent is Map ? Map<String, dynamic>.from(rawStudent) : {},
      ),
      isMyDoubt: json['isMyDoubt'] == true,
      hasUpvoted: json['hasUpvoted'] == true,
      stats: DoubtStats.fromJson(
        rawStats is Map ? Map<String, dynamic>.from(rawStats) : {},
      ),
      replies: (json['replies'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => DoubtReply.fromJson(e))
              .toList() ??
          [],
    );
  }
}
