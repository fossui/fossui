import 'package:flutter/material.dart';
import 'package:foss_ui/foss_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Playground', type: FossAlertDialog)
Widget playgroundAlertDialog(BuildContext context) {
  final filled = context.knobs.boolean(label: 'Filled footer');
  final description = context.knobs.boolean(
    label: 'Description',
    initialValue: true,
  );

  return Center(
    child: FossButton(
      variant: FossButtonVariant.destructive,
      onPressed: () => showFossAlertDialog<void>(
        context: context,
        builder: (context) => FossAlertDialog(
          footerVariant: filled
              ? FossDialogFooterVariant.filled
              : FossDialogFooterVariant.bare,
          title: const Text('Delete account'),
          description: description
              ? const Text('This is permanent and cannot be undone.')
              : null,
          actions: [
            FossButton(
              variant: FossButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FossButton(
              variant: FossButtonVariant.destructive,
              onPressed: () => Navigator.pop(context),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      child: const Text('Delete account'),
    ),
  );
}
