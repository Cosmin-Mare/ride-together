class DesignConstants {
  static const double designWidth = 1200;
  static double calculateScale(double width) =>
    (width / designWidth).clamp(0.4, 1.0);
}