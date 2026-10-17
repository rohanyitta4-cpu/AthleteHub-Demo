import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared style for every screen title in an app bar.
TextStyle appTitleStyle({Color? color}) =>
    GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: color);
