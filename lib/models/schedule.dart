class ScheduleSession {
  final String id;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String? classLevel;
  final String subject;
  final String color;
  final String? notes;

  ScheduleSession({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.classLevel,
    required this.subject,
    required this.color,
    this.notes,
  });

  factory ScheduleSession.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return ScheduleSession(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Session',
      date: json['date']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '10:00 AM',
      endTime: json['endTime']?.toString() ?? '11:00 AM',
      classLevel: (json['class'] ?? json['classLevel'])?.toString(),
      subject: json['subject']?.toString() ?? 'General',
      color: json['color']?.toString() ?? '#3b82f6',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'class': classLevel,
      'subject': subject,
      'color': color,
      'notes': notes,
    };
  }
}

class CustomHoliday {
  final String id;
  final String date;
  final String title;

  CustomHoliday({
    required this.id,
    required this.date,
    required this.title,
  });

  factory CustomHoliday.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return CustomHoliday(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'title': title,
    };
  }
}

class NationalHoliday {
  final String date;
  final String title;
  final bool? tentative;

  const NationalHoliday({
    required this.date,
    required this.title,
    this.tentative,
  });

  factory NationalHoliday.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return NationalHoliday(
      date: json['date']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      tentative: json['tentative'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'title': title,
      'tentative': tentative,
    };
  }
}
