import 'package:flutter/material.dart';

/// Corner radii. [circular] is large enough for pills and avatars.
abstract final class AppRadius {
  static const small = 4.0;
  static const medium = 8.0;
  static const large = 12.0;
  static const extraLarge = 16.0;
  static const circular = 999.0;

  static const smallBorder = BorderRadius.all(Radius.circular(small));
  static const mediumBorder = BorderRadius.all(Radius.circular(medium));
  static const largeBorder = BorderRadius.all(Radius.circular(large));
  static const extraLargeBorder = BorderRadius.all(Radius.circular(extraLarge));
  static const circularBorder = BorderRadius.all(Radius.circular(circular));
}
