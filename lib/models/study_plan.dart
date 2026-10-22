import 'dart:convert';

class StudyTask {
  final String time;
  final String task;
  final String type; // "theory" | "practice" | "project" | "break" | "review"
  final String duration;
  final List<String> resources;
  final String? link;
  final bool completed;

  StudyTask({
    required this.time,
    required this.task,
    required this.type,
    required this.duration,
    required this.resources,
    this.link,
    required this.completed,
  });

  StudyTask copyWith({
    String? time,
    String? task,
    String? type,
    String? duration,
    List<String>? resources,
    String? link,
    bool? completed,
  }) {
    return StudyTask(
      time: time ?? this.time,
      task: task ?? this.task,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      resources: resources ?? this.resources,
      link: link ?? this.link,
      completed: completed ?? this.completed,
    );
  }

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    return StudyTask(
      time: json['time'] ?? '',
      task: json['task'] ?? '',
      type: json['type'] ?? 'theory',
      duration: json['duration'] ?? '',
      resources: List<String>.from(json['resources'] ?? []),
      link: json['link'],
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'task': task,
      'type': type,
      'duration': duration,
      'resources': resources,
      if (link != null) 'link': link,
      'completed': completed,
    };
  }
}

class StudyDaySchedule {
  final int day;
  final String title;
  final String focus;
  final List<String> objectives;
  final List<StudyTask> tasks;
  final String milestone;

  StudyDaySchedule({
    required this.day,
    required this.title,
    required this.focus,
    required this.objectives,
    required this.tasks,
    required this.milestone,
  });

  StudyDaySchedule copyWith({
    int? day,
    String? title,
    String? focus,
    List<String>? objectives,
    List<StudyTask>? tasks,
    String? milestone,
  }) {
    return StudyDaySchedule(
      day: day ?? this.day,
      title: title ?? this.title,
      focus: focus ?? this.focus,
      objectives: objectives ?? this.objectives,
      tasks: tasks ?? this.tasks,
      milestone: milestone ?? this.milestone,
    );
  }

  factory StudyDaySchedule.fromJson(Map<String, dynamic> json) {
    return StudyDaySchedule(
      day: (json['day'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      focus: json['focus']?.toString() ?? '',
      objectives: List<String>.from((json['objectives'] as List?)?.map((e) => e.toString()) ?? []),
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => StudyTask.fromJson(Map<String, dynamic>.from(t as Map)))
              .toList() ??
          [],
      milestone: json['milestone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'title': title,
      'focus': focus,
      'objectives': objectives,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'milestone': milestone,
    };
  }
}

class StudyResources {
  final List<String> documentation;
  final List<String> tutorials;
  final List<String> practice;

  StudyResources({
    required this.documentation,
    required this.tutorials,
    required this.practice,
  });

  factory StudyResources.fromJson(Map<String, dynamic> json) {
    return StudyResources(
      documentation: List<String>.from((json['documentation'] as List?)?.map((e) => e.toString()) ?? []),
      tutorials: List<String>.from((json['tutorials'] as List?)?.map((e) => e.toString()) ?? []),
      practice: List<String>.from((json['practice'] as List?)?.map((e) => e.toString()) ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentation': documentation,
      'tutorials': tutorials,
      'practice': practice,
    };
  }
}

class StudyPlanData {
  final String title;
  final String description;
  final num totalHours;
  final List<StudyDaySchedule> schedule;
  final List<String> weeklyGoals;
  final List<String> tips;
  final StudyResources resources;

  StudyPlanData({
    required this.title,
    required this.description,
    required this.totalHours,
    required this.schedule,
    required this.weeklyGoals,
    required this.tips,
    required this.resources,
  });

  factory StudyPlanData.fromJson(Map<String, dynamic> json) {
    final rawResources = json['resources'];
    return StudyPlanData(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      totalHours: json['totalHours'] as num? ?? 0,
      schedule: (json['schedule'] as List<dynamic>?)
              ?.map((s) => StudyDaySchedule.fromJson(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          [],
      weeklyGoals: List<String>.from((json['weeklyGoals'] as List?)?.map((e) => e.toString()) ?? []),
      tips: List<String>.from((json['tips'] as List?)?.map((e) => e.toString()) ?? []),
      resources: StudyResources.fromJson(
        rawResources is Map ? Map<String, dynamic>.from(rawResources) : {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'totalHours': totalHours,
      'schedule': schedule.map((s) => s.toJson()).toList(),
      'weeklyGoals': weeklyGoals,
      'tips': tips,
      'resources': resources.toJson(),
    };
  }

  String toRawJson() => json.encode(toJson());

  factory StudyPlanData.fromRawJson(String str) =>
      StudyPlanData.fromJson(Map<String, dynamic>.from(json.decode(str) as Map));
}

class StudyFormData {
  final String topics;
  final int days;
  final int hoursPerDay;
  final String level; // "beginner" | "intermediate" | "advanced"
  final String goal;

  StudyFormData({
    required this.topics,
    required this.days,
    required this.hoursPerDay,
    required this.level,
    required this.goal,
  });

  Map<String, dynamic> toJson() {
    return {
      'topics': topics,
      'days': days,
      'hoursPerDay': hoursPerDay,
      'level': level,
      'goal': goal,
    };
  }
}
