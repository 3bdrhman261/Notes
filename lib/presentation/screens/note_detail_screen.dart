import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/core/format.dart';
import 'package:notes_app/core/note_validator.dart';
import 'package:notes_app/data/entities/note.dart';
import 'package:notes_app/presentation/cubit/notes_cubit.dart';
import 'package:notes_app/presentation/widgets/location_chip.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _descController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    await context.read<NotesCubit>().updateNote(
          widget.note,
          title: _titleController.text,
          description: _descController.text,
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final cubit = context.read<NotesCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await cubit.deleteNote(widget.note);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final titleError = NoteValidator.validateTitle(_titleController.text);
    final descError = NoteValidator.validateDescription(_descController.text);
    final changed = _titleController.text.trim() != note.title ||
        _descController.text.trim() != note.content;
    final canUpdate = changed && titleError == null && descError == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit note'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _delete,
            icon: Icon(Icons.delete_outline_rounded,
                color: theme.colorScheme.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: muted),
                const SizedBox(width: 4),
                Text(formatDate(note.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                if (note.hasLocation) ...[
                  const SizedBox(width: 12),
                  Flexible(child: LocationChip(label: note.locationLabel)),
                ],
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              maxLength: NoteValidator.titleMaxLength,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  InputDecoration(hintText: 'Title', errorText: titleError),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              minLines: 5,
              maxLines: 8,
              maxLength: NoteValidator.maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(hintText: 'Description (optional)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              onPressed: canUpdate ? _update : null,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Update note'),
            ),
          ],
        ),
      ),
    );
  }
}
