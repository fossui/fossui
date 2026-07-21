import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Fraction of pixels allowed to differ before a CI golden is a failure.
// Runner image drift (font hinting, antialiasing) shifts a handful of edge
// pixels between the run that generated a reference and the run that verifies
// it; observed drift sits near 0.02%. A real visual change moves well over 1%,
// so this absorbs the noise without masking regressions.
const _ciGoldenTolerance = 0.005;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final isCi = Platform.environment['CI'] == 'true';

  // Real face only matters for the platform flavor; CI obscures text.
  await _loadGeist();

  if (isCi) {
    final current = goldenFileComparator;
    if (current is LocalFileComparator) {
      // basedir carries no trailing slash, and LocalFileComparator derives its
      // own basedir by resolving away the final path segment; a trailing file
      // name keeps the real directory intact.
      goldenFileComparator = _TolerantComparator(
        Uri.parse('${current.basedir}/golden.dart'),
        _ciGoldenTolerance,
      );
    }
  }

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

/// A [LocalFileComparator] that passes when the differing-pixel fraction is at
/// or below [tolerance], so small runner-to-runner rendering drift does not
/// fail the build. Regeneration (`--update-goldens`) still writes exact refs.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile, this.tolerance);

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

Future<void> _loadGeist() async {
  final file = File('fonts/Geist-Variable.ttf');
  if (!file.existsSync()) return;
  final loader = FontLoader('packages/fossui/Geist')
    ..addFont(file.readAsBytes().then((b) => b.buffer.asByteData()));
  await loader.load();
}
