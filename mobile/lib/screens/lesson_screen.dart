import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final Color color;
  const LessonScreen({super.key, required this.lesson, required this.color});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _busy = false;

  Future<void> _complete() async {
    setState(() => _busy = true);
    try {
      await ApiService.completeLesson(widget.lesson.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, '$e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    return Scaffold(
      appBar: AppBar(title: Text(l.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Pill(text: '${l.durationMin} min de lecture', color: widget.color),
          const SizedBox(height: 16),
          Text(l.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Text(l.content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: l.completed
              ? const Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Leçon terminée'),
                ])
              : FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: widget.color),
                  onPressed: _busy ? null : _complete,
                  icon: const Icon(Icons.check),
                  label: const Text('Marquer comme terminée'),
                ),
        ),
      ),
    );
  }
}
