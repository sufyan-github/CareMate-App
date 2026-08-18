import 'package:flutter/widgets.dart';

abstract final class CareMateSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class CareMateRadii {
  static const small = 12.0;
  static const medium = 16.0;
  static const large = 20.0;
  static const pill = 999.0;
}

abstract final class CareMateLayout {
  static const minTouchTarget = 48.0;
  static const maxContentWidth = 560.0;
  static const pagePadding = EdgeInsets.fromLTRB(
    CareMateSpacing.lg,
    CareMateSpacing.lg,
    CareMateSpacing.lg,
    CareMateSpacing.xxl,
  );
}
