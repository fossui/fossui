import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

void main() => runApp(const ExampleApp());

/// Registers the fossui theme and renders a handful of components so the
/// gallery below reads tokens through `context.fossTheme`.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fossui example',
      theme: FossThemeData.light.toThemeData(),
      darkTheme: FossThemeData.dark.toThemeData(),
      home: const Gallery(),
    );
  }
}

/// A single screen showing a few components stacked in a column.
class Gallery extends StatefulWidget {
  /// Creates the gallery screen.
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  bool _notify = true;

  @override
  Widget build(BuildContext context) {
    final spacing = context.fossTheme.spacing;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: spacing.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: spacing(4),
            children: [
              const FossBadge(label: Text('fossui')),
              FossCard(
                title: const Text('Welcome'),
                description: const Text('A Flutter UI library.'),
                content: FossSwitch(
                  value: _notify,
                  onChanged: (value) => setState(() => _notify = value),
                ),
              ),
              FossButton(onPressed: () {}, child: const Text('Get started')),
            ],
          ),
        ),
      ),
    );
  }
}
