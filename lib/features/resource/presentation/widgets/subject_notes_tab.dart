
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/personal_resource.dart';
import '../view_models/subject_notes_view_model.dart';

import 'package:file_picker/file_picker.dart';


/*
 * Contenuto della tab Appunti.
 * Visualizza soltanto i file della materia selezionata.
 */
class SubjectNotesTab extends StatefulWidget {
  const SubjectNotesTab({super.key});

  @override
  State<SubjectNotesTab> createState() =>
      _SubjectNotesTabState();
}

class _SubjectNotesTabState extends State<SubjectNotesTab> {
  String _query = '';

  // Rappresenta la dimensione del file in formato leggibile.
  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Sceglie l'aspetto dell'icona in base al tipo di file.
  Widget _fileIcon(PersonalResource resource) {
    final filename = resource.originalFilename.toLowerCase();

    final Color color;
    final IconData icon;

    if (filename.endsWith('.pdf')) {
      color = const Color(0xFFB84942);
      icon = Icons.picture_as_pdf_outlined;
    } else if (filename.endsWith('.docx') ||
        filename.endsWith('.doc')) {
      color = const Color(0xFF287DB5);
      icon = Icons.description_outlined;
    } else {
      color = Theme.of(context).colorScheme.primary;
      icon = Icons.insert_drive_file_outlined;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );


  }


  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubjectNotesViewModel>();
    final theme = Theme.of(context);

    final resources = viewModel.resources.where((resource) {
      return resource.originalFilename
          .toLowerCase()
          .contains(_query.toLowerCase().trim());
    }).toList();

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16, 16, 16, 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appunti',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    onChanged: (value) {
                      setState(() => _query = value);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Cerca un file...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ],
              ),
            ),

            if (viewModel.isUploading)
              const LinearProgressIndicator(),

            Expanded(
              child: _buildResourceList(
                viewModel,
                resources,
              ),
            ),
          ],
        ),

        // Il pulsante compare soltanto nella tab Appunti.
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'upload_appunti',
            tooltip: 'Carica appunti',
            onPressed: viewModel.isUploading
                ? null
                : () => _pickAndUpload(viewModel),
            child: viewModel.isUploading
                ? const CircularProgressIndicator()
                : const Icon(Icons.add),
          ),
        ),
      ],
    );
  }



/*
 * Apre il selettore dei file Android.
 * Delega il caricamento al ViewModel della materia.
 */
  Future<void> _pickAndUpload(
      SubjectNotesViewModel viewModel,
      ) async {
    try {

      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: false,
      );

// Se l'utente annulla, non viene restituito alcun risultato.
      if (result == null || !mounted) return;

// Nella versione 11, i file sono contenuti in result.files.
      await viewModel.uploadFiles(result.files);

      if (!mounted) return;

      final message = viewModel.uploadMessage;

      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossibile selezionare i documenti.',
          ),
        ),
      );
    }
  }


  Widget _buildResourceList(
      SubjectNotesViewModel viewModel,
      List<PersonalResource> resources,
      ) {
    if (viewModel.isLoading &&
        viewModel.resources.isEmpty) {
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
            const SizedBox(height: 12),
            FilledButton(
              onPressed: viewModel.load,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (resources.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),

            const Icon(
              Icons.folder_open_outlined,
              size: 60,
            ),

            const SizedBox(height: 16),

            Text(
              viewModel.resources.isEmpty
                  ? 'Non ci sono ancora appunti.'
                  : 'Nessun file trovato.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16, 0, 16, 20,
        ),
        itemCount: resources.length,
        separatorBuilder: (_, _) =>
        const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final resource = resources[index];

          final date = MaterialLocalizations.of(context)
              .formatShortDate(
            resource.createdAt.toLocal(),
          );

          return Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant,
              ),
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              leading: _fileIcon(resource),
              title: Text(
                resource.originalFilename,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${_formatSize(resource.sizeBytes)} · $date',
              ),
            ),
          );
        },
      ),
    );
  }
}
