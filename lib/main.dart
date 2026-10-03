import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/domain/notes_repository.dart';
import 'package:notes_app/presentation/cubit/notes_cubit.dart';
import 'package:notes_app/presentation/screens/notes_list_screen.dart';
import 'core/app_theme.dart';
import 'core/location_service.dart';
import 'data/database/app_database.dart';
import 'data/repository/notes_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await $FloorAppDatabase.databaseBuilder('notes.db').build();
  runApp(NotesApp(
    repository: NotesRepositoryImpl(db.noteDao),
    locationService: LocationService(),
  ));
}

class NotesApp extends StatelessWidget {
  final NotesRepository repository;
  final LocationService locationService;

  const NotesApp({
    super.key,
    required this.repository,
    required this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: locationService,
      child: BlocProvider(
        create: (_) => NotesCubit(repository, locationService),
        child: MaterialApp(
          title: 'Notes',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          home: const NotesListScreen(),
        ),
      ),
    );
  }
}
