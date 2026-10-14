import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets.dart';
import 'admin_screens.dart';
import 'admin_students.dart';
import 'course_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().isAdmin;

    final pages = admin
        ? <Widget>[const AdminDashboardTab(), const AdminCoursesTab(), const AdminStudentsTab(), const ProfileScreen()]
        : <Widget>[const ExploreTab(mineOnly: false), const ExploreTab(mineOnly: true), const ProfileScreen()];
    final titles = admin
        ? ['Tableau de bord', 'Cours', 'Étudiants', 'Profil']
        : ['Explorer', 'Mes cours', 'Profil'];
    final dests = admin
        ? const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Accueil'),
            NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books), label: 'Cours'),
            NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Étudiants'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorer'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Mes cours'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
          ];
    if (_tab >= pages.length) _tab = 0;

    return Scaffold(
      appBar: AppBar(title: Text(titles[_tab])),
      body: KeyedSubtree(key: ValueKey('$admin-$_tab'), child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: dests,
      ),
    );
  }
}

/// Onglets étudiant : "Explorer" (tous les cours) et "Mes cours" (inscrits).
class ExploreTab extends StatefulWidget {
  final bool mineOnly;
  const ExploreTab({super.key, required this.mineOnly});
  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  List<Course>? _courses;
  String? _error;
  String _query = '';
  String? _category;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await ApiService.courses();
      if (!mounted) return;
      setState(() { _courses = c; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _open(Course c) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: c.id)));
    if (!mounted) return;
    context.read<AuthProvider>().refreshUser();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_courses == null) {
      return _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : const Center(child: CircularProgressIndicator());
    }
    final user = context.watch<AuthProvider>().user!;
    var list = _courses!;
    if (widget.mineOnly) list = list.where((c) => c.enrolled).toList();
    final categories = list.map((c) => c.category).toSet().toList()..sort();
    final shown = list.where((c) {
      final q = _query.toLowerCase();
      final okQ = q.isEmpty || c.title.toLowerCase().contains(q) || c.description.toLowerCase().contains(q);
      final okC = _category == null || c.category == _category;
      return okQ && okC;
    }).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (!widget.mineOnly)
            GradientBox(
              color: Theme.of(context).colorScheme.primary,
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Bonjour, ${user.name.split(' ').first} 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('${user.lessonsDone} leçon${user.lessonsDone > 1 ? 's' : ''} terminée${user.lessonsDone > 1 ? 's' : ''} • '
                        '${user.coursesCount} cours suivi${user.coursesCount > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white70)),
                  ]),
                ),
                const Icon(Icons.local_fire_department, color: Colors.amber, size: 44),
              ]),
            ),
          const SizedBox(height: 14),
          TextField(
            decoration: const InputDecoration(hintText: 'Rechercher un cours…', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _query = v),
          ),
          if (categories.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: const Text('Tous'), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
                ),
                ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
                    )),
              ]),
            ),
          ],
          const SizedBox(height: 14),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Empty(
                icon: Icons.menu_book_outlined,
                text: widget.mineOnly ? "Vous n'êtes inscrit à aucun cours pour l'instant.\nAllez dans « Explorer » pour commencer !" : 'Aucun cours trouvé.',
              ),
            )
          else
            ...shown.map((c) => CourseCard(course: c, onTap: () => _open(c))),
        ],
      ),
    );
  }
}
