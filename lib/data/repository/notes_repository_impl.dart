import 'package:notes_app/domain/notes_repository.dart';
import '../dao/note_dao.dart';
import '../entities/note.dart';

class NotesRepositoryImpl implements NotesRepository {
  final NoteDao _dao;
  NotesRepositoryImpl(this._dao);

  @override
  Stream<List<Note>> watchNotes() => _dao.watchAll();

  @override
  Future<void> add(Note note) => _dao.insertNote(note);

  @override
  Future<void> update(Note note) => _dao.updateNote(note);

  @override
  Future<void> delete(int id) => _dao.deleteById(id);

  @override
  Future<void> deleteAll() => _dao.deleteAll();
}

