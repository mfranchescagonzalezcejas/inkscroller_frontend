import 'package:flutter/material.dart';

import '../../../library/domain/entities/manga_tags.dart';

/// Modal selector that prevents an empty demographic preference.
class DemographicSelectionDialog extends StatefulWidget {
  const DemographicSelectionDialog({super.key, required this.options, required this.current, required this.labelFor, required this.emptySelectionMessage});
  final List<MangaDemographic> options;
  final Set<MangaDemographic> current;
  final String Function(MangaDemographic) labelFor;
  final String emptySelectionMessage;
  @override State<DemographicSelectionDialog> createState() => _DemographicSelectionDialogState();
}

class _DemographicSelectionDialogState extends State<DemographicSelectionDialog> {
  late Set<MangaDemographic> selected = Set.of(widget.current);
  String? error;
  @override Widget build(BuildContext context) => AlertDialog(
    title: const Text('Demographics'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      ...widget.options.map((option) => CheckboxListTile(value: selected.contains(option), title: Text(widget.labelFor(option)), onChanged: (checked) => setState(() { if (checked ?? false) { selected.add(option); } else { selected.remove(option); } }))),
      if (error != null) Text(error!),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (selected.isEmpty) { setState(() => error = widget.emptySelectionMessage); } else { Navigator.pop(context, selected); } }, child: const Text('OK'))],
  );
}
