import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double x2 = 2;
  static const double x3 = 3;
  static const double x4 = 4;
  static const double x6 = 6;
  static const double x8 = 8;
  static const double x10 = 10;
  static const double x12 = 12;
  static const double x14 = 14;
  static const double x16 = 16;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x28 = 28;
  static const double x32 = 32;
  static const double x40 = 40;
  static const double x48 = 48;
  static const double x64 = 64;

  // Named aliases for readability
  static const double xs = x4;
  static const double sm = x8;
  static const double md = x16;
  static const double lg = x24;
  static const double xl = x32;
  static const double xxl = x48;

  // Padding presets
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: x16);
  static const EdgeInsets screenAll = EdgeInsets.all(x16);
  static const EdgeInsets cardAll = EdgeInsets.all(x16);
  static const EdgeInsets cardH = EdgeInsets.symmetric(horizontal: x16);
  static const EdgeInsets sectionV = EdgeInsets.symmetric(vertical: x12);
  static const EdgeInsets chipH = EdgeInsets.symmetric(horizontal: x12, vertical: x4);
  static const EdgeInsets listTile = EdgeInsets.symmetric(horizontal: x16, vertical: x12);
  static const EdgeInsets pageInsets = EdgeInsets.fromLTRB(x16, x20, x16, x32);

  // SizedBox helpers
  static const Widget h2 = SizedBox(height: x2);
  static const Widget h4 = SizedBox(height: x4);
  static const Widget h6 = SizedBox(height: x6);
  static const Widget h8 = SizedBox(height: x8);
  static const Widget h10 = SizedBox(height: x10);
  static const Widget h12 = SizedBox(height: x12);
  static const Widget h16 = SizedBox(height: x16);
  static const Widget h20 = SizedBox(height: x20);
  static const Widget h24 = SizedBox(height: x24);
  static const Widget h28 = SizedBox(height: x28);
  static const Widget h32 = SizedBox(height: x32);
  static const Widget h40 = SizedBox(height: x40);
  static const Widget h48 = SizedBox(height: x48);

  static const Widget w4 = SizedBox(width: x4);
  static const Widget w6 = SizedBox(width: x6);
  static const Widget w8 = SizedBox(width: x8);
  static const Widget w10 = SizedBox(width: x10);
  static const Widget w12 = SizedBox(width: x12);
  static const Widget w14 = SizedBox(width: x14);
  static const Widget w16 = SizedBox(width: x16);
  static const Widget w20 = SizedBox(width: x20);
}
