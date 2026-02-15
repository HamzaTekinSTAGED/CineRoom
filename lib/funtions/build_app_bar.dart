import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

AppBar buildAppBar() {
  return AppBar(
    toolbarHeight: 80,  // Adjust height if needed
    backgroundColor: const Color.fromARGB(0, 117, 107, 107),  // Make AppBar background transparent
    elevation: 0,  // Remove shadow
    flexibleSpace: Container(
      color: const Color(0x26262B50),  // Fill entire AppBar with color
      alignment: Alignment.center,  // Center the text
      child: Text(
        'CineRoom',
        style: GoogleFonts.itim(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 3,
        ),
      ),
    ),
  );
}
