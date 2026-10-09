import 'package:flutter/material.dart';

/// Wraps [child] in a minimal app with the bar pinned to the bottom, the shape
/// it is used in.
Widget host(Widget child, {double width = 393, double height = 200}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[child],
            ),
          ),
        ),
      ),
    );
