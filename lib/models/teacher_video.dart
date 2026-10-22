class TeacherVideoItem {
  final String id;
  final String title;
  final String description;
  final String duration;
  final int views;
  final int uniqueViewers;
  final String totalWatchTime;
  final String uploadDate;
  final String thumbnail;
  final String videoUrl;
  final String size;
  final String quality;

  TeacherVideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.views,
    required this.uniqueViewers,
    required this.totalWatchTime,
    required this.uploadDate,
    required this.thumbnail,
    required this.videoUrl,
    required this.size,
    required this.quality,
  });

  factory TeacherVideoItem.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return TeacherVideoItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
      views: (json['views'] as num?)?.toInt() ?? 0,
      uniqueViewers: (json['uniqueViewers'] as num?)?.toInt() ?? 0,
      totalWatchTime: (json['totalWatchTime'] ?? '').toString(),
      uploadDate: (json['uploadDate'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      videoUrl: (json['videoUrl'] ?? '').toString(),
      size: (json['size'] ?? '').toString(),
      quality: (json['quality'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'duration': duration,
    'views': views,
    'uniqueViewers': uniqueViewers,
    'totalWatchTime': totalWatchTime,
    'uploadDate': uploadDate,
    'thumbnail': thumbnail,
    'videoUrl': videoUrl,
    'size': size,
    'quality': quality,
  };
}

class TeacherVideoFolder {
  final String id;
  final String name;
  final String subject;
  final String className;
  final String chapter;
  final String description;
  final String thumbnail;
  final bool isPublic;
  final String? youtubePlaylistId;
  final int videoCount;
  final String totalDuration;
  final int totalViews;
  final String totalWatchTime;
  final String createdAt;
  final List<TeacherVideoItem> videos;

  TeacherVideoFolder({
    required this.id,
    required this.name,
    required this.subject,
    required this.className,
    required this.chapter,
    required this.description,
    required this.thumbnail,
    required this.isPublic,
    this.youtubePlaylistId,
    required this.videoCount,
    required this.totalDuration,
    required this.totalViews,
    required this.totalWatchTime,
    required this.createdAt,
    required this.videos,
  });

  factory TeacherVideoFolder.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    final rawVideos = json['videos'];
    List<TeacherVideoItem> parsedVideos = [];
    if (rawVideos is List) {
      for (final item in rawVideos) {
        if (item is Map) {
          parsedVideos.add(TeacherVideoItem.fromJson(item));
        }
      }
    }

    return TeacherVideoFolder(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      className: (json['class'] ?? json['className'] ?? '').toString(),
      chapter: (json['chapter'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      isPublic: json['isPublic'] is bool ? json['isPublic'] as bool : true,
      youtubePlaylistId: json['youtubePlaylistId']?.toString(),
      videoCount: (json['videoCount'] as num?)?.toInt() ?? parsedVideos.length,
      totalDuration: (json['totalDuration'] ?? '').toString(),
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      totalWatchTime: (json['totalWatchTime'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      videos: parsedVideos,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subject': subject,
    'class': className,
    'chapter': chapter,
    'description': description,
    'thumbnail': thumbnail,
    'isPublic': isPublic,
    'youtubePlaylistId': youtubePlaylistId,
    'videoCount': videoCount,
    'totalDuration': totalDuration,
    'totalViews': totalViews,
    'totalWatchTime': totalWatchTime,
    'createdAt': createdAt,
    'videos': videos.map((v) => v.toJson()).toList(),
  };
}

class YouTubeSyncStatus {
  final String channelId;
  final String channelTitle;
  final String channelThumbnail;
  final String subscriberCount;
  final String videoCount;
  final Map<String, dynamic>? folder;

  YouTubeSyncStatus({
    required this.channelId,
    required this.channelTitle,
    required this.channelThumbnail,
    required this.subscriberCount,
    required this.videoCount,
    this.folder,
  });

  factory YouTubeSyncStatus.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return YouTubeSyncStatus(
      channelId: (json['channelId'] ?? '').toString(),
      channelTitle: (json['channelTitle'] ?? '').toString(),
      channelThumbnail: (json['channelThumbnail'] ?? '').toString(),
      subscriberCount: (json['subscriberCount'] ?? '0').toString(),
      videoCount: (json['videoCount'] ?? '0').toString(),
      folder: json['folder'] is Map ? Map<String, dynamic>.from(json['folder'] as Map) : null,
    );
  }
}
