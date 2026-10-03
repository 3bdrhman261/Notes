import 'package:equatable/equatable.dart';
import 'package:notes_app/data/entities/note.dart';

class NotesState extends Equatable {
  final List<Note> notes;
  final bool loading;
  final String? error;

  const NotesState({this.notes = const [], this.loading = true, this.error});

  @override
  List<Object?> get props => [notes, loading, error];
}

