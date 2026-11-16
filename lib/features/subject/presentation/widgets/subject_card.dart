
import 'package:flutter/material.dart';

import '../../data/models/subject.dart';

// Azioni disponibili nel menu di una materia.
enum SubjectAction { rename, delete }

/*
 * Icona grafica della materia.
 * Il colore viene ricavato dall'identificativo,
 * così rimane coerente nelle diverse schermate.
 */
class SubjectIcon extends StatelessWidget {
  final Subject subject;
  final double size;

  const SubjectIcon({
    super.key,
    required this.subject,
    this.size = 48,
  });

  static const _colors = [
    Color(0xFF367A53),
    Color(0xFF287DB5),
    Color(0xFFB84942),
    Color(0xFF6B55AC),
    Color(0xFFB8860B),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[subject.id % _colors.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.menu_book_outlined,
        color: color,
        size: size * 0.5,
      ),
    );
  }
}

/*
 * Card riutilizzabile dell'elenco delle materie.
 * Delega apertura, modifica ed eliminazione
 * alla schermata che la contiene.
 */
class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onOpen;
  //final VoidCallback onRename;
  //final VoidCallback onDelete;
  final bool isSaving;


  const SubjectCard({
    super.key,
    required this.subject,
    required this.onOpen,
    this.isSaving = false,
  });


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Tutta la card permette di aprire la materia.
        onTap: isSaving ? null : onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubjectIcon(subject: subject),

              const SizedBox(height: 12),

              Text(
                subject.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
