import 'package:flutter/material.dart';
import 'package:foss_ui/foss_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Playground', type: FossDialog)
Widget playgroundDialog(BuildContext context) {
  final filled = context.knobs.boolean(label: 'Filled footer');
  final showClose = context.knobs.boolean(
    label: 'Close button',
    initialValue: true,
  );
  final description = context.knobs.boolean(
    label: 'Description',
    initialValue: true,
  );
  final longBody = context.knobs.boolean(label: 'Long body');

  return Center(
    child: FossButton(
      onPressed: () => showFossDialog<void>(
        context: context,
        builder: (context) => FossDialog(
          showCloseButton: showClose,
          footerVariant: filled
              ? FossDialogFooterVariant.filled
              : FossDialogFooterVariant.bare,
          title: const Text('Delete project'),
          description: description
              ? const Text('This permanently removes the project.')
              : null,
          content: longBody ? Text('Lorem ipsum dolor sit amet. ' * 30) : null,
          actions: [
            FossButton(
              variant: FossButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FossButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      child: const Text('Open dialog'),
    ),
  );
}

@widgetbook.UseCase(name: 'Scrolling', type: FossDialog)
Widget scrollingDialog(BuildContext context) => Center(
  child: FossButton(
    onPressed: () => showFossDialog<void>(
      context: context,
      builder: (context) => FossDialog(
        title: const Text('Terms'),
        content: Text('All clear. ' * 200),
        footerVariant: FossDialogFooterVariant.filled,
        actions: [
          FossButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Accept'),
          ),
        ],
      ),
    ),
    child: const Text('Open long dialog'),
  ),
);
