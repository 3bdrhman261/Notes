import 'package:flutter/material.dart';
import 'package:notes_app/core/location_service.dart';

enum GateResult { ready, cancelled, openedSettings }

/// Makes sure location is usable. If it's not, shows a dialog that asks the
/// user to turn on the GPS / grant the permission / open app settings.
Future<GateResult> ensureLocationReady(
  BuildContext context,
  LocationService service,
) async {
  var status = await service.checkStatus();

  while (status != LocationStatus.ready) {
    if (!context.mounted) return GateResult.cancelled;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => _LocationDialog(status: status),
    );
    if (accepted != true) return GateResult.cancelled;

    if (status == LocationStatus.serviceDisabled) {
      await service.openLocationSettings();
      return GateResult.openedSettings;
    }
    if (status == LocationStatus.deniedForever) {
      await service.openAppSettings();
      return GateResult.openedSettings;
    }
    // denied -> ask for the permission again
    status = await service.checkStatus();
  }
  return GateResult.ready;
}

class _LocationDialog extends StatelessWidget {
  final LocationStatus status;
  const _LocationDialog({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (icon, title, message, action) = switch (status) {
      LocationStatus.serviceDisabled => (
          Icons.location_off_rounded,
          'Turn on location',
          'Location services are off. Turn them on to attach your current place to the note.',
          'Open settings',
        ),
      LocationStatus.denied => (
          Icons.location_searching_rounded,
          'Allow location access',
          'We need your permission to get your current location and show the place name on your note.',
          'Allow',
        ),
      _ => (
          Icons.lock_outline_rounded,
          'Permission blocked',
          'Location permission was permanently denied. Enable it from the app settings.',
          'App settings',
        ),
    };

    return AlertDialog(
      icon: Icon(icon, size: 40, color: scheme.primary),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    );
  }
}

