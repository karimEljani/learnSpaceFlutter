import 'package:flutter/material.dart';

int _i(dynamic v) => v == null ? 0 : int.parse('$v');

Color colorFromHex(String? hex) {
  try {
    return Color(int.parse((hex ?? '#4F46E5').substring(1), radix: 16) | 0xFF000000);
  } catch (_) {
    return const Color(0xFF4F46E5);
  }
}

String colorToHex(Color c) =>
    '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int coursesCount;
  final int lessonsDone;
  final String? createdAt;

  User({required this.id, required this.name, required this.email,
      this.role = 'student', this.coursesCount = 0, this.lessonsDone = 0, this.createdAt});

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: _i(j['id']),
        name: j['name'],
        email: j['email'],
        role: j['role'] ?? 'student',
        coursesCount: _i(j['courses_count']),
        lessonsDone: _i(j['lessons_done']),
        createdAt: j['created_at'],
      );
}

class Lesson {
  final int id;
  final String title;
  final String content;
  final int durationMin;
  final int position;
  bool completed;

  Lesson({required this.id, required this.title, required this.content,
      required this.durationMin, this.position = 0, this.completed = false});

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: _i(j['id']),
        title: j['title'],
        content: j['content'],
        durationMin: _i(j['duration_min']),
        position: _i(j['position']),
        completed: j['completed'] == true,
      );
}

class Course {
  final int id;
  final String title;
  final String description;
  final String category;
  final String level;
  final Color color;
  final bool published;
  final int lessonCount;
  final int doneCount;
  final int enrolledCount;
  final bool enrolled;
  final List<Lesson> lessons;

  Course({required this.id, required this.title, required this.description,
      required this.category, required this.level, required this.color,
      this.published = true, this.lessonCount = 0, this.doneCount = 0,
      this.enrolledCount = 0, this.enrolled = false, this.lessons = const []});

  double get progress => lessonCount == 0 ? 0 : doneCount / lessonCount;
  bool get isComplete => lessonCount > 0 && doneCount >= lessonCount;

  factory Course.fromJson(Map<String, dynamic> j) {
    final ls = (j['lessons'] as List?)
            ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Lesson>[];
    return Course(
      id: _i(j['id']),
      title: j['title'],
      description: j['description'] ?? '',
      category: j['category'] ?? '',
      level: j['level'] ?? 'Débutant',
      color: colorFromHex(j['color']),
      published: j['published'] != false,
      lessonCount: j['lesson_count'] != null ? _i(j['lesson_count']) : ls.length,
      doneCount: j['done_count'] != null
          ? _i(j['done_count'])
          : ls.where((l) => l.completed).length,
      enrolledCount: _i(j['enrolled_count']),
      enrolled: j['enrolled'] == true,
      lessons: ls,
    );
  }
}

/// Étudiant vu par l'administrateur (avec ses cours si on charge le détail).
class Student {
  final User user;
  final List<Course> courses;
  Student(this.user, [this.courses = const []]);

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        User.fromJson(j),
        (j['courses'] as List?)
                ?.map((e) => Course.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class AdminStats {
  final int students, courses, publishedCourses, lessons, enrollments, completions;
  final List<Course> topCourses;
  final List<User> recentStudents;

  AdminStats({required this.students, required this.courses,
      required this.publishedCourses, required this.lessons,
      required this.enrollments, required this.completions,
      required this.topCourses, required this.recentStudents});

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        students: _i(j['students']),
        courses: _i(j['courses']),
        publishedCourses: _i(j['published_courses']),
        lessons: _i(j['lessons']),
        enrollments: _i(j['enrollments']),
        completions: _i(j['completions']),
        topCourses: (j['top_courses'] as List)
            .map((e) => Course.fromJson({...e, 'description': '', 'category': '', 'level': ''}))
            .toList(),
        recentStudents:
            (j['recent_students'] as List).map((e) => User.fromJson(e)).toList(),
      );
}
