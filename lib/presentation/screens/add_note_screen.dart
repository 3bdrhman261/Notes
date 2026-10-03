import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/core/location_service.dart';
import 'package:notes_app/core/note_validator.dart';
import 'package:notes_app/presentation/cubit/notes_cubit.dart';
import 'package:notes_app/presentation/widgets/location_gate.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late final LocationService _service;

  bool _useLocation = false;
  bool _saving = false;
  String _savingLabel = 'Saving...';
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _service = context.read<LocationService>();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving) return; // prevent double taps

    final titleError = NoteValidator.validateTitle(_titleController.text);
    final descError = NoteValidator.validateDescription(_descController.text);
    if (titleError != null || descError != null) {
      setState(() => _titleError = titleError);
      if (descError != null) _snack(descError);
      return;
    }

    setState(() {
      _saving = true;
      _savingLabel = 'Saving...';
    });

    try {
      // Location is only handled now, when the user presses Save.
      var withLocation = _useLocation;
      if (withLocation) {
        setState(() => _savingLabel = 'Getting location...');
        GateResult gate;
        try {
          gate = await ensureLocationReady(context, _service);
        } catch (_) {
          gate = GateResult.cancelled;
        }
        if (!mounted) return;

        if (gate == GateResult.openedSettings) {
          // User went to the settings: stay here so they can press Save again.
          setState(() => _saving = false);
          _snack('Turn on location, then press Save again');
          return;
        }
        withLocation = gate == GateResult.ready;
      }

      final locationOk = await context.read<NotesCubit>().addNote(
            title: _titleController.text,
            description: _descController.text,
            useLocation: withLocation,
          );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final skipped = _useLocation && (!withLocation || !locationOk);
      Navigator.pop(context);
      if (skipped) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Note saved without location')));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New note')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              enabled: !_saving,
              autofocus: true,
              maxLength: NoteValidator.titleMaxLength,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Title',
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              enabled: !_saving,
              minLines: 5,
              maxLines: 8,
              maxLength: NoteValidator.maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CheckboxListTile(
                value: _useLocation,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _useLocation = v ?? false),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Add my location'),
                subtitle: Text(_useLocation
                    ? 'Your location will be added when you save'
                    : 'Optional'),
                secondary: Icon(Icons.location_on_rounded,
                    color: _useLocation
                        ? scheme.primary
                        : scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? _savingLabel : 'Save note'),
            ),
          ],
        ),
      ),
    );
  }
}
