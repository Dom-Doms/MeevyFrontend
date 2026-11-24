
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
            viewModel.actionError ?? 'Operazione non completata.'
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChecklistViewModel>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Solo gli errori di caricamento bloccano la schermata.
    if (viewModel.errorMessage != null) {
      return Center(
        child: FilledButton(
          onPressed: viewModel.load,
          child: const Text('Errore di caricamento · Riprova'),
        ),
      );
    }

    final items = viewModel.items;
    final total = items.length;
    final completed = items.where((item) => item.completed).length;

    return Stack(
      children: [
        Column(
          children: [
            // Riepilogo compatto della checklist.
            if (total > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, 12,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completed di $total completate',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '${(completed / total * 100).round()}%',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    LinearProgressIndicator(
                      value: completed / total,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor:
                      colors.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),

            if (viewModel.isSaving)
              const LinearProgressIndicator(minHeight: 2),

            Expanded(
              child: RefreshIndicator(
                onRefresh: viewModel.load,
                child: items.isEmpty
                // Nessun passaggio "Crea checklist".
                    ? ListView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    24, 80, 24, 96,
                  ),
                  children: [
                    Icon(
                      Icons.checklist_outlined,
                      size: 56,
                      color: colors.onSurfaceVariant,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Nessuna attività',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Tocca + per aggiungere la prima.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                )

                // Elenco leggero, senza Card.
                    : ListView.separated(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    12, 8, 12, 96,
                  ),
                  itemCount: items.length,

                  separatorBuilder: (_, _) =>
                  const Divider(
                    height: 1,
                    indent: 52,
                    endIndent: 12,
                  ),

                  itemBuilder: (context, index) {
                    final item = items[index];

                    return CheckboxListTile(
                      key: ValueKey(item.id),
                      value: item.completed,

                      controlAffinity:
                      ListTileControlAffinity.leading,

                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),

                      title: Text(
                        item.text,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(
                          decoration: item.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: item.completed
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                        ),
                      ),

                      // Conferma lo stato tramite il backend.
                      onChanged: viewModel.isSaving
                          ? null
                          : (_) async {
                        final success =
                        await viewModel.toggle(item);

                        if (!success && context.mounted) {
                          _showError(
                            context,
                            viewModel,
                          );
                        }
                      },

                      // Menu di modifica ed eliminazione.
                      secondary: PopupMenuButton<String>(
                        tooltip: 'Gestisci attività',
                        enabled: !viewModel.isSaving,

                        onSelected: (action) {
                          if (action == 'edit') {
                            _edit(context, viewModel, item);
                          } else if (action == 'delete') {
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        // Unico pulsante + per checklist nuove ed esistenti.
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
