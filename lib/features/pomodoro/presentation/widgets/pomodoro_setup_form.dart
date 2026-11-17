import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../subject/data/repositories/subjects_repository.dart';
import '../../../subject/presentation/view_models/subjects_view_model.dart';
import '../view_models/pomodoro_view_model.dart';
import 'pomodoro_timer_ring.dart';

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

  int _cycleCount = 4;

// La durata totale è calcolata, non scelta dall'utente.
// Ogni ciclo comprende una fase di studio e una pausa.
  int get _targetMinutes =>
      (_studyMinutes + _breakMinutes) * _cycleCount;

// Mostra la durata in ore e minuti.
  String get _formattedTotalDuration {
    final hours = _targetMinutes ~/ 60;
    final minutes = _targetMinutes % 60;

    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours h';

    return '$hours h $minutes min';
  }


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
 * Card riutilizzabile per configurare le durate.
 *
 * I pulsanti + e - scorrono esclusivamente
 * tra i valori consentiti dall'interfaccia.
 */
  Widget _buildDurationCard({
    required IconData icon,
    required String title,
    required int value,
    required List<int> options,
    required ValueChanged<int> onChanged,
    required bool enabled,
    String Function(int)? formatValue,
  }) {
    final index = options.indexOf(value);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF4D8B67)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C6672),
                  ),
                ),
              ),
            ],
          ),


          Row(
            children: [
              // Il pulsante sinistro occupa sempre 36 pixel.
              SizedBox(
                width: 36,
                height: 40,
                child: IconButton(
                  onPressed: enabled && index > 0
                      ? () => onChanged(options[index - 1])
                      : null,
                  icon: const Icon(Icons.remove),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),

              // Il valore è sempre centrato rispetto alla card.
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatValue?.call(value) ?? '$value min',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // Il pulsante destro occupa esattamente lo stesso spazio.
              SizedBox(
                width: 36,
                height: 40,
                child: IconButton(
                  onPressed:
                  enabled && index >= 0 && index < options.length - 1
                      ? () => onChanged(options[index + 1])
                      : null,
                  icon: const Icon(Icons.add),
                  iconSize: 18,
                  color: const Color(0xFF4D8B67),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),

        ],
      ),
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
            // Anteprima grafica del timer.
            // Non avvia alcuna sessione prima della creazione.
            Center(
              child: PomodoroTimerRing(
                phaseLabel: 'Studio',
                timeText: '${_studyMinutes.toString().padLeft(2, '0')}:00',
                statusText: 'Anteprima',
                progress: 0.0,
              ),
            ),

            const SizedBox(height: 24),

            // Durata dello studio e della pausa.
            Row(
              children: [
                Expanded(
                  child: _buildDurationCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Durata studio',
                    value: _studyMinutes,
                    options: const [15, 25, 40, 50],
                    enabled: !isBusy,
                    onChanged: (value) {
                      setState(() {
                        _studyMinutes = value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildDurationCard(
                    icon: Icons.free_breakfast_outlined,
                    title: 'Pausa breve',
                    value: _breakMinutes,
                    options: const [5, 10, 15],
                    enabled: !isBusy,
                    onChanged: (value) {
                      setState(() {
                        _breakMinutes = value;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Materia associata alla sessione.

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE8E3EF),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 23,
                    color: Color(0xFF4D8B67),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Materia associata',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6C6672),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Evita il doppio bordo creato dal tema globale.
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedSubjectId,
                            isExpanded: true,
                            isDense: true,
                            borderRadius: BorderRadius.circular(16),
                            dropdownColor: Colors.white,
                            hint: const Text(
                              'Seleziona una materia',
                              overflow: TextOverflow.ellipsis,
                            ),
                            items: subjects.map((subject) {
                              return DropdownMenuItem<int>(
                                value: subject.id,
                                child: Text(
                                  subject.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 16),


// Numero di cicli che l'utente vuole completare.
            _buildDurationCard(
              icon: Icons.repeat,
              title: 'Numero di cicli',
              value: _cycleCount,
              options: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
              enabled: !isBusy,
              formatValue: (value) =>
              value == 1 ? '1 ciclo' : '$value cicli',
              onChanged: (value) {
                setState(() {
                  _cycleCount = value;
                });
              },
            ),

            const SizedBox(height: 12),

// Riepilogo aggiornato automaticamente.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F7F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Durata complessiva',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6C6672),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _formattedTotalDuration,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4D8B67),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${_studyMinutes * _cycleCount} min di studio + '
                        '${_breakMinutes * _cycleCount} min di pausa',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 24),

            // Errori della creazione, senza perdere il form.
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

            // Crea la sessione tramite il ViewModel esistente.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedSubjectId == null || isBusy
                    ? null
                    : _createSession,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4D8B67),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.add),
                label: Text(isBusy ? 'Creazione in corso...' : 'Crea sessione'),
              ),
            ),

            const SizedBox(height: 20),
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
