class AssignmentSubmission {
  final String id;
  final String fileUrl;
  final String fileName;
  final String fileSize;
  final String? remarks;
  final String status;
  final bool isCompleted;
  final DateTime submittedAt;

  AssignmentSubmission({
    required this.id,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    this.remarks,
    required this.status,
    required this.isCompleted,
    required this.submittedAt,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      id: json['id']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      fileSize: json['fileSize']?.toString() ?? '',
      remarks: json['remarks']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      isCompleted: json['isCompleted'] == true,
      submittedAt: json['submittedAt'] != null
          ? (DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  AssignmentSubmission copyWith({
    bool? isCompleted,
    String? status,
  }) {
    return AssignmentSubmission(
      id: id,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      remarks: remarks,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      submittedAt: submittedAt,
    );
  }
}

class StudentAssignment {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String className;
  final DateTime dueDate;
  final int totalMarks;
  final String? fileUrl;
  final String? fileName;
  final String? fileSize;
  final DateTime createdAt;
  final Map<String, dynamic> teacher;
  final AssignmentSubmission? mySubmission;
  final Map<String, dynamic> stats;

  StudentAssignment({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.className,
    required this.dueDate,
    required this.totalMarks,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.createdAt,
    required this.teacher,
    this.mySubmission,
    required this.stats,
  });

  factory StudentAssignment.fromJson(Map<String, dynamic> json) {
    final rawTeacher = json['teacher'];
    final rawSubmission = json['mySubmission'];
    final rawStats = json['stats'];

    return StudentAssignment(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      className: (json['class'] ?? json['className'])?.toString() ?? '',
      dueDate: json['dueDate'] != null
          ? (DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 0,
      fileUrl: json['fileUrl']?.toString(),
      fileName: json['fileName']?.toString(),
      fileSize: json['fileSize']?.toString(),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      teacher: rawTeacher is Map
          ? Map<String, dynamic>.from(rawTeacher)
          : <String, dynamic>{},
      mySubmission: rawSubmission is Map
          ? AssignmentSubmission.fromJson(Map<String, dynamic>.from(rawSubmission))
          : null,
      stats: rawStats is Map
          ? Map<String, dynamic>.from(rawStats)
          : <String, dynamic>{'totalSubmissions': 0, 'totalComments': 0},
    );
  }

  StudentAssignment copyWith({
    AssignmentSubmission? mySubmission,
  }) {
    return StudentAssignment(
      id: id,
      title: title,
      description: description,
      subject: subject,
      className: className,
      dueDate: dueDate,
      totalMarks: totalMarks,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      createdAt: createdAt,
      teacher: teacher,
      mySubmission: mySubmission ?? this.mySubmission,
      stats: stats,
    );
  }
}

class AssignmentComment {
  final String id;
  final String content;
  final String? fileUrl;
  final String? fileName;
  final String? fileSize;
  final int likes;
  final DateTime createdAt;
  final Map<String, dynamic> user;

  AssignmentComment({
    required this.id,
    required this.content,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.likes,
    required this.createdAt,
    required this.user,
  });

  factory AssignmentComment.fromJson(Map<String, dynamic> json) {
    return AssignmentComment(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      likes: json['likes'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      user: json['user'] ?? {},
    );
  }

  AssignmentComment copyWith({
    int? likes,
  }) {
    return AssignmentComment(
      id: id,
      content: content,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      likes: likes ?? this.likes,
      createdAt: createdAt,
      user: user,
    );
  }
}
