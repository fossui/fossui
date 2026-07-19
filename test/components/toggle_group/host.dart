import 'package:flutter/material.dart';

/// Wraps [child] in a minimal app for toggle group widget tests.
Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: Center(child: child)),
      ),
    );
