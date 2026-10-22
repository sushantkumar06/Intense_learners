class TeacherStudentProfile {
  final String id;
  final String userId;
  final String? name;
  final String? email;
  final String? avatar;
  final String? phone;
  final String? location;
  final String? dateOfBirth;
  final String? bio;

  TeacherStudentProfile({
    required this.id,
    required this.userId,
    this.name,
    this.email,
    this.avatar,
    this.phone,
    this.location,
    this.dateOfBirth,
    this.bio,
  });

  factory TeacherStudentProfile.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    final userMap = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : null;
    return TeacherStudentProfile(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? userMap?['id']?.toString() ?? '',
      name: userMap?['name']?.toString() ?? json['name']?.toString() ?? 'Student',
      email: userMap?['email']?.toString() ?? json['email']?.toString() ?? '',
      avatar: userMap?['avatar']?.toString() ?? json['avatar']?.toString(),
      phone: userMap?['phone']?.toString() ?? json['phone']?.toString(),
      location: userMap?['location']?.toString() ?? json['location']?.toString(),
      dateOfBirth: userMap?['dateOfBirth']?.toString() ?? json['dateOfBirth']?.toString(),
      bio: userMap?['bio']?.toString() ?? json['bio']?.toString(),
    );
  }
}

class TeacherSubmission {
  final String id;
  final String status;
  final bool isCompleted;
  final String fileUrl;
  final String fileName;
  final String fileSize;
  final String? remarks;
  final String submittedAt;
  final TeacherStudentProfile student;

  TeacherSubmission({
    required this.id,
    required this.status,
    required this.isCompleted,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    this.remarks,
    required this.submittedAt,
    required this.student,
  });

  factory TeacherSubmission.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return TeacherSubmission(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      isCompleted: json['isCompleted'] == true,
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'Submission.pdf',
      fileSize: json['fileSize']?.toString() ?? '1.2 MB',
      remarks: json['remarks']?.toString(),
      submittedAt: json['submittedAt']?.toString() ?? '',
      student: TeacherStudentProfile.fromJson(
        json['student'] is Map ? json['student'] as Map : {},
      ),
    );
  }
}

class TeacherAssignmentCommentUser {
  final String id;
  final String? name;
  final String? email;
  final String? avatar;
  final String role;

  TeacherAssignmentCommentUser({
    required this.id,
    this.name,
    this.email,
    this.avatar,
    required this.role,
  });

  factory TeacherAssignmentCommentUser.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return TeacherAssignmentCommentUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString() ?? 'STUDENT',
    );
  }
}

class TeacherAssignmentComment {
  final String id;
  final String content;
  final String createdAt;
  final TeacherAssignmentCommentUser user;

  TeacherAssignmentComment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.user,
  });

  factory TeacherAssignmentComment.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return TeacherAssignmentComment(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      user: TeacherAssignmentCommentUser.fromJson(
        json['user'] is Map ? json['user'] as Map : {},
      ),
    );
  }
}

class TeacherAssignmentStats {
  final int totalSubmissions;
  final int totalComments;

  TeacherAssignmentStats({
    required this.totalSubmissions,
    required this.totalComments,
  });

  factory TeacherAssignmentStats.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return TeacherAssignmentStats(
      totalSubmissions: (json['totalSubmissions'] as num?)?.toInt() ?? 0,
      totalComments: (json['totalComments'] as num?)?.toInt() ?? 0,
    );
  }
}

class TeacherAssignment {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String className;
  final String dueDate;
  final String fileUrl;
  final String? fileName;
  final String? fileSize;
  final bool isPublished;
  final String createdAt;
  final TeacherAssignmentStats stats;
  final List<TeacherSubmission> submissions;
  final List<TeacherAssignmentComment> comments;

  TeacherAssignment({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.className,
    required this.dueDate,
    required this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.isPublished,
    required this.createdAt,
    required this.stats,
    required this.submissions,
    required this.comments,
  });

  factory TeacherAssignment.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    final statsMap = json['stats'] is Map ? json['stats'] as Map : {};
    return TeacherAssignment(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      className: (json['class'] ?? json['className'])?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileName: json['fileName']?.toString(),
      fileSize: json['fileSize']?.toString(),
      isPublished: json['isPublished'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
      stats: TeacherAssignmentStats.fromJson(statsMap),
      submissions: (json['submissions'] as List?)
              ?.map((s) => TeacherSubmission.fromJson(s is Map ? s : {}))
              .toList() ??
          [],
      comments: (json['comments'] as List?)
              ?.map((c) => TeacherAssignmentComment.fromJson(c is Map ? c : {}))
              .toList() ??
          [],
    );
  }
}
