
import 'package:flutter/material.dart';

import '../../data/models/study_group.dart';

/*
 * Dialog per la creazione e la modifica di un gruppo.
 * Restituisce i dati inseriti senza effettuare chiamate REST.
 */
class GroupFormDialog extends StatefulWidget {
  final StudyGroup? group;

  const GroupFormDialog({
    super.key,
    this.group,
  });

  @override
  State<GroupFormDialog> createState() =>
      _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    // In modifica mostra i dati attuali del gruppo.
    _nameController = TextEditingController(
      text: widget.group?.name ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.group?.description ?? '',
    );
  }

  // Valida i campi e restituisce i dati alla schermata.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();

    Navigator.of(context).pop(
      (
      name: _nameController.text.trim(),
      description: description.isEmpty
          ? null
          : description,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.group != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Modifica gruppo' : 'Crea gruppo',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Nome del gruppo',
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Inserisci un nome';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrizione (facoltativa)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            isEditing ? 'Salva' : 'Crea',
          ),
        ),
      ],
    );
  }
}
