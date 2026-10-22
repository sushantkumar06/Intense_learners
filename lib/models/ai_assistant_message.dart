class AIAssistantMessage {
  final String id;
  final String content;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final String? fileSize;
  final String createdAt;
  final bool isAI;

  AIAssistantMessage({
    required this.id,
    required this.content,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    required this.createdAt,
    this.isAI = false,
  });

  factory AIAssistantMessage.fromJson(Map<String, dynamic> json) {
    return AIAssistantMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      createdAt: json['createdAt'] ?? '',
      isAI: json['isAI'] ?? false,
    );
  }
}
