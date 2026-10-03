import 'package:floor/floor.dart';
import '../entities/note.dart';

@dao
abstract class NoteDao {
  @Query('SELECT * FROM notes ORDER BY createdAt DESC')
  Stream<List<Note>> watchAll();

  @Query('DELETE FROM notes WHERE id = :id')
  Future<void> deleteById(int id);

  @Query('DELETE FROM notes')
  Future<void> deleteAll();

  @insert
  Future<int> insertNote(Note note);

  @update
  Future<void> updateNote(Note note);
}

