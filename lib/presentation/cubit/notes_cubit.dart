import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/core/location_service.dart';
import 'package:notes_app/core/note_validator.dart';
import 'package:notes_app/data/entities/note.dart';
import 'package:notes_app/domain/notes_repository.dart';

import 'notes_state.dart';

class NotesCubit extends Cubit<NotesState> {
  final NotesRepository _repo;
  final LocationService _location;
  late final StreamSubscription<List<Note>> _sub;

  NotesCubit(this._repo, this._location) : super(const NotesState()) {
    // Floor's Stream keeps the list in sync after any insert/update/delete.
    _sub = _repo.watchNotes().listen(
          (notes) => emit(NotesState(notes: notes, loading: false)),
          onError: (_) => emit(
              const NotesState(loading: false, error: 'Failed to load notes')),
        );
  }

  bool _isValid(String title, String description) =>
      NoteValidator.validateTitle(title) == null &&
      NoteValidator.validateDescription(description) == null;

  /// Returns false if location was requested but couldn't be obtained
  /// (the note is still saved, without location).
  Future<bool> addNote({
    required String title,
    required String description,
    required bool useLocation,
  }) async {
    if (!_isValid(title, description)) return true;

    NoteLocation? location;
    if (useLocation) location = await _location.getCurrentLocation();

    await _repo.add(Note(
      title: title.trim(),
      content: description.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      latitude: location?.latitude,
      longitude: location?.longitude,
      placeName: location?.placeName,
    ));
    return !useLocation || location != null;
  }

  Future<void> updateNote(
    Note note, {
    required String title,
    required String description,
  }) async {
    if (!_isValid(title, description)) return;
    final t = title.trim();
    final d = description.trim();
    if (t == note.title && d == note.content) return;
    await _repo.update(note.copyWith(title: t, content: d));
  }

  Future<void> deleteNote(Note note) async {
    if (note.id == null) return;
    await _repo.delete(note.id!);
  }

  /// Returns false when there was nothing to delete.
  Future<bool> deleteAll() async {
    if (state.notes.isEmpty) return false;
    await _repo.deleteAll();
    return true;
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
