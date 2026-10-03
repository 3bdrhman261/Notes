import 'package:notes_app/data/entities/note.dart';

abstract class NotesRepository {
  Stream<List<Note>> watchNotes();
  Future<void> add(Note note);
  Future<void> update(Note note);
  Future<void> delete(int id);
  Future<void> deleteAll();
}

