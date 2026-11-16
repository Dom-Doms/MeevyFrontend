
import 'package:flutter/foundation.dart';

import '../../data/models/personal_resource.dart';
import '../../data/repositories/resources_repository.dart';

import 'package:file_picker/file_picker.dart';


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

  // Carica gli appunti della materia dal server.
  Future<void> load() async {
    if (_isLoading || _disposed) return;

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
    if (_isUploading || _isLoading || _disposed) return;
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


  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
