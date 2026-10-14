import 'package:flutter/material.dart';
import 'models/models.dart';
import 'theme.dart';

/// Carte "surface" arrondie utilisée partout dans l'app.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const AppCard({super.key, required this.child, this.onTap,
      this.padding = const EdgeInsets.all(16),
      this.margin = const EdgeInsets.only(bottom: 12)});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C1C26) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(110)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Bandeau dégradé (en-têtes, bannières).
class GradientBox extends StatelessWidget {
  final Color color;
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  const GradientBox({super.key, required this.color, required this.child,
      this.padding = const EdgeInsets.all(20), this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
        ),
      ),
      child: child,
    );
  }
}

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  const CourseCard({super.key, required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 8,
            decoration: BoxDecoration(
              color: course.color,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Pill(text: course.category, color: course.color),
                  const SizedBox(width: 8),
                  Text(course.level, style: t.labelMedium),
                  const Spacer(),
                  if (course.isComplete)
                    const Icon(Icons.verified, color: Colors.green, size: 20),
                ]),
                const SizedBox(height: 8),
                Text(course.title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(course.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                const SizedBox(height: 12),
                if (course.enrolled) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                        value: course.progress, minHeight: 7, color: course.color),
                  ),
                  const SizedBox(height: 4),
                  Text('${course.doneCount}/${course.lessonCount} leçons • ${(course.progress * 100).round()} %',
                      style: t.bodySmall),
                ] else
                  Row(children: [
                    Icon(Icons.play_lesson_outlined, size: 16, color: course.color),
                    const SizedBox(width: 4),
                    Text('${course.lessonCount} leçons',
                        style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const StatTile({super.key, required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 12),
        Text('$value', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final bool admin;
  const UserAvatar({super.key, required this.name, this.radius = 22, this.admin = false});

  @override
  Widget build(BuildContext context) {
    final color = admin ? Colors.deepOrange : Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withAlpha(35),
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: radius * 0.85)),
    );
  }
}

class Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const Empty({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ]),
        ),
      );
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ]),
        ),
      );
}

void toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
}

Future<bool> confirm(BuildContext context, String title, String message,
    {String action = 'Supprimer'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
      ],
    ),
  );
  return r ?? false;
}

class ColorPicker extends StatelessWidget {
  final Color value;
  final ValueChanged<Color> onChanged;
  const ColorPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: kCourseColors
            .map((c) => GestureDetector(
                  onTap: () => onChanged(c),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: c.value == value.value ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                          width: 3),
                    ),
                    child: c.value == value.value ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                ))
            .toList(),
      );
}
