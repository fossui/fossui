import 'package:flutter/widgets.dart';
import 'package:foss_ui/foss_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: FossSpinner)
Widget defaultSpinner(BuildContext context) {
  final size = context.knobs.double.slider(
    label: 'Size',
    initialValue: 24,
    min: 12,
    max: 64,
  );
  return Center(child: FossSpinner(size: size));
}
