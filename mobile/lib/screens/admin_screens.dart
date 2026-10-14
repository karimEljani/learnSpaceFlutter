import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_students.dart';

// ======================= Tableau de bord =======================
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});
  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  AdminStats? _s;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ApiService.adminStats();
      if (!mounted) return;
      setState(() { _s = s; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _newCourse() async {
    final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseFormScreen()));
    if (r is Course && mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminCourseScreen(courseId: r.id)));
    }
    _load();
  }

  Future<void> _newStudent() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentFormScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (s == null) {
      return _error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator());
    }
    final t = Theme.of(context).textTheme;
    final maxEnrolled = s.topCourses.fold<int>(1, (m, c) => c.enrolledCount > m ? c.enrolledCount : m);

    Widget row(Widget a, Widget b) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]),
        );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          GradientBox(
            color: Colors.deepOrange,
            child: Row(children: [
              const Icon(Icons.admin_panel_settings, color: Colors.white, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Espace administrateur', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('${s.publishedCourses}/${s.courses} cours publiés', style: const TextStyle(color: Colors.white70)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: _newCourse, icon: const Icon(Icons.add), label: const Text('Nouveau cours'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(onPressed: _newStudent, icon: const Icon(Icons.person_add_alt), label: const Text('Étudiant'))),
          ]),
          const SizedBox(height: 16),
          row(StatTile(label: 'Étudiants', value: s.students, icon: Icons.groups, color: Colors.indigo),
              StatTile(label: 'Cours', value: s.courses, icon: Icons.library_books, color: Colors.teal)),
          row(StatTile(label: 'Leçons', value: s.lessons, icon: Icons.play_lesson, color: Colors.orange),
              StatTile(label: 'Inscriptions', value: s.enrollments, icon: Icons.how_to_reg, color: Colors.pink)),
          Text('Cours les plus suivis', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (s.topCourses.isEmpty) const Empty(icon: Icons.bar_chart, text: 'Aucune donnée pour le moment.'),
          ...s.topCourses.map((c) => AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(c.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                    Text('${c.enrolledCount} inscrit${c.enrolledCount > 1 ? 's' : ''}', style: t.bodySmall),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: c.enrolledCount / maxEnrolled, minHeight: 8, color: c.color),
                  ),
                ]),
              )),
          const SizedBox(height: 8),
          Text('Derniers inscrits', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (s.recentStudents.isEmpty) const Empty(icon: Icons.person_off_outlined, text: "Aucun étudiant pour l'instant."),
          ...s.recentStudents.map((u) => AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(userId: u.id)));
                  _load();
                },
                child: Row(children: [
                  UserAvatar(name: u.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u.name, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(u.email, style: t.bodySmall),
                    ]),
                  ),
                ]),
              )),
        ],
      ),
    );
  }
}

// ======================= Liste des cours (admin) =======================
class AdminCoursesTab extends StatefulWidget {
  const AdminCoursesTab({super.key});
  @override
  State<AdminCoursesTab> createState() => _AdminCoursesTabState();
}

class _AdminCoursesTabState extends State<AdminCoursesTab> {
  List<Course>? _courses;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await ApiService.adminCourses();
      if (!mounted) return;
      setState(() { _courses = c; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _create() async {
    final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseFormScreen()));
    if (r is Course && mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminCourseScreen(courseId: r.id)));
    }
    _load();
  }

  Future<void> _manage(Course c) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminCourseScreen(courseId: c.id)));
    _load();
  }

  Future<void> _action(String a, Course c) async {
    try {
      if (a == 'edit') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => CourseFormScreen(course: c)));
      } else if (a == 'publish') {
        await ApiService.updateCourse(c.id, c.title, c.description, c.category, c.level, c.color, !c.published);
        if (mounted) toast(context, c.published ? 'Cours masqué (brouillon)' : 'Cours publié');
      } else if (a == 'delete') {
        if (!await confirm(context, 'Supprimer ce cours ?',
            '« ${c.title} », ses ${c.lessonCount} leçons et les inscriptions associées seront supprimés définitivement.')) return;
        await ApiService.deleteCourse(c.id);
        if (mounted) toast(context, 'Cours supprimé');
      }
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget body;
    if (_courses == null) {
      body = _error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator());
    } else if (_courses!.isEmpty) {
      body = const Empty(icon: Icons.library_add_outlined, text: "Aucun cours.\nAppuyez sur « Nouveau cours » pour commencer.");
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
          children: _courses!.map((c) => AppCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                onTap: () => _manage(c),
                child: Row(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.menu_book, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${c.category} • ${c.lessonCount} leçons • ${c.enrolledCount} inscrits', style: t.bodySmall),
                      if (!c.published) ...[
                        const SizedBox(height: 4),
                        const Pill(text: 'Brouillon', color: Colors.orange),
                      ],
                    ]),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (a) => _action(a, c),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifier les infos')),
                      PopupMenuItem(value: 'publish', child: Text(c.published ? 'Passer en brouillon' : 'Publier')),
                      const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                  ),
                ]),
              )).toList(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create, icon: const Icon(Icons.add), label: const Text('Nouveau cours')),
    );
  }
}

// ======================= Gestion d'un cours et de ses leçons =======================
class AdminCourseScreen extends StatefulWidget {
  final int courseId;
  const AdminCourseScreen({super.key, required this.courseId});
  @override
  State<AdminCourseScreen> createState() => _AdminCourseScreenState();
}

class _AdminCourseScreenState extends State<AdminCourseScreen> {
  Course? _c;
  List<Lesson> _lessons = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await ApiService.adminCourse(widget.courseId);
      if (!mounted) return;
      setState(() { _c = c; _lessons = List.of(c.lessons); _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _editCourse() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CourseFormScreen(course: _c)));
    _load();
  }

  Future<void> _lessonForm([Lesson? l]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => LessonFormScreen(courseId: widget.courseId, lesson: l)));
    _load();
  }

  Future<void> _deleteLesson(Lesson l) async {
    if (!await confirm(context, 'Supprimer la leçon ?', '« ${l.title} » sera supprimée.')) return;
    try {
      await ApiService.deleteLesson(l.id);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    _load();
  }

  Future<void> _reorder(int oldI, int newI) async {
    if (newI > oldI) newI -= 1;
    setState(() => _lessons.insert(newI, _lessons.removeAt(oldI)));
    try {
      await ApiService.reorderLessons(widget.courseId, _lessons.map((l) => l.id).toList());
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()),
      );
    }
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer le cours', style: TextStyle(fontSize: 20)),
        actions: [IconButton(tooltip: 'Modifier les infos', icon: const Icon(Icons.edit_outlined), onPressed: _editCourse)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.color,
        foregroundColor: Colors.white,
        onPressed: () => _lessonForm(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une leçon'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            GradientBox(
              color: c.color,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(c.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _badge(c.category), _badge(c.level), _badge('${c.enrolledCount} inscrits'),
                  _badge(c.published ? 'Publié' : 'Brouillon'),
                ]),
              ]),
            ),
            const SizedBox(height: 18),
            Text('Leçons (${_lessons.length})', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const Text('Maintenez la poignée ⠿ pour réordonner.'),
            const SizedBox(height: 10),
            if (_lessons.isEmpty)
              const Empty(icon: Icons.playlist_add, text: 'Aucune leçon.\nAjoutez la première avec le bouton ci-dessous.')
            else
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: _reorder,
                children: [
                  for (int i = 0; i < _lessons.length; i++)
                    AppCard(
                      key: ValueKey(_lessons[i].id),
                      onTap: () => _lessonForm(_lessons[i]),
                      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                      child: Row(children: [
                        CircleAvatar(radius: 16, backgroundColor: c.color.withAlpha(35),
                            child: Text('${i + 1}', style: TextStyle(color: c.color, fontWeight: FontWeight.w700))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_lessons[i].title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            Text('${_lessons[i].durationMin} min', style: t.bodySmall),
                          ]),
                        ),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteLesson(_lessons[i])),
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.drag_indicator)),
                        ),
                      ]),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
        child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

// ======================= Formulaire cours =======================
class CourseFormScreen extends StatefulWidget {
  final Course? course;
  const CourseFormScreen({super.key, this.course});
  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.course?.title);
  late final _desc = TextEditingController(text: widget.course?.description);
  late final _cat = TextEditingController(text: widget.course?.category);
  late String _level = widget.course?.level ?? 'Débutant';
  late Color _color = widget.course?.color ?? kCourseColors.first;
  late bool _published = widget.course?.published ?? true;
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final c = widget.course;
      if (c == null) {
        final created = await ApiService.createCourse(_title.text.trim(), _desc.text.trim(), _cat.text.trim(), _level, _color, _published);
        if (mounted) Navigator.pop(context, created);
      } else {
        await ApiService.updateCourse(c.id, _title.text.trim(), _desc.text.trim(), _cat.text.trim(), _level, _color, _published);
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, '$e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.course != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Modifier le cours' : 'Nouveau cours', style: const TextStyle(fontSize: 20))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titre du cours'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _cat,
              decoration: const InputDecoration(labelText: 'Catégorie (ex : Mobile, Backend…)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _level,
              decoration: const InputDecoration(labelText: 'Niveau'),
              items: const ['Débutant', 'Intermédiaire', 'Avancé'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _level = v ?? _level),
            ),
            const SizedBox(height: 20),
            const Text('Couleur du cours', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ColorPicker(value: _color, onChanged: (c) => setState(() => _color = c)),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publié'),
              subtitle: const Text('Les brouillons ne sont pas visibles par les étudiants'),
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(editing ? 'Enregistrer' : 'Créer le cours'),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= Formulaire leçon =======================
class LessonFormScreen extends StatefulWidget {
  final int courseId;
  final Lesson? lesson;
  const LessonFormScreen({super.key, required this.courseId, this.lesson});
  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.lesson?.title);
  late final _content = TextEditingController(text: widget.lesson?.content);
  late final _dur = TextEditingController(text: '${widget.lesson?.durationMin ?? 10}');
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final dur = int.tryParse(_dur.text) ?? 10;
    try {
      final l = widget.lesson;
      if (l == null) {
        await ApiService.createLesson(widget.courseId, _title.text.trim(), _content.text.trim(), dur);
      } else {
        await ApiService.updateLesson(l.id, _title.text.trim(), _content.text.trim(), dur);
      }
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
    final editing = widget.lesson != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Modifier la leçon' : 'Nouvelle leçon', style: const TextStyle(fontSize: 20))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titre de la leçon'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dur,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Durée (minutes)', prefixIcon: Icon(Icons.schedule)),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Nombre ≥ 1' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _content,
              maxLines: 12,
              decoration: const InputDecoration(labelText: 'Contenu de la leçon', alignLabelWithHint: true),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(editing ? 'Enregistrer' : 'Ajouter la leçon'),
            ),
          ],
        ),
      ),
    );
  }
}
