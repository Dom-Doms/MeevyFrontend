
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../data/models/subject.dart';
import '../widgets/subject_card.dart';
import 'subject_detail_screen.dart';

import '../view_models/subjects_view_model.dart';


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
          content: Text(
            'Vuoi eliminare "${subject.name}"? '
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
          if (!didPop) {
            setState(() => _selectedSubjectId = null);
          }
        },
        child: SubjectDetailScreen(
          key: ValueKey(selectedSubject.id),
          subject: selectedSubject,
          onBack: () {
            setState(() => _selectedSubjectId = null);
          },
          onRename: viewModel.isSaving
              ? null
              : () => _showSubjectForm(
            subject: selectedSubject,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.school_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text(
              'Meevy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Aggiungi materia',
        onPressed: viewModel.isSaving ||
            viewModel.isLoading
            ? null
            : () => _showSubjectForm(),
        child: const Icon(Icons.add),
      ),

      body: Column(
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
    );
  }

  // Intestazione con ricerca e ordinamento delle materie.
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16, 12, 16, 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Le tue materie',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Qui trovi tutte le materie che stai studiando.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
            isSaving: viewModel.isSaving || viewModel.isLoading,
            onOpen: () {
              setState(() {
                _selectedSubjectId = subject.id;
              });
            },
            onRename: () => _showSubjectForm(
              subject: subject,
            ),
            onDelete: () => _deleteSubject(subject),
          );
        },
      ),
    );
  }
}
