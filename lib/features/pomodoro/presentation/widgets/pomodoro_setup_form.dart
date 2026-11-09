import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../subject/data/repositories/subjects_repository.dart';
import '../../../subject/presentation/view_models/subjects_view_model.dart';
import '../view_models/pomodoro_view_model.dart';

/*
 * Form per configurare una nuova sessione Pomodoro.
 *
 * Le materie vengono recuperate dal backend.
 * Le durate vengono scelte in minuti, mentre il Repository
 * le convertirà in secondi prima della POST.
 */
class PomodoroSetupForm extends StatefulWidget {
  const PomodoroSetupForm({super.key});

  @override
  State<PomodoroSetupForm> createState() => _PomodoroSetupFormState();
}

class _PomodoroSetupFormState extends State<PomodoroSetupForm> {
  late final SubjectsViewModel _subjectsViewModel;

  int? _selectedSubjectId;

  int _studyMinutes = 25;
  int _breakMinutes = 5;
  int _targetMinutes = 120;

  @override
  void initState() {
    super.initState();

    // Utilizziamo il client Dio autenticato già presente nell'app.
    _subjectsViewModel = SubjectsViewModel(
      SubjectsRepository(context.read<Dio>()),
    );

    unawaited(_subjectsViewModel.load());
  }

  /*
   * Invia la configurazione al PomodoroViewModel.
   *
   * Non effettua direttamente chiamate HTTP:
   * questa responsabilità rimane nel Repository.
   */
  Future<void> _createSession() async {
    final subjectId = _selectedSubjectId;

    if (subjectId == null) return;

    await context.read<PomodoroViewModel>().createSession(
      subjectId: subjectId,
      studyMinutes: _studyMinutes,
      breakMinutes: _breakMinutes,
      targetMinutes: _targetMinutes,
    );
  }

  /*
   * Costruisce un selettore riutilizzabile per le durate.
   */
  Widget _buildMinutesDropdown({
    required String label,
    required int value,
    required List<int> options,
    required ValueChanged<int?>? onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options.map((minutes) {
        return DropdownMenuItem<int>(
          value: minutes,
          child: Text('$minutes min'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroViewModel>();

    return AnimatedBuilder(
      animation: _subjectsViewModel,
      builder: (context, _) {
        // Caricamento iniziale delle materie.
        if (_subjectsViewModel.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Errore nel recupero delle materie.
        if (_subjectsViewModel.errorMessage != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _subjectsViewModel.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _subjectsViewModel.load,
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
              ),
            ],
          );
        }

        final subjects = _subjectsViewModel.subjects;

        // Il backend richiede obbligatoriamente una materia.
        if (subjects.isEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_outlined, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Nessuna materia disponibile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Per creare un Pomodoro devi avere almeno '
                'una materia associata al tuo account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _subjectsViewModel.load,
                icon: const Icon(Icons.refresh),
                label: const Text('Aggiorna materie'),
              ),
            ],
          );
        }

        final isBusy = pomodoro.isPerformingAction;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const Text(
              'Scegli la materia e configura '
              'i tuoi intervalli di studio.',
            ),

            const SizedBox(height: 24),

            // Selezione della materia.
            DropdownButtonFormField<int>(
              initialValue: _selectedSubjectId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Materia',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Seleziona una materia'),
              items: subjects.map((subject) {
                return DropdownMenuItem<int>(
                  value: subject.id,
                  child: Text(subject.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: isBusy
                  ? null
                  : (value) {
                      setState(() {
                        _selectedSubjectId = value;
                      });
                    },
            ),

            const SizedBox(height: 20),

            // Durata di studio e pausa.
            Row(
              children: [
                Expanded(
                  child: _buildMinutesDropdown(
                    label: 'Studio',
                    value: _studyMinutes,
                    options: const [15, 25, 40, 50],
                    onChanged: isBusy
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              _studyMinutes = value;
                            });
                          },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildMinutesDropdown(
                    label: 'Pausa',
                    value: _breakMinutes,
                    options: const [5, 10, 15],
                    onChanged: isBusy
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              _breakMinutes = value;
                            });
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Obiettivo complessivo della sessione.
            _buildMinutesDropdown(
              label: 'Durata totale',
              value: _targetMinutes,
              options: const [30, 60, 120, 180, 240],
              onChanged: isBusy
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _targetMinutes = value;
                      });
                    },
            ),

            const SizedBox(height: 24),

            // Riepilogo della configurazione.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riepilogo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$_studyMinutes min studio · '
                    '$_breakMinutes min pausa',
                  ),

                  Text('Obiettivo: $_targetMinutes minuti'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Mostra gli errori della POST senza perdere il form.
            if (pomodoro.actionError != null) ...[
              Text(
                pomodoro.actionError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],

            if (isBusy) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],

            FilledButton.icon(
              onPressed: _selectedSubjectId == null || isBusy
                  ? null
                  : _createSession,
              icon: const Icon(Icons.add),
              label: Text(isBusy ? 'Creazione in corso...' : 'Crea sessione'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Libera il ViewModel delle materie quando il form viene rimosso.
    _subjectsViewModel.dispose();
    super.dispose();
  }
}
