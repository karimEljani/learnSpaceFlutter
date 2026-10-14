import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets.dart';

// ======================= Liste des utilisateurs =======================
class AdminStudentsTab extends StatefulWidget {
  const AdminStudentsTab({super.key});
  @override
  State<AdminStudentsTab> createState() => _AdminStudentsTabState();
}

class _AdminStudentsTabState extends State<AdminStudentsTab> {
  List<Student>? _all;
  String? _error;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ApiService.students();
      if (!mounted) return;
      setState(() { _all = s; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _add() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentFormScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget body;
    if (_all == null) {
      body = _error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator());
    } else {
      final q = _q.toLowerCase();
      final list = _all!.where((s) => q.isEmpty || s.user.name.toLowerCase().contains(q) || s.user.email.toLowerCase().contains(q)).toList();
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Rechercher un utilisateur…', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('${list.length} utilisateur${list.length > 1 ? 's' : ''}', style: t.bodySmall),
            ),
            if (list.isEmpty) const Empty(icon: Icons.person_search, text: 'Aucun utilisateur trouvé.'),
            ...list.map((s) => AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(userId: s.user.id)));
                    _load();
                  },
                  child: Row(children: [
                    UserAvatar(name: s.user.name, admin: s.user.isAdmin),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(child: Text(s.user.name, overflow: TextOverflow.ellipsis, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                          if (s.user.isAdmin) ...[const SizedBox(width: 6), const Pill(text: 'Admin', color: Colors.deepOrange)],
                        ]),
                        Text(s.user.email, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                        Text('${s.user.coursesCount} cours • ${s.user.lessonsDone} leçons terminées', style: t.bodySmall),
                      ]),
                    ),
                    const Icon(Icons.chevron_right),
                  ]),
                )),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.person_add_alt), label: const Text('Ajouter')),
    );
  }
}

// ======================= Création d'un utilisateur =======================
class StudentFormScreen extends StatefulWidget {
  const StudentFormScreen({super.key});
  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _admin = false;
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ApiService.createStudent(_name.text.trim(), _email.text.trim(), _pass.text, _admin ? 'admin' : 'student');
      if (mounted) {
        toast(context, 'Utilisateur créé');
        Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel utilisateur', style: TextStyle(fontSize: 20))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _pass, obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe (6 car. min.)', prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Administrateur'),
              subtitle: const Text('Accès complet à la gestion des cours et des utilisateurs'),
              value: _admin,
              onChanged: (v) => setState(() => _admin = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Créer l'utilisateur"),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= Détail d'un étudiant =======================
class StudentDetailScreen extends StatefulWidget {
  final int userId;
  const StudentDetailScreen({super.key, required this.userId});
  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Student? _s;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ApiService.student(widget.userId);
      if (!mounted) return;
      setState(() { _s = s; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _run(Future<void> Function() job, String okMsg) async {
    try {
      await job();
      if (mounted) toast(context, okMsg);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    _load();
  }

  Future<void> _enrollDialog() async {
    final all = await ApiService.adminCourses().catchError((_) => <Course>[]);
    final enrolledIds = _s!.courses.map((c) => c.id).toSet();
    final available = all.where((c) => !enrolledIds.contains(c.id)).toList();
    if (!mounted) return;
    final picked = await showModalBottomSheet<Course>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: available.isEmpty
            ? const Padding(padding: EdgeInsets.all(32), child: Text('Cet utilisateur est déjà inscrit à tous les cours.', textAlign: TextAlign.center))
            : ListView(
                shrinkWrap: true,
                children: [
                  const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('Inscrire à un cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  ...available.map((c) => ListTile(
                        leading: CircleAvatar(backgroundColor: c.color, child: const Icon(Icons.menu_book, color: Colors.white, size: 18)),
                        title: Text(c.title),
                        subtitle: Text(c.published ? c.category : '${c.category} • brouillon'),
                        onTap: () => Navigator.pop(context, c),
                      )),
                ],
              ),
      ),
    );
    if (picked != null) {
      _run(() => ApiService.enrollStudent(widget.userId, picked.id), 'Inscription ajoutée');
    }
  }

  Future<void> _menu(String a) async {
    final s = _s!;
    if (a == 'role') {
      final toAdmin = !s.user.isAdmin;
      if (!await confirm(context, toAdmin ? 'Promouvoir en administrateur ?' : 'Retirer les droits admin ?',
          '${s.user.name} ${toAdmin ? 'pourra gérer les cours et les utilisateurs.' : 'redeviendra un simple étudiant.'}', action: 'Confirmer')) return;
      _run(() => ApiService.setRole(s.user.id, toAdmin ? 'admin' : 'student'), 'Rôle mis à jour');
    } else if (a == 'delete') {
      if (!await confirm(context, "Supprimer l'utilisateur ?", '${s.user.name} et toute sa progression seront supprimés définitivement.')) return;
      try {
        await ApiService.deleteStudent(s.user.id);
        if (mounted) {
          toast(context, 'Utilisateur supprimé');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) toast(context, '$e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()),
      );
    }
    final me = context.read<AuthProvider>().user!;
    final isMe = me.id == s.user.id;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateur', style: TextStyle(fontSize: 20)),
        actions: [
          if (!isMe)
            PopupMenuButton<String>(
              onSelected: _menu,
              itemBuilder: (_) => [
                PopupMenuItem(value: 'role', child: Text(s.user.isAdmin ? 'Retirer les droits admin' : 'Promouvoir administrateur')),
                const PopupMenuItem(value: 'delete', child: Text("Supprimer l'utilisateur")),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Center(child: UserAvatar(name: s.user.name, radius: 42, admin: s.user.isAdmin)),
            const SizedBox(height: 10),
            Text(s.user.name, textAlign: TextAlign.center, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(s.user.email, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Center(child: Pill(text: s.user.isAdmin ? 'Administrateur' : 'Étudiant', color: s.user.isAdmin ? Colors.deepOrange : Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: StatTile(label: 'Cours', value: s.user.coursesCount, icon: Icons.menu_book, color: Colors.indigo)),
              const SizedBox(width: 12),
              Expanded(child: StatTile(label: 'Leçons terminées', value: s.user.lessonsDone, icon: Icons.task_alt, color: Colors.green)),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Text('Cours suivis', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              TextButton.icon(onPressed: _enrollDialog, icon: const Icon(Icons.add), label: const Text('Inscrire')),
            ]),
            if (s.courses.isEmpty) const Empty(icon: Icons.menu_book_outlined, text: "Pas encore inscrit à un cours."),
            ...s.courses.map((c) => AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: c.progress, minHeight: 7, color: c.color),
                        ),
                        const SizedBox(height: 4),
                        Text('${c.doneCount}/${c.lessonCount} leçons • ${(c.progress * 100).round()} %', style: t.bodySmall),
                      ]),
                    ),
                    IconButton(
                      tooltip: 'Désinscrire',
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () async {
                        if (!await confirm(context, 'Désinscrire ?', 'La progression de ${s.user.name} dans « ${c.title} » sera effacée.', action: 'Désinscrire')) return;
                        _run(() => ApiService.unenrollStudent(s.user.id, c.id), 'Désinscrit du cours');
                      },
                    ),
                  ]),
                )),
          ],
        ),
      ),
    );
  }
}
