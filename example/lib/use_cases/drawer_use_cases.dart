import 'package:flutter/material.dart';
import 'package:foss_ui/foss_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Playground', type: FossDrawer)
Widget playgroundDrawer(BuildContext context) {
  final side = context.knobs.object.dropdown(
    label: 'Side',
    options: FossDrawerSide.values,
    labelBuilder: (s) => s.name,
  );
  final straight = context.knobs.boolean(label: 'Straight corners');
  final filled = context.knobs.boolean(label: 'Filled footer');
  final handle = context.knobs.boolean(label: 'Handle', initialValue: true);
  final close = context.knobs.boolean(label: 'Close button');
  final description = context.knobs.boolean(
    label: 'Description',
    initialValue: true,
  );
  final longBody = context.knobs.boolean(label: 'Long body');

  return Center(
    child: FossButton(
      onPressed: () => showFossDrawer<void>(
        context: context,
        side: side,
        builder: (context) => FossDrawer(
          variant: straight
              ? FossDrawerVariant.straight
              : FossDrawerVariant.rounded,
          footerVariant: filled
              ? FossDrawerFooterVariant.filled
              : FossDrawerFooterVariant.bare,
          showHandle: handle,
          showCloseButton: close,
          title: const Text('Filters'),
          description: description ? const Text('Narrow the results.') : null,
          content: longBody ? Text('Lorem ipsum dolor sit amet. ' * 30) : null,
          actions: [
            FossButton(
              variant: FossButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
              child: const Text('Reset'),
            ),
            FossButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
      child: const Text('Open drawer'),
    ),
  );
}

@widgetbook.UseCase(name: 'Scrolling', type: FossDrawer)
Widget scrollingDrawer(BuildContext context) => Center(
  child: FossButton(
    onPressed: () => showFossDrawer<void>(
      context: context,
      builder: (context) => FossDrawer(
        showHandle: true,
        title: const Text('Terms'),
        content: Text('All clear. ' * 200),
        footerVariant: FossDrawerFooterVariant.filled,
        actions: [
          FossButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Accept'),
          ),
        ],
      ),
    ),
    child: const Text('Open long drawer'),
  ),
);

@widgetbook.UseCase(name: 'Side panel', type: FossDrawer)
Widget sidePanelDrawer(BuildContext context) => Center(
  child: FossButton(
    onPressed: () => showFossDrawer<void>(
      context: context,
      side: FossDrawerSide.right,
      builder: (context) => const FossDrawer(
        showCloseButton: true,
        title: Text('Account'),
        description: Text('A side panel that slides in from the edge.'),
        content: Text('Profile, billing, and preferences live here.'),
      ),
    ),
    child: const Text('Open side panel'),
  ),
);
