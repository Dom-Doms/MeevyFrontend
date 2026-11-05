
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/session/session_view_model.dart';
import '../view_models/subjects_view_model.dart';

/*
 * Visualizza le materie personali recuperate dal backend.
 * Permette di aggiornare l'elenco e disconnettersi.
 */
class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Le mie materie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Esci',
            onPressed: () {
              context.read<SessionViewModel>().logout();
            },
          ),
        ],
      ),
      body: Consumer<SubjectsViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(viewModel.errorMessage!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: viewModel.load,
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.subjects.isEmpty) {
            return const Center(
              child: Text('Non hai ancora creato materie.'),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.load,
            child: ListView.builder(
              itemCount: viewModel.subjects.length,
              itemBuilder: (context, index) {
                final subject = viewModel.subjects[index];

                return ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: Text(subject.name),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
