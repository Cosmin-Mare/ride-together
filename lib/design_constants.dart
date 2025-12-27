class DesignConstants {
  static const double designWidth = 1200;
  static double calculateScale(double width) =>
    (width / designWidth).clamp(0.4, 1.0);
  static bool isMobile(double width) => width < 600;
  static bool isTablet(double width) => width >= 600 && width < 1200;
  static bool isDesktop(double width) => width >= 1200;
}