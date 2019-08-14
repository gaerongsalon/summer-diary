import 'package:flutter/material.dart';

class ColorMap {
  static const int primaryColor = 0xFF407088;
  static const Color key1 = const Color(0xFF132743);
  static const Color key2 = const Color(primaryColor);
  static const Color key3 = const Color(0xFFFFB5B5);
  static const Color key4 = const Color(0xFFFFCBCB);

  static const MaterialColor dawn = MaterialColor(
    primaryColor,
    <int, Color>{
      50: key1,
      100: Color(0xFF223F5A),
      200: Color(0xFF315871),
      300: key2,
      400: Color(0xFF808797),
      500: Color(0xFFBF9EA6),
      600: key3,
      700: Color(0xFFFFBCBC),
      800: Color(0xFFFFC4C4),
      900: key4,
    },
  );
}
