/// Spacing, radius and sizing tokens from the Stitch design system.
abstract final class AppDimensions {
  // Spacing scale
  static const double spaceXxs = 2;
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  /// Horizontal page margin used by every screen.
  static const double pageMargin = 16;
  static const double gutter = 16;

  // Corner radius
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // Component sizes
  static const double buttonHeight = 52;
  static const double inputHeight = 56;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double avatarSm = 32;
  static const double avatarMd = 44;
  static const double avatarLg = 72;
  static const double avatarXl = 96;
  static const double bottomNavHeight = 72;

  /// Content max width for larger phones / foldables.
  static const double maxContentWidth = 600;

  /// Width at or below which a phone is treated as "small".
  static const double smallPhoneWidth = 360;
}
