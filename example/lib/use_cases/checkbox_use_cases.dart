import 'package:flutter/widgets.dart';
import 'package:foss_ui/foss_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Playground', type: FossCheckbox)
Widget playgroundCheckbox(BuildContext context) {
  final label = context.knobs.string(
    label: 'Label',
    initialValue: 'Accept terms and conditions',
  );
  final description = context.knobs.string(label: 'Description');
  final error = context.knobs.string(label: 'Error');
  final indeterminate = context.knobs.boolean(label: 'Indeterminate');
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);

  return Center(
    child: SizedBox(
      width: 280,
      child: _CheckboxDemo(
        label: label.isEmpty ? null : label,
        description: description.isEmpty ? null : description,
        errorText: error.isEmpty ? null : error,
        indeterminate: indeterminate,
        enabled: enabled,
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'States', type: FossCheckbox)
Widget statesCheckbox(BuildContext context) => Center(
  child: SizedBox(
    width: 280,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        FossCheckbox(label: 'Unchecked', onChanged: (_) {}),
        FossCheckbox(value: true, label: 'Checked', onChanged: (_) {}),
        FossCheckbox(value: null, label: 'Indeterminate', onChanged: (_) {}),
        FossCheckbox(
          value: true,
          label: 'With description',
          description: 'A secondary line below the title',
          onChanged: (_) {},
        ),
        const FossCheckbox(
          value: true,
          label: 'Error',
          errorText: 'This field is required',
        ),
        const FossCheckbox(value: true, label: 'Disabled', enabled: false),
      ],
    ),
  ),
);

@widgetbook.UseCase(name: 'Group', type: FossCheckboxGroup)
Widget groupCheckbox(BuildContext context) {
  final card = context.knobs.boolean(label: 'Card');
  final label = context.knobs.string(
    label: 'Label',
    initialValue: 'Frameworks',
  );
  final error = context.knobs.string(label: 'Error');
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);

  return Center(
    child: SizedBox(
      width: 280,
      child: _CheckboxGroupDemo(
        variant: card
            ? FossCheckboxGroupVariant.card
            : FossCheckboxGroupVariant.plain,
        label: label.isEmpty ? null : label,
        errorText: error.isEmpty ? null : error,
        enabled: enabled,
      ),
    ),
  );
}

class _CheckboxDemo extends StatefulWidget {
  const _CheckboxDemo({
    required this.indeterminate,
    required this.enabled,
    this.label,
    this.description,
    this.errorText,
  });

  final bool indeterminate;
  final bool enabled;
  final String? label;
  final String? description;
  final String? errorText;

  @override
  State<_CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<_CheckboxDemo> {
  bool _value = false;

  @override
  Widget build(BuildContext context) => FossCheckbox(
    value: widget.indeterminate ? null : _value,
    label: widget.label,
    description: widget.description,
    errorText: widget.errorText,
    enabled: widget.enabled,
    onChanged: (value) => setState(() => _value = value),
  );
}

class _CheckboxGroupDemo extends StatefulWidget {
  const _CheckboxGroupDemo({
    required this.variant,
    required this.enabled,
    this.label,
    this.errorText,
  });

  final FossCheckboxGroupVariant variant;
  final bool enabled;
  final String? label;
  final String? errorText;

  @override
  State<_CheckboxGroupDemo> createState() => _CheckboxGroupDemoState();
}

class _CheckboxGroupDemoState extends State<_CheckboxGroupDemo> {
  Set<String> _values = {'next'};

  @override
  Widget build(BuildContext context) => FossCheckboxGroup<String>(
    variant: widget.variant,
    label: widget.label,
    errorText: widget.errorText,
    enabled: widget.enabled,
    values: _values,
    onChanged: (values) => setState(() => _values = values),
    children: const [
      FossCheckboxItem(
        value: 'next',
        label: 'Next.js',
        description: 'React framework',
      ),
      FossCheckboxItem(value: 'vite', label: 'Vite'),
      FossCheckboxItem(value: 'astro', label: 'Astro'),
    ],
  );
}
