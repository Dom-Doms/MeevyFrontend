
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/personal_resource.dart';
import '../view_models/subject_notes_view_model.dart';

import 'package:file_picker/file_picker.dart';


// Azioni disponibili su un documento personale.
// In futuro aggiungeremo anche la condivisione.
enum _ResourceAction {
  delete,
}

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

// ID del documento che stiamo scaricando o salvando.
  int? _activeDownloadId;


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

// Ricava il formato da mostrare sotto il nome del file.
  String _formatFileType(PersonalResource resource) {
    final filename = resource.originalFilename;
    final dotIndex = filename.lastIndexOf('.');

    if (dotIndex <= 0 ||
        dotIndex == filename.length - 1) {
      return 'FILE';
    }

    final extension = filename
        .substring(dotIndex + 1)
        .toUpperCase();

    return extension.length <= 7
        ? extension
        : 'FILE';
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
            onPressed: viewModel.isUploading || //Disabilitiamo il caricamento durante un'eliminazione
                viewModel.isDeleting
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


/*
 * Scarica il documento dal server e apre
 * il selettore di salvataggio del dispositivo.
 *
 * Se l'utente annulla il salvataggio,
 * non viene mostrato alcun messaggio di errore.
 */
  Future<void> _downloadResource(
      PersonalResource resource,
      SubjectNotesViewModel viewModel,
      ) async {
    if (_activeDownloadId != null) return;

    setState(() {
      _activeDownloadId = resource.id;
    });

    try {
      // Recupera i byte tramite ViewModel e Repository.
      final bytes = await viewModel.download(resource);

      if (!mounted) return;

      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.downloadError ??
                  'Download non riuscito.',
            ),
          ),
        );
        return;
      }

      /*
     * Apre il selettore di salvataggio.
     * Su Android i byte vengono scritti nella
     * destinazione scelta dall'utente.
     */
      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Salva appunto',
        fileName: resource.originalFilename,
        bytes: bytes,
      );

      if (!mounted) return;

      // L'utente può annullare senza salvare nulla.
      if (savedPath == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${resource.originalFilename} salvato correttamente.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossibile salvare il documento.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _activeDownloadId = null;
        });
      }
    }
  }


/*
 * Chiede conferma prima di eliminare un documento.
 * La cancellazione è definitiva e viene eseguita
 * soltanto dopo la conferma dell'utente.
 */
  Future<void> _deleteResource(
      PersonalResource resource,
      SubjectNotesViewModel viewModel,
      ) async {
    if (viewModel.isDeleting ||
        viewModel.isUploading ||
        viewModel.isDownloading ||
        _activeDownloadId != null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text('Elimina appunto?'),
          content: Text(
            'Vuoi eliminare definitivamente '
                '"${resource.originalFilename}"?\n\n'
                'Il documento non potrà essere recuperato.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await viewModel.deleteResource(resource);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          viewModel.deleteMessage ??
              'Operazione non completata.',
        ),
      ),
    );
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
          padding: const EdgeInsets.fromLTRB(
            16, 0, 16, 96,
          ),
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


          final isBusy = viewModel.isUploading ||
              viewModel.isDeleting ||
              viewModel.isDownloading ||
              viewModel.isLoading ||
              _activeDownloadId != null;

          final isDeletingThis =
              viewModel.deletingResourceId == resource.id;

          final isDownloadingThis =
              _activeDownloadId == resource.id;

          return Card(
            key: ValueKey(resource.id),
            color: Theme.of(context).colorScheme.surface,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),

              leading: _fileIcon(resource),

              title: Text(
                resource.originalFilename,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_formatFileType(resource)} · '
                      '${_formatSize(resource.sizeBytes)} · $date',
                  maxLines: 2,
                ),
              ),

              /*
     * Download immediato e menu per le altre operazioni.
     * La condivisione sarà aggiunta qui quando
     * il backend supporterà i gruppi.
     */
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Scarica ${resource.originalFilename}',
                    onPressed: isBusy
                        ? null
                        : () => _downloadResource(
                      resource,
                      viewModel,
                    ),
                    icon: isDownloadingThis
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.download_outlined),
                  ),

                  if (isDeletingThis)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    PopupMenuButton<_ResourceAction>(
                      tooltip: 'Altre azioni',
                      enabled: !isBusy,
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        switch (action) {
                          case _ResourceAction.delete:
                            _deleteResource(
                              resource,
                              viewModel,
                            );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _ResourceAction.delete,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .error,
                              ),
                              const SizedBox(width: 12),
                              const Text('Elimina'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );

        },
      ),
    );
  }
}
