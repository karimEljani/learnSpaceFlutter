import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'package:flutter/material.dart' show Color;
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiService {
  static String? token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<dynamic> _request(String method, String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$apiBaseUrl/$path');
    final payload = jsonEncode(body ?? {});
    try {
      late http.Response res;
      switch (method) {
        case 'GET':
          res = await http.get(uri, headers: _headers);
          break;
        case 'POST':
          res = await http.post(uri, headers: _headers, body: payload);
          break;
        case 'PUT':
          res = await http.put(uri, headers: _headers, body: payload);
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: _headers);
          break;
      }
      final data = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode >= 400) {
        throw ApiException(
            (data is Map ? data['error'] : null) ?? 'Erreur ${res.statusCode}',
            res.statusCode);
      }
      return data;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Impossible de joindre le serveur ($apiBaseUrl)');
    }
  }

  // ---------- Auth & profil ----------
  static Future<Map<String, dynamic>> login(String email, String password) async =>
      await _request('POST', 'login', body: {'email': email, 'password': password});

  static Future<Map<String, dynamic>> register(String name, String email, String password) async =>
      await _request('POST', 'register', body: {'name': name, 'email': email, 'password': password});

  static Future<User> me() async => User.fromJson(await _request('GET', 'me'));

  static Future<void> updateProfile({String? name, String? currentPassword, String? newPassword}) =>
      _request('PUT', 'me', body: {
        if (name != null) 'name': name,
        if (newPassword != null) 'current_password': currentPassword,
        if (newPassword != null) 'new_password': newPassword,
      });

  // ---------- Étudiant ----------
  static Future<List<Course>> courses() async =>
      ((await _request('GET', 'courses')) as List).map((e) => Course.fromJson(e)).toList();

  static Future<Course> course(int id) async => Course.fromJson(await _request('GET', 'courses/$id'));

  static Future<void> enroll(int courseId) => _request('POST', 'courses/$courseId/enroll');

  static Future<void> leaveCourse(int courseId) => _request('DELETE', 'courses/$courseId/enroll');

  static Future<void> completeLesson(int lessonId) => _request('POST', 'lessons/$lessonId/complete');

  // ---------- Admin : statistiques ----------
  static Future<AdminStats> adminStats() async =>
      AdminStats.fromJson(await _request('GET', 'admin/stats'));

  // ---------- Admin : cours ----------
  static Future<List<Course>> adminCourses() async =>
      ((await _request('GET', 'admin/courses')) as List).map((e) => Course.fromJson(e)).toList();

  static Future<Course> adminCourse(int id) async =>
      Course.fromJson(await _request('GET', 'admin/courses/$id'));

  static Map<String, dynamic> _courseBody(String title, String description, String category,
          String level, Color color, bool published) =>
      {'title': title, 'description': description, 'category': category,
       'level': level, 'color': colorToHex(color), 'published': published};

  static Future<Course> createCourse(String title, String description, String category,
          String level, Color color, bool published) async =>
      Course.fromJson(await _request('POST', 'admin/courses',
          body: _courseBody(title, description, category, level, color, published)));

  static Future<void> updateCourse(int id, String title, String description, String category,
          String level, Color color, bool published) =>
      _request('PUT', 'admin/courses/$id', body: _courseBody(title, description, category, level, color, published));

  static Future<void> deleteCourse(int id) => _request('DELETE', 'admin/courses/$id');

  // ---------- Admin : leçons ----------
  static Future<void> createLesson(int courseId, String title, String content, int duration) =>
      _request('POST', 'admin/courses/$courseId/lessons',
          body: {'title': title, 'content': content, 'duration_min': duration});

  static Future<void> updateLesson(int id, String title, String content, int duration) =>
      _request('PUT', 'admin/lessons/$id',
          body: {'title': title, 'content': content, 'duration_min': duration});

  static Future<void> deleteLesson(int id) => _request('DELETE', 'admin/lessons/$id');

  static Future<void> reorderLessons(int courseId, List<int> ids) =>
      _request('POST', 'admin/courses/$courseId/reorder', body: {'ids': ids});

  // ---------- Admin : étudiants ----------
  static Future<List<Student>> students() async =>
      ((await _request('GET', 'admin/students')) as List).map((e) => Student.fromJson(e)).toList();

  static Future<Student> student(int id) async =>
      Student.fromJson(await _request('GET', 'admin/students/$id'));

  static Future<void> createStudent(String name, String email, String password, String role) =>
      _request('POST', 'admin/students',
          body: {'name': name, 'email': email, 'password': password, 'role': role});

  static Future<void> deleteStudent(int id) => _request('DELETE', 'admin/students/$id');

  static Future<void> setRole(int id, String role) =>
      _request('POST', 'admin/students/$id/role', body: {'role': role});

  static Future<void> enrollStudent(int id, int courseId) =>
      _request('POST', 'admin/students/$id/enroll', body: {'course_id': courseId});

  static Future<void> unenrollStudent(int id, int courseId) =>
      _request('DELETE', 'admin/students/$id/courses/$courseId');
}
