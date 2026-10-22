class ChatSender {
  final String id;
  final String? name;
  final String? avatar;

  ChatSender({
    required this.id,
    this.name,
    this.avatar,
  });

  factory ChatSender.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return ChatSender(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
  };
}

class TeacherChatMessage {
  final String id;
  final String content;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final String? fileSize;
  final bool isRead;
  final List<String> readBy;
  final String createdAt;
  final String? updatedAt;
  final ChatSender sender;
  final bool isSelf;

  TeacherChatMessage({
    required this.id,
    required this.content,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    required this.isRead,
    required this.readBy,
    required this.createdAt,
    this.updatedAt,
    required this.sender,
    required this.isSelf,
  });

  factory TeacherChatMessage.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    final rawSender = json['sender'];
    return TeacherChatMessage(
      id: (json['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      fileUrl: json['fileUrl']?.toString(),
      fileName: json['fileName']?.toString(),
      fileType: json['fileType']?.toString(),
      fileSize: json['fileSize']?.toString(),
      isRead: json['isRead'] == true,
      readBy: (json['readBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: json['updatedAt']?.toString(),
      sender: ChatSender.fromJson(
        rawSender is Map ? rawSender : {},
      ),
      isSelf: json['isSelf'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'fileUrl': fileUrl,
    'fileName': fileName,
    'fileType': fileType,
    'fileSize': fileSize,
    'isRead': isRead,
    'readBy': readBy,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'sender': sender.toJson(),
    'isSelf': isSelf,
  };
}
