
import 'package:flutter/foundation.dart';

import '../../data/models/personal_resource.dart';
import '../../data/repositories/resources_repository.dart';

import 'package:file_picker/file_picker.dart';


import 'dart:typed_data';
import 'package:dio/dio.dart';


/*
 * Distingue tre possibili risultati:
 *
 * deleted: il documento non è più presente.
 * notDeleted: il documento è ancora presente.
 * unknown: non possiamo verificare l'esito.
 */
enum ResourceDeletionStatus {
  deleted,
  notDeleted,
  unknown,
}





/*
 * Gestisce gli appunti appartenenti a una materia.
 * Conserva elenco, caricamento ed eventuali errori.
 */
class SubjectNotesViewModel extends ChangeNotifier {
  final ResourcesRepository _repository;
  final int subjectId;

  List<PersonalResource> _resources = [];

  bool _isLoading = false;
  bool _disposed = false;

  bool _isUploading = false;
  String? _uploadMessage;

// Stato del download di un documento.
  bool _isDownloading = false;
  String? _downloadError;

  bool get isDownloading => _isDownloading;
  String? get downloadError => _downloadError;


// Stato dell'eliminazione di un documento.
  bool _isDeleting = false;
  int? _deletingResourceId;
  String? _deleteMessage;

  bool get isDeleting => _isDeleting;
  int? get deletingResourceId => _deletingResourceId;
  String? get deleteMessage => _deleteMessage;


  //upload
  bool get isUploading => _isUploading;
  String? get uploadMessage => _uploadMessage;


  String? _errorMessage;

  SubjectNotesViewModel(
      this._repository,
      this.subjectId,
      );

  List<PersonalResource> get resources =>
      List.unmodifiable(_resources);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // Carica gli appunti della materia dal suploadFileserver.
  Future<void> load() async {

    if (_isLoading || _isDeleting || _disposed) return;


    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getBySubject(
        subjectId,
      );

      if (_disposed) return;

      _resources = result;
    } catch (_) {
      if (_disposed) return;

      _errorMessage = 'Impossibile caricare gli appunti.';
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }


/*
 * Carica i documenti selezionati dall'utente.
 * Ogni documento usa l'endpoint REST esistente.
 *
 * Rifiuta i file vuoti o superiori al limite
 * e aggiorna l'elenco dopo i caricamenti riusciti.
 */
  Future<void> uploadFiles(List<PlatformFile> files) async {
    if (_isUploading || _isLoading ||
        _isDeleting|| _disposed) return;
    if (files.isEmpty) return;

    const maxFileSize = 20 * 1024 * 1024;

    _isUploading = true;
    _uploadMessage = null;
    notifyListeners();

    int uploaded = 0;
    int failed = 0;

    try {
      for (final file in files) {
        if (_disposed) return;


        // Ogni file deve avere un percorso valido,
        // essere non vuoto e rispettare il limite di 20 MB.
        if (file.path == null ||
            file.size == 0 ||
            file.size > maxFileSize) {
          failed++;
          continue;
        }



        try {
          await _repository.upload(
            subjectId: subjectId,
            filePath: file.path!,
            filename: file.name,
          );

          uploaded++;
        } catch (_) {
          // Un documento fallito non blocca i successivi.
          failed++;
        }
      }

      if (_disposed) return;

      if (uploaded > 0) {
        try {
          _resources = await _repository.getBySubject(
            subjectId,
          );
          _errorMessage = null;
        } catch (_) {
          _errorMessage =
          'File caricati, ma non è stato possibile '
              'aggiornare l’elenco.';
        }
      }

      if (_disposed) return;

      _uploadMessage = '$uploaded file caricati';

      if (failed > 0) {
        _uploadMessage =
        '$_uploadMessage, $failed non caricati. '
            'Controlla formato, dimensione e connessione.';
      }
    } finally {
      if (!_disposed) {
        _isUploading = false;
        notifyListeners();
      }
    }
  }


/*
 * Recupera i byte di un documento tramite il Repository.
 *
 * Verifica che il contenuto scaricato abbia la dimensione
 * registrata nel database, evitando file incompleti.
 *
 * Il salvataggio sul dispositivo resta responsabilità
 * della View, che interagisce con il selettore Android.
 */
  Future<Uint8List?> download(
      PersonalResource resource,
      ) async {
    if (_isDownloading || _isDeleting || _disposed) return null;

    _isDownloading = true;
    _downloadError = null;
    notifyListeners();

    try {
      final bytes = await _repository.download(resource.id);

      if (_disposed) return null;

      // Impedisce di salvare un documento incompleto.
      if (bytes.lengthInBytes != resource.sizeBytes) {
        _downloadError =
        'Il file scaricato è incompleto. Riprova.';
        return null;
      }

      return bytes;
    } on DioException catch (error) {
      if (_disposed) return null;

      if (error.response?.statusCode == 404) {
        _downloadError =
        'Il documento non è più disponibile.';
      } else if (error.response == null) {
        _downloadError =
        'Impossibile contattare il server.';
      } else {
        _downloadError =
        'Impossibile scaricare il documento.';
      }

      return null;
    } catch (_) {
      if (!_disposed) {
        _downloadError =
        'Si è verificato un errore durante il download.';
      }

      return null;
    } finally {
      if (!_disposed) {
        _isDownloading = false;
        notifyListeners();
      }
    }
  }


/*
 * Elimina un documento personale e riconcilia
 * l'elenco con lo stato effettivo del backend.
 *
 * Anche se DELETE restituisce errore, verifichiamo
 * se il documento è ancora presente: il backend
 * può aver eliminato il record prima di incontrare
 * un problema nella cancellazione fisica.
 */
  Future<ResourceDeletionStatus> deleteResource(
      PersonalResource resource,
      ) async {
    if (_disposed ||
        _isLoading ||
        _isUploading ||
        _isDownloading ||
        _isDeleting) {
      return ResourceDeletionStatus.unknown;
    }

    _isDeleting = true;
    _deletingResourceId = resource.id;
    _deleteMessage = null;
    notifyListeners();

    bool deleteConfirmed = false;

    try {
      try {
        await _repository.delete(resource.id);
        deleteConfirmed = true;
      } catch (_) {
        // Il risultato HTTP non basta a stabilire
        // se il record sia ancora presente.
      }

      if (_disposed) {
        return ResourceDeletionStatus.unknown;
      }

      try {
        // Recupera l'elenco autorevole dopo il tentativo.
        final updated = await _repository.getBySubject(
          subjectId,
        );

        if (_disposed) {
          return ResourceDeletionStatus.unknown;
        }

        _resources = updated;
        _errorMessage = null;

        final stillExists = updated.any(
              (item) => item.id == resource.id,
        );

        if (!stillExists) {
          _deleteMessage = 'Appunto eliminato.';
          return ResourceDeletionStatus.deleted;
        }

        if (deleteConfirmed) {
          _deleteMessage =
          'Il server ha confermato l’eliminazione, '
              'ma il documento risulta ancora presente. '
              'Aggiorna l’elenco.';
          return ResourceDeletionStatus.unknown;
        }

        _deleteMessage =
        'Non è stato possibile eliminare il documento.';
        return ResourceDeletionStatus.notDeleted;
      } catch (_) {
        if (_disposed) {
          return ResourceDeletionStatus.unknown;
        }

        if (deleteConfirmed) {
          /*
         * DELETE è riuscita, ma il refresh è fallito.
         * Aggiorniamo soltanto l'elemento confermato,
         * senza fingere di avere l'elenco aggiornato.
         */
          _resources = _resources
              .where((item) => item.id != resource.id)
              .toList();

          _deleteMessage =
          'Appunto eliminato. '
              'Non è stato possibile aggiornare '
              'l’intero elenco.';

          return ResourceDeletionStatus.deleted;
        }

        _deleteMessage =
        'Non è possibile verificare se il documento '
            'sia stato eliminato. Aggiorna l’elenco '
            'prima di riprovare.';

        return ResourceDeletionStatus.unknown;
      }
    } finally {
      if (!_disposed) {
        _isDeleting = false;
        _deletingResourceId = null;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
