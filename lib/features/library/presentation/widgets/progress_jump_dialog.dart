import 'package:flutter/material.dart';
import 'package:inkscroller_flutter/core/design/design_tokens.dart'
    show AppTypography;
import 'package:inkscroller_flutter/core/l10n/l10n.dart';

/// Shows a dialog with a numeric input to jump to a specific chapter number.
///
/// Returns the chapter number on confirm, or `null` on cancel.
Future<int?> showProgressJumpDialog(
  BuildContext context, {
  required int totalChaptersCount,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) =>
        _ProgressJumpDialogBody(totalChaptersCount: totalChaptersCount),
  );
}

class _ProgressJumpDialogBody extends StatefulWidget {
  const _ProgressJumpDialogBody({required this.totalChaptersCount});

  final int totalChaptersCount;

  @override
  State<_ProgressJumpDialogBody> createState() =>
      _ProgressJumpDialogBodyState();
}

class _ProgressJumpDialogBodyState extends State<_ProgressJumpDialogBody> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  void _validate() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = context.l10n.jumpToChapterInvalid);
      return;
    }
    final number = int.tryParse(text);
    if (number == null || number < 0 || number > widget.totalChaptersCount) {
      setState(() => _error = context.l10n.jumpToChapterInvalid);
      return;
    }
    Navigator.of(context).pop(number);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(
        context.l10n.jumpToChapter,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: context.l10n.jumpToChapterHint,
          errorText: _error,
          filled: true,
          fillColor: colorScheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _validate(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            context.l10n.dialogCancel,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        FilledButton(
          onPressed: _validate,
          child: Text(context.l10n.dialogConfirm),
        ),
      ],
    );
  }
}
