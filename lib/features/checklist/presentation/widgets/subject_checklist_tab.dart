
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/checklist_item.dart';
import '../view_models/checklist_view_model.dart';

/*
 * Interfaccia della checklist personale.
 * Permette di creare attività, modificarle e completarle.
 */
class SubjectChecklistTab extends StatelessWidget {
  const SubjectChecklistTab({super.key});

  Future<void> _edit(
      BuildContext context,
      ChecklistViewModel viewModel, [
        ChecklistItem? item,
      ]) async {
    final controller = TextEditingController(
      text: item?.text ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          item == null ? 'Nuova attività' : 'Modifica attività',
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Attività da studiare',
            ),
            validator: (value) =>
            value == null || value.trim().isEmpty
                ? 'Inserisci un’attività.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (text == null || !context.mounted) return;

    final success = item == null
        ? await viewModel.add(text)
        : await viewModel.rename(item, text);

    if (!success && context.mounted) {
      _showError(context, viewModel);
    }
  }

  Future<void> _remove(
      BuildContext context,
      ChecklistViewModel viewModel,
      ChecklistItem item,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Elimina attività?'),
        content: Text(item.text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (!await viewModel.remove(item) && context.mounted) {
      _showError(context, viewModel);
    }
  }

  void _showError(
      BuildContext context,
      ChecklistViewModel viewModel,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          viewModel.errorMessage ?? 'Operazione non completata.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChecklistViewModel>();

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: FilledButton(
          onPressed: viewModel.load,
          child: const Text('Errore di caricamento · Riprova'),
        ),
      );
    }


    if (!viewModel.hasChecklist) {
      return Stack(
        children: [
          const Center(
            child: Text('Nessuna checklist per questa materia.'),
          ),

          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'create_subject_checklist',
              tooltip: 'Crea checklist',
              onPressed: viewModel.isSaving
                  ? null
                  : () async {
                if (!await viewModel.create() &&
                    context.mounted) {
                  _showError(context, viewModel);
                }
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }


    final completed = viewModel.items
        .where((item) => item.completed)
        .length;

    return Stack(
        children: [
    Column(
    children: [
        /*Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Checklist',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('$completed/${viewModel.items.length} completate'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: viewModel.isSaving
                    ? null
                    : () => _edit(context, viewModel),
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi attività'),
              ),
              if (viewModel.isSaving)
                const LinearProgressIndicator(),
            ],
          ),
        ),
*/
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$completed/${viewModel.items.length} completate',
            ),
          ),
        ),

        if (viewModel.isSaving)
          const LinearProgressIndicator(),

        Expanded(
          child: RefreshIndicator(
            onRefresh: viewModel.load,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: viewModel.items.length,
              itemBuilder: (context, index) {
                final item = viewModel.items[index];

                return Card(
                  child: CheckboxListTile(
                    value: item.completed,
                    onChanged: viewModel.isSaving
                        ? null
                        : (_) async {
                      if (!await viewModel.toggle(item) &&
                          context.mounted) {
                        _showError(context, viewModel);
                      }
                    },
                    title: Text(item.text),
                    secondary: PopupMenuButton<String>(
                      enabled: !viewModel.isSaving,
                      onSelected: (action) {
                        if (action == 'edit') {
                          _edit(context, viewModel, item);
                        } else {
                          _remove(context, viewModel, item);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Modifica'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Elimina'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

    ],
    ),

          // Pulsante fisso in basso a destra.
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'add_checklist_item',
              tooltip: 'Aggiungi attività',
              onPressed: viewModel.isSaving
                  ? null
                  : () => _edit(context, viewModel),
              child: const Icon(Icons.add),
            ),
          ),
        ],
    );


  }
}
