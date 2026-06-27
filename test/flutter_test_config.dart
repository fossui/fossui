import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final isCi = Platform.environment['CI'] == 'true';

  // Real face only matters for the platform flavor; CI obscures text.
  await _loadGeist();

  // References render differently per platform, so each flavor is verified only
  // where it was generated: the Ahem flavor on CI, the host-rendered flavor
  // locally.
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      ciGoldensConfig: CiGoldensConfig(enabled: isCi),
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isCi),
    ),
    run: testMain,
  );
}

Future<void> _loadGeist() async {
  final file = File('fonts/Geist-Variable.ttf');
  if (!file.existsSync()) return;
  final loader = FontLoader('Geist')
    ..addFont(file.readAsBytes().then((b) => b.buffer.asByteData()));
  await loader.load();
}
