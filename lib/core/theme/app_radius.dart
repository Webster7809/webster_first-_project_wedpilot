import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double r4 = 4;
  static const double r6 = 6;
  static const double r8 = 8;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r32 = 32;
  static const double full = 999;

  // Named aliases
  static const double xs = r4;
  static const double sm = r8;
  static const double md = r12;
  static const double lg = r16;
  static const double xl = r20;
  static const double card = r16;
  static const double chip = r20;
  static const double button = r24;
  static const double input = r12;
  static const double avatar = full;
  static const double dialog = r24;
  static const double bottomSheet = r24;

  // BorderRadius helpers
  static const BorderRadius bxs = BorderRadius.all(Radius.circular(r4));
  static const BorderRadius bsm = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius bmd = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius blg = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius bxl = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius bbutton = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius bfull = BorderRadius.all(Radius.circular(full));

  static BorderRadius top(double r) =>
      BorderRadius.vertical(top: Radius.circular(r));
  static BorderRadius bottom(double r) =>
      BorderRadius.vertical(bottom: Radius.circular(r));
}
