import 'package:flutter/material.dart';
import 'package:foss_ui/foss_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Playground', type: FossAlert)
Widget playgroundAlert(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: 'Variant',
    options: FossAlertVariant.values,
    initialOption: FossAlertVariant.info,
    labelBuilder: (v) => v.name,
  );
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Heads up',
  );
  final description = context.knobs.string(
    label: 'Description',
    initialValue: 'Something worth your attention.',
  );
  final showAction = context.knobs.boolean(label: 'Action');

  return Center(
    child: SizedBox(
      width: 360,
      child: FossAlert(
        variant: variant,
        title: title.isEmpty ? null : Text(title),
        description: description.isEmpty ? null : Text(description),
        actions: showAction
            ? [
                FossButton(
                  variant: FossButtonVariant.ghost,
                  size: FossButtonSize.sm,
                  onPressed: () {},
                  child: const Text('Dismiss'),
                ),
              ]
            : const [],
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Variants', type: FossAlert)
Widget variantsAlert(BuildContext context) => Center(
  child: SizedBox(
    width: 360,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        for (final variant in FossAlertVariant.values)
          FossAlert(
            variant: variant,
            title: Text(variant.name),
            description: const Text('A short status message.'),
          ),
      ],
    ),
  ),
);
