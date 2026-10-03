import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shake/shake.dart';
import '../../core/format.dart';
import '../../data/entities/note.dart';
import '../cubit/notes_cubit.dart';
import '../cubit/notes_state.dart';
import '../widgets/location_chip.dart';
import 'add_note_screen.dart';
import 'note_detail_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  late final ShakeDetector _shake;

  @override
  void initState() {
    super.initState();
    _shake = ShakeDetector.autoStart(
      onPhoneShake: (_) async {
        if (!mounted) return;
        final deleted = await context.read<NotesCubit>().deleteAll();
        if (deleted && mounted) _showDeleted();
      },
    );
  }

  @override
  void dispose() {
    _shake.stopListening();
    super.dispose();
  }

  void _showDeleted() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('All notes deleted')));
  }

  Future<void> _confirmDeleteAll(int count) async {
    final cubit = context.read<NotesCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_sweep_rounded,
            size: 40, color: Theme.of(ctx).colorScheme.error),
        title: const Text('Delete all notes?', textAlign: TextAlign.center),
        content: Text(
          count == 1
              ? 'Your note will be deleted. This cannot be undone.'
              : 'All $count notes will be deleted. This cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete all')),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await cubit.deleteAll();
    if (deleted && mounted) _showDeleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          BlocBuilder<NotesCubit, NotesState>(
            builder: (context, state) {
              if (state.notes.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Delete all notes',
                onPressed: () => _confirmDeleteAll(state.notes.length),
                icon: Icon(Icons.delete_sweep_rounded,
                    color: Theme.of(context).colorScheme.error),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text(state.error!));
          }
          if (state.notes.isEmpty) return const _EmptyState();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: state.notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _NoteCard(
              key: ValueKey(state.notes[i].id),
              note: state.notes[i],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddNoteScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New note'),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  const _NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: muted),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(note.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  if (note.hasLocation) ...[
                    const SizedBox(width: 12),
                    Flexible(child: LocationChip(label: note.locationLabel)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit_note_rounded,
                  size: 56, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text('No notes yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tap "New note" to write your first one.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
