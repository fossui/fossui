import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:foss_ui/foss_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Playground', type: FossButton)
Widget playgroundButton(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: 'Variant',
    options: FossButtonVariant.values,
    initialOption: FossButtonVariant.primary,
    labelBuilder: (v) => v.name,
  );
  final size = context.knobs.object.dropdown(
    label: 'Size',
    options: FossButtonSize.values,
    initialOption: FossButtonSize.md,
    labelBuilder: (s) => s.name,
  );
  final label = context.knobs.string(label: 'Label', initialValue: 'Continue');
  final loading = context.knobs.boolean(label: 'Loading');
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);

  return Center(
    child: FossButton(
      onPressed: enabled ? () {} : null,
      variant: variant,
      size: size,
      loading: loading,
      child: Text(label),
    ),
  );
}

@widgetbook.UseCase(name: 'Variants', type: FossButton)
Widget variantsButton(BuildContext context) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: [
      for (final variant in FossButtonVariant.values)
        FossButton(
          onPressed: () {},
          variant: variant,
          child: Text(variant.name),
        ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Icon', type: FossButton)
Widget iconButton(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: 'Variant',
    options: FossButtonVariant.values,
    initialOption: FossButtonVariant.primary,
    labelBuilder: (v) => v.name,
  );
  final size = context.knobs.object.dropdown(
    label: 'Size',
    options: FossButtonSize.values,
    initialOption: FossButtonSize.md,
    labelBuilder: (s) => s.name,
  );

  return Center(
    child: FossButton.icon(
      onPressed: () {},
      variant: variant,
      size: size,
      semanticLabel: 'Add',
      icon: const Icon(Icons.add),
    ),
  );
}
