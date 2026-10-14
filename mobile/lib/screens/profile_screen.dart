import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ctrl = TextEditingController(text: auth.user!.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier mon nom'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nom')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      try {
        await auth.updateName(ctrl.text.trim());
      } catch (e) {
        if (context.mounted) toast(context, '$e', error: true);
      }
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final cur = TextEditingController();
    final nxt = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: cur, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe actuel')),
          const SizedBox(height: 12),
          TextField(controller: nxt, obscureText: true, decoration: const InputDecoration(labelText: 'Nouveau (6 car. min.)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Valider')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await auth.changePassword(cur.text, nxt.text);
        if (context.mounted) toast(context, 'Mot de passe modifié ✅');
      } catch (e) {
        if (context.mounted) toast(context, '$e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(child: UserAvatar(name: user.name, radius: 46, admin: user.isAdmin)),
        const SizedBox(height: 12),
        Text(user.name, textAlign: TextAlign.center, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        Text(user.email, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Center(child: Pill(text: user.isAdmin ? 'Administrateur' : 'Étudiant', color: user.isAdmin ? Colors.deepOrange : Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 24),
        if (!user.isAdmin)
          Row(children: [
            Expanded(child: StatTile(label: 'Cours suivis', value: user.coursesCount, icon: Icons.menu_book, color: Colors.indigo)),
            const SizedBox(width: 12),
            Expanded(child: StatTile(label: 'Leçons terminées', value: user.lessonsDone, icon: Icons.task_alt, color: Colors.green)),
          ]),
        const SizedBox(height: 20),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Modifier mon nom'), trailing: const Icon(Icons.chevron_right), onTap: () => _editName(context)),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.lock_reset), title: const Text('Changer le mot de passe'), trailing: const Icon(Icons.chevron_right), onTap: () => _changePassword(context)),
          ]),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.read<AuthProvider>().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
        ),
      ],
    );
  }
}
