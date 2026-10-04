import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  colorScheme: ColorScheme.light(
    surface: const Color.fromARGB(
      255,
      239,
      233,
      233,
    ), // warm light yellow-gray (main surface)
    primary: const Color.fromARGB(255, 158, 142, 142), // light pink
    secondary: const Color.fromARGB(255, 167, 157, 157), // light blue
    tertiary: const Color.fromARGB(255, 242, 242, 237), // light yellow
    inversePrimary: const Color(
      0xFF5C3A4D,
    ), // deep muted pink/plum for contrast text/icons
  ),
  scaffoldBackgroundColor: const Color.fromARGB(
    255,
    229,
    223,
    222,
  ), // matches surface
);
