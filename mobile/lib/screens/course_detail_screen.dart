import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets.dart';
import 'lesson_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  const CourseDetailScreen({super.key, required this.courseId});
  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await ApiService.course(widget.courseId);
      if (!mounted) return;
      setState(() { _course = c; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _enroll() async {
    try {
      await ApiService.enroll(widget.courseId);
      toast(context, 'Inscription réussie 🎉');
      _load();
    } catch (e) {
      toast(context, '$e', error: true);
    }
  }

  Future<void> _leave() async {
    if (!await confirm(context, 'Quitter ce cours ?', 'Votre progression dans ce cours sera effacée.', action: 'Quitter')) return;
    try {
      await ApiService.leaveCourse(widget.courseId);
      _load();
    } catch (e) {
      toast(context, '$e', error: true);
    }
  }

  Future<void> _openLesson(Course c, Lesson l) async {
    final done = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => LessonScreen(lesson: l, color: c.color)));
    if (done == true && mounted) toast(context, 'Leçon terminée ✅');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = _course;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()),
      );
    }
    final next = c.lessons.where((l) => !l.completed).cast<Lesson?>().firstWhere((_) => true, orElse: () => null);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: c.color,
            foregroundColor: Colors.white,
            actions: [
              if (c.enrolled)
                IconButton(tooltip: 'Quitter le cours', icon: const Icon(Icons.exit_to_app), onPressed: _leave),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [c.color, Color.lerp(c.color, Colors.black, 0.4)!],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                alignment: Alignment.bottomLeft,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 8, children: [
                    _chip(c.category),
                    _chip(c.level),
                    _chip('${c.lessons.length} leçons'),
                  ]),
                  const SizedBox(height: 10),
                  Text(c.title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(c.description, style: t.bodyLarge?.copyWith(height: 1.5)),
                const SizedBox(height: 16),
                if (!c.enrolled)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: c.color),
                    onPressed: _enroll,
                    icon: const Icon(Icons.add),
                    label: const Text("S'inscrire à ce cours"),
                  )
                else
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('Ma progression', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('${(c.progress * 100).round()} %', style: t.titleSmall?.copyWith(color: c.color, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: c.progress, minHeight: 9, color: c.color),
                      ),
                      const SizedBox(height: 6),
                      Text(c.isComplete ? '🎉 Cours terminé, bravo !' : '${c.doneCount}/${c.lessonCount} leçons terminées', style: t.bodySmall),
                      if (next != null) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: c.color),
                          onPressed: () => _openLesson(c, next),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(c.doneCount == 0 ? 'Commencer' : 'Continuer : ${next.title}', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ]),
                  ),
                const SizedBox(height: 20),
                Text('Programme', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (c.lessons.isEmpty) const Empty(icon: Icons.hourglass_empty, text: 'Les leçons arrivent bientôt.'),
                ...c.lessons.asMap().entries.map((e) {
                  final l = e.value;
                  return AppCard(
                    onTap: () => _openLesson(c, l),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: l.completed ? Colors.green : c.color.withAlpha(35),
                        child: l.completed
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Text('${e.key + 1}', style: TextStyle(color: c.color, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text('${l.durationMin} min', style: t.bodySmall),
                        ]),
                      ),
                      const Icon(Icons.chevron_right),
                    ]),
                  );
                }),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}
