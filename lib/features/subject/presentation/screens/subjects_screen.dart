
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../data/models/subject.dart';
import '../widgets/subject_card.dart';
import 'subject_detail_screen.dart';

import '../view_models/subjects_view_model.dart';

import '../../../../app/widgets/meevy_page_header.dart';


/*
 * Visualizza le materie personali dell'utente.
 * Permette di cercare, ordinare, creare, modificare
 * ed eliminare le materie e accedere al loro dettaglio.
 */
class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() =>
      _SubjectsScreenState();


}

/*
 * Gestisce ricerca, ordinamento e navigazione
 * tra elenco e dettaglio delle materie.
 */
class _SubjectsScreenState extends State<SubjectsScreen> {
  final _searchController = TextEditingController();

// Gestisce le sottoschermate della sezione Materie.
  final _subjectNavigatorKey = GlobalKey<NavigatorState>();


  int? _selectedSubjectId;
  bool _ascending = true;


  // Filtra e ordina una copia dell'elenco originale.
  List<Subject> _visibleSubjects(List<Subject> subjects) {
    final query = _searchController.text
        .trim()
        .toLowerCase();

    final result = subjects.where((subject) {
      return subject.name.toLowerCase().contains(query);
    }).toList();

    result.sort((first, second) {
      final comparison = first.name.toLowerCase().compareTo(
        second.name.toLowerCase(),
      );

      return _ascending ? comparison : -comparison;
    });

    return result;
  }

  /*
   * Un unico dialog viene utilizzato sia per creare
   * una materia sia per modificarne il nome.
   */
  Future<void> _showSubjectForm({
    Subject? subject,
  }) async {
    final formKey = GlobalKey<FormState>();
    String name = subject?.name ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            subject == null
                ? 'Nuova materia'
                : 'Rinomina materia',
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              initialValue: name,
              autofocus: true,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Nome della materia',
              ),
              onChanged: (value) => name = value,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Inserisci un nome.';
                }

                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(
                    name.trim(),
                  );
                }
              },
              child: Text(
                subject == null ? 'Crea' : 'Salva',
              ),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) return;

    final viewModel = context.read<SubjectsViewModel>();

    final success = subject == null
        ? await viewModel.create(result)
        : await viewModel.update(subject.id, result);

    if (!mounted) return;

    if (!success) {
      _showError(viewModel.saveError);
    }
  }

  // Richiede conferma prima di eliminare una materia.
  Future<void> _deleteSubject(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Elimina materia?'),
//TODO cambiare la scritta dell'elimina
          content: Text(
            'Vuoi eliminare "${subject.name}"?\n\n'
                'Gli appunti e le flashcard rimarranno salvati, '
                'ma non saranno più associati a questa materia. '
                'La checklist verrà eliminata.\n\n'
                'L’operazione non può essere annullata.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annulla'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                Theme.of(context).colorScheme.error,
                foregroundColor:
                Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final viewModel = context.read<SubjectsViewModel>();
    final success = await viewModel.delete(subject.id);

    if (!mounted) return;

    if (!success) {
      _showError(viewModel.saveError);
    }
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? 'Operazione non completata.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubjectsViewModel>();

    final selectedSubject = _selectedSubjectId == null
        ? null
        : viewModel.findById(_selectedSubjectId!);

    /*
     * Mostra il dettaglio all'interno della MainShell,
     * mantenendo visibile la barra di navigazione.
     */

    if (selectedSubject != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          final navigator = _subjectNavigatorKey.currentState;

          // Prima chiude un eventuale dettaglio flashcard.
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
            return;
          }

          // Altrimenti torna all'elenco delle materie.
          _closeSubjectDetail(viewModel);
        },
        child: Navigator(
          key: _subjectNavigatorKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => SubjectDetailScreen(
                key: ValueKey(selectedSubject.id),
                subject: selectedSubject,
                onBack: () => _closeSubjectDetail(viewModel),
                onRename: viewModel.isSaving
                    ? null
                    : () => _showSubjectForm(
                  subject: selectedSubject,
                ),
                onDelete: viewModel.isSaving
                    ? null
                    : () => _deleteSubject(selectedSubject),
              ),
            );
          },
        ),
      );
    }


    return Scaffold(

      floatingActionButton: FloatingActionButton(
        tooltip: 'Aggiungi materia',
        onPressed: viewModel.isSaving ||
            viewModel.isLoading
            ? null
            : () => _showSubjectForm(),
        child: const Icon(Icons.add),
      ),


      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),

            if (viewModel.isSaving)
              const LinearProgressIndicator(),

            Expanded(
              child: _buildSubjects(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  // Intestazione con ricerca e ordinamento delle materie.
  Widget _buildHeader(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20, 12, 20, 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MeevyPageHeader(
          title: 'Le tue materie',
          ),


          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cerca una materia...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                      tooltip: 'Cancella ricerca',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              PopupMenuButton<bool>(
                tooltip: 'Ordina materie',
                initialValue: _ascending,
                icon: const Icon(Icons.sort),
                onSelected: (value) {
                  setState(() => _ascending = value);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: true,
                    child: Text('Nome A-Z'),
                  ),
                  PopupMenuItem(
                    value: false,
                    child: Text('Nome Z-A'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Gestisce caricamento, errori, elenco vuoto e griglia.
  Widget _buildSubjects(SubjectsViewModel viewModel) {
    if (viewModel.isLoading &&
        viewModel.subjects.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewModel.errorMessage != null &&
        viewModel.subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewModel.errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: viewModel.load,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    final subjects = _visibleSubjects(
      viewModel.subjects,
    );

    if (subjects.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            const Icon(
              Icons.menu_book_outlined,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.subjects.isEmpty
                  ? 'Non hai ancora creato materie.'
                  : 'Nessuna materia trovata.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    /*
     * La griglia si adatta alla larghezza disponibile.
     * Su uno smartphone normalmente mostra due colonne.
     */
    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16, 0, 16, 96,
        ),
        gridDelegate:
        const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          mainAxisExtent: 190,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];




          return SubjectCard(
            key: ValueKey(subject.id),
            subject: subject,
            progress: viewModel.progressFor(subject.id),
            isSaving: viewModel.isSaving || viewModel.isLoading,
            onOpen: () {
              setState(() {
                _selectedSubjectId = subject.id;
              });
            },
          );

        },
      ),
    );
  }

// Chiude il dettaglio e aggiorna i progressi dal server.
  void _closeSubjectDetail(SubjectsViewModel viewModel) {
    setState(() {
      _selectedSubjectId = null;
    });

    viewModel.load();
  }

}
