import 'package:flutter/material.dart';

/// Wraps [child] in a minimal app for button widget tests.
Widget host(Widget child) => MaterialApp(home: Center(child: child));
