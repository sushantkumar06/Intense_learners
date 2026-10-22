class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String difficulty; // "easy" | "medium" | "hard"
  final String topic;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
    required this.topic,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      question: json['question']?.toString() ?? '',
      options: List<String>.from((json['options'] as List?)?.map((e) => e.toString()) ?? []),
      correctAnswer: (json['correctAnswer'] as num?)?.toInt() ?? 0,
      difficulty: json['difficulty']?.toString() ?? 'medium',
      topic: json['topic']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

class QuizMetadata {
  final String generatedAt;
  final String model;
  final int questionCount;
  final Map<String, dynamic> markingScheme;

  QuizMetadata({
    required this.generatedAt,
    required this.model,
    required this.questionCount,
    required this.markingScheme,
  });

  factory QuizMetadata.fromJson(Map<String, dynamic> json) {
    return QuizMetadata(
      generatedAt: json['generatedAt']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      markingScheme: json['markingScheme'] is Map
          ? Map<String, dynamic>.from(json['markingScheme'] as Map)
          : <String, dynamic>{},
    );
  }
}

class QuizData {
  final String title;
  final String category;
  final int duration;
  final int totalMarks;
  final int passingMarks;
  final List<QuizQuestion> questions;
  final QuizMetadata metadata;

  QuizData({
    required this.title,
    required this.category,
    required this.duration,
    required this.totalMarks,
    required this.passingMarks,
    required this.questions,
    required this.metadata,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 3600,
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 80,
      passingMarks: (json['passingMarks'] as num?)?.toInt() ?? 32,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      metadata: json['metadata'] is Map
          ? QuizMetadata.fromJson(Map<String, dynamic>.from(json['metadata'] as Map))
          : QuizMetadata(generatedAt: '', model: '', questionCount: 0, markingScheme: {}),
    );
  }
}

class QuizScore {
  final int total;
  final int correct;
  final int incorrect;
  final int unattempted;
  final int percentage;
  final bool passed;
  final int timeTaken;

  QuizScore({
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.unattempted,
    required this.percentage,
    required this.passed,
    required this.timeTaken,
  });
}

class QuizCategoryItem {
  final String id;
  final String title;
  final String subject;
  final int? classLevel;
  final String? difficulty;

  QuizCategoryItem({
    required this.id,
    required this.title,
    required this.subject,
    this.classLevel,
    this.difficulty,
  });

  factory QuizCategoryItem.fromJson(Map<String, dynamic> json) {
    return QuizCategoryItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      classLevel: json['class'] is int
          ? json['class'] as int
          : int.tryParse(json['class']?.toString() ?? ''),
      difficulty: json['difficulty']?.toString(),
    );
  }
}
