import 'package:flutter/material.dart';

class Responsive {
  static const double compactBreakpoint = 768.0;

  static bool isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < compactBreakpoint;
  }
}
