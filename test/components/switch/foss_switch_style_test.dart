import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  group('FossSwitchStyle.merge', () {
    test('null other returns the receiver unchanged', () {
      const base = FossSwitchStyle(trackWidth: 38, thumbSize: 20);
      expect(identical(base.merge(null), base), isTrue);
    });

    test('non-null fields of other win, the rest are kept', () {
      const base = FossSwitchStyle(
        trackWidth: 38,
        trackHeight: 22,
        thumbSize: 20,
        activeTrackColor: Color(0xFF000001),
      );
      const override = FossSwitchStyle(
        thumbSize: 18,
        activeTrackColor: Color(0xFF000002),
      );

      final merged = base.merge(override);

      expect(merged.trackWidth, 38);
      expect(merged.trackHeight, 22);
      expect(merged.thumbSize, 18);
      expect(merged.activeTrackColor, const Color(0xFF000002));
    });
  });
}
