class VideoItem {
  final String id;
  final String title;
  final String description;
  final String duration;
  final int views;
  final String uploadDate;
  final String thumbnail;
  final String videoUrl;
  final int order;
  final bool watched;
  final double watchedPercentage;
  final int watchedSeconds;
  final int lastPosition;
  final bool bookmarked;

  VideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.views,
    required this.uploadDate,
    required this.thumbnail,
    required this.videoUrl,
    required this.order,
    required this.watched,
    required this.watchedPercentage,
    required this.watchedSeconds,
    required this.lastPosition,
    required this.bookmarked,
  });

  factory VideoItem.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return VideoItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      views: (json['views'] as num?)?.toInt() ?? 0,
      uploadDate: json['uploadDate']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      watched: json['watched'] == true,
      watchedPercentage: ((json['watchedPercentage'] ?? 0) as num).toDouble(),
      watchedSeconds: (json['watchedSeconds'] as num?)?.toInt() ?? 0,
      lastPosition: (json['lastPosition'] as num?)?.toInt() ?? 0,
      bookmarked: json['bookmarked'] == true,
    );
  }

  VideoItem copyWith({
    bool? watched,
    double? watchedPercentage,
    int? watchedSeconds,
    int? lastPosition,
    bool? bookmarked,
  }) {
    return VideoItem(
      id: id,
      title: title,
      description: description,
      duration: duration,
      views: views,
      uploadDate: uploadDate,
      thumbnail: thumbnail,
      videoUrl: videoUrl,
      order: order,
      watched: watched ?? this.watched,
      watchedPercentage: watchedPercentage ?? this.watchedPercentage,
      watchedSeconds: watchedSeconds ?? this.watchedSeconds,
      lastPosition: lastPosition ?? this.lastPosition,
      bookmarked: bookmarked ?? this.bookmarked,
    );
  }
}

class VideoFolder {
  final String id;
  final String name;
  final String subject;
  final String className;
  final String? chapter;
  final String description;
  final String thumbnail;
  final int videoCount;
  final String totalDuration;
  final int totalViews;
  final String teacher;
  final String teacherAvatar;
  final double progress;
  final int completedCount;
  final List<VideoItem> videos;

  VideoFolder({
    required this.id,
    required this.name,
    required this.subject,
    required this.className,
    this.chapter,
    required this.description,
    required this.thumbnail,
    required this.videoCount,
    required this.totalDuration,
    required this.totalViews,
    required this.teacher,
    required this.teacherAvatar,
    required this.progress,
    required this.completedCount,
    required this.videos,
  });

  factory VideoFolder.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    var vList = json['videos'] as List? ?? [];
    return VideoFolder(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      className: (json['class'] ?? json['className'])?.toString() ?? '',
      chapter: json['chapter']?.toString(),
      description: json['description']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      videoCount: (json['videoCount'] as num?)?.toInt() ?? 0,
      totalDuration: json['totalDuration']?.toString() ?? '',
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      teacher: json['teacher']?.toString() ?? '',
      teacherAvatar: json['teacherAvatar']?.toString() ?? '',
      progress: ((json['progress'] ?? 0) as num).toDouble(),
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      videos: vList
          .whereType<Map>()
          .map((v) => VideoItem.fromJson(v))
          .toList(),
    );
  }
}

class WatchStats {
  final WatchTime watchTime;
  final int completedVideos;
  final int startedVideos;
  final int bookmarkedVideos;
  final double completionRate;

  WatchStats({
    required this.watchTime,
    required this.completedVideos,
    required this.startedVideos,
    required this.bookmarkedVideos,
    required this.completionRate,
  });

  factory WatchStats.fromJson(Map<String, dynamic> json) {
    final rawWatchTime = json['watchTime'];
    return WatchStats(
      watchTime: WatchTime.fromJson(
        rawWatchTime is Map ? Map<String, dynamic>.from(rawWatchTime) : {},
      ),
      completedVideos: (json['completedVideos'] as num?)?.toInt() ?? 0,
      startedVideos: (json['startedVideos'] as num?)?.toInt() ?? 0,
      bookmarkedVideos: (json['bookmarkedVideos'] as num?)?.toInt() ?? 0,
      completionRate: ((json['completionRate'] ?? 0) as num).toDouble(),
    );
  }
}

class WatchTime {
  final int hours;
  final int minutes;
  final int totalSeconds;

  WatchTime({
    required this.hours,
    required this.minutes,
    required this.totalSeconds,
  });

  factory WatchTime.fromJson(Map<String, dynamic> json) {
    return WatchTime(
      hours: (json['hours'] as num?)?.toInt() ?? 0,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      totalSeconds: (json['totalSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
