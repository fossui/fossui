import 'package:flutter/material.dart';

/// Wraps [child] in a minimal app for slider widget tests.
Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);
