import 'package:flutter/material.dart';
import 'package:foss_ui/foss_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Playground', type: FossToaster)
Widget playgroundToast(BuildContext context) {
  final type = context.knobs.object.dropdown(
    label: 'Type',
    options: FossToastType.values,
    initialOption: FossToastType.success,
    labelBuilder: (v) => v.name,
  );
  final title = context.knobs.string(label: 'Title', initialValue: 'Saved');
  final description = context.knobs.string(
    label: 'Description',
    initialValue: 'Your changes are live.',
  );

  return FossToaster(
    child: Builder(
      builder: (context) => Center(
        child: FossButton(
          onPressed: () => showFossToast(
            context,
            FossToast(
              type: type,
              title: title.isEmpty ? null : Text(title),
              description: description.isEmpty ? null : Text(description),
            ),
          ),
          child: const Text('Show toast'),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Types', type: FossToaster)
Widget typesToast(BuildContext context) => FossToaster(
  child: Builder(
    builder: (context) => Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final type in FossToastType.values)
            FossButton(
              variant: FossButtonVariant.outline,
              size: FossButtonSize.sm,
              onPressed: () => showFossToast(
                context,
                FossToast(
                  type: type,
                  title: Text(type.name),
                  description: const Text('An example notification.'),
                ),
              ),
              child: Text(type.name),
            ),
        ],
      ),
    ),
  ),
);
