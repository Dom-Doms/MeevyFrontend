
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/subject.dart';
import '../widgets/subject_card.dart';

import '../../../resource/data/repositories/resources_repository.dart';
import '../../../resource/presentation/view_models/subject_notes_view_model.dart';
import '../../../resource/presentation/widgets/subject_notes_tab.dart';


import '../../../checklist/data/repositories/checklist_repository.dart';
import '../../../checklist/presentation/view_models/checklist_view_model.dart';
import '../../../checklist/presentation/widgets/subject_checklist_tab.dart';

import '../../../flashcard/data/repositories/flashcards_repository.dart';
import '../../../flashcard/presentation/view_models/subject_flashcards_view_model.dart';
import '../../../flashcard/presentation/widgets/subject_flashcards_tab.dart';


/*
 * Contenitore delle funzionalità di una singola materia.
 *
 * Appunti, Checklist e Flashcard sono tre tab indipendenti,
 * ognuna responsabile della propria interfaccia.
 */
class SubjectDetailScreen extends StatelessWidget {
  final Subject subject;
  final VoidCallback onBack;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const SubjectDetailScreen({
    super.key,
    required this.subject,
    required this.onBack,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return MultiProvider(
      providers: [
        // Appunti personali della materia.
        ChangeNotifierProvider(
          create: (context) => SubjectNotesViewModel(
            ResourcesRepository(context.read<Dio>()),
            subject.id,
          )..load(),
        ),

        // Checklist personale della materia.
        ChangeNotifierProvider(
          create: (context) => ChecklistViewModel(
            ChecklistRepository(context.read<Dio>()),
            subject.id,
          )..load(),
        ),

        // Flashcard personali della materia.
        ChangeNotifierProvider(
          create: (context) => SubjectFlashcardsViewModel(
            FlashcardsRepository(context.read<Dio>()),
            subject.id,
          )..load(),
        ),
      ],


      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Torna alle materie',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('Le tue materie'),
            actions: [
              IconButton(
                tooltip: 'Rinomina materia',
                onPressed: onRename,
                icon: const Icon(Icons.edit_outlined),
              ),

              IconButton(
                tooltip: 'Elimina materia',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),

            ],
          ),

          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intestazione comune alle tre funzionalità.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16, 12, 16, 20,
                ),
                child: Row(
                  children: [
                    SubjectIcon(
                      subject: subject,
                      size: 64,
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Text(
                        subject.name,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),


                    const SizedBox(width: 12),

                    // Il cerchio si aggiorna quando cambia la checklist.
                    Consumer<ChecklistViewModel>(
                      builder: (context, checklist, _) {
                        final total = checklist.items.length;

                        final completed = checklist.items
                            .where((item) => item.completed)
                            .length;

                        final hasProgress =
                            checklist.hasChecklist &&
                                !checklist.isLoading &&
                                checklist.errorMessage == null &&
                                total > 0;

                        final double? fraction = hasProgress
                            ? completed / total
                            : null;

                        final label = fraction == null
                            ? '—'
                            : '${(fraction * 100).round()}%';

                        final colors = Theme.of(context).colorScheme;

                        return SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: fraction ?? 0,
                                  strokeWidth: 6,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor:
                                  colors.surfaceContainerHighest,
                                ),
                              ),
                              Text(
                                label,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge,
                              ),
                            ],
                          ),
                        );
                      },
                    ),


                  ],
                ),
              ),

              /*
               * TabBar controlla la sezione attualmente
               * selezionata tramite DefaultTabController.
               */
              const TabBar(
                tabs: [
                  Tab(
                    icon: Icon(
                      Icons.description_outlined,
                    ),
                    text: 'Appunti',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.checklist_outlined,
                    ),
                    text: 'Checklist',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.style_outlined,
                    ),
                    text: 'Flashcard',
                  ),
                ],
              ),

              /*
               * Viene visualizzato un solo contenuto
               * alla volta, in base alla tab selezionata.
               */

              const Expanded(
                child: TabBarView(
                  children: [
                    SubjectNotesTab(),
                    SubjectChecklistTab(),
                    SubjectFlashcardsTab(),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
