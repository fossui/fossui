part of 'foss_colors.dart';

/// Primitive color palette: the raw swatches the semantic [FossColors] roles
/// are built from. Private and never exported; components read semantic roles,
/// not these. Each value is a fixed sRGB constant, and a swatch lives here only
/// when a semantic role references it.
abstract final class _FossPalette {
  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral400 = Color(0xFFA1A1A1);
  static const neutral500 = Color(0xFF737373);
  static const neutral800 = Color(0xFF262626);

  static const red400 = Color(0xFFFF6467);
  static const red500 = Color(0xFFFB2C36);
  static const red700 = Color(0xFFC10007);
  static const blue400 = Color(0xFF51A2FF);
  static const blue500 = Color(0xFF2B7FFF);
  static const blue700 = Color(0xFF1447E6);
  static const emerald400 = Color(0xFF00D492);
  static const emerald500 = Color(0xFF00BC7D);
  static const emerald700 = Color(0xFF007A55);
  static const amber400 = Color(0xFFFFBA00);
  static const amber500 = Color(0xFFFD9A00);
  static const amber700 = Color(0xFFBB4D00);
}
