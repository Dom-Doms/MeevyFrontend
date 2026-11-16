
import 'package:flutter/material.dart';

/*
 * Permette all'utente di inserire il token
 * ricevuto da un proprietario o moderatore.
 */
class JoinGroupDialog extends StatefulWidget {
  const JoinGroupDialog({super.key});

  @override
  State<JoinGroupDialog> createState() =>
      _JoinGroupDialogState();
}

class _JoinGroupDialogState
    extends State<JoinGroupDialog> {
  final _formKey = GlobalKey<FormState>();

  final _tokenController = TextEditingController();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _tokenController.text.trim(),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unisciti a un gruppo'),

      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Inserisci il codice di invito '
                    'che hai ricevuto.',
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _tokenController,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization:
                TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Codice di invito',
                  prefixIcon: Icon(
                    Icons.key_outlined,
                  ),
                ),
                validator: (value) {
                  final token = value?.trim() ?? '';

                  if (token.isEmpty) {
                    return 'Inserisci il codice.';
                  }

                  // Il DTO del backend richiede
                  // esattamente 43 caratteri.
                  if (token.length != 43) {
                    return 'Il codice deve contenere '
                        '43 caratteri.';
                  }

                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: 12),

              Text(
                'Il codice può essere utilizzato '
                    'una sola volta ed è valido per 24 ore.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annulla'),
        ),

        FilledButton(
          onPressed: _submit,
          child: const Text('Unisciti'),
        ),
      ],
    );
  }
}
