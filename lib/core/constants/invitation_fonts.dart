import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared with the guest-facing public invitation screen so the RSVP page
/// guests see actually reflects the font the couple picked in the editor,
/// rather than a fixed generic style.
class InvitationFontOption {
  final String label;
  final String category;
  final TextStyle Function(double size, Color color) style;
  const InvitationFontOption(this.label, this.category, this.style);
}

final invitationFontOptions = <InvitationFontOption>[
  InvitationFontOption('Great Vibes', 'Script',
      (s, c) => GoogleFonts.greatVibes(fontSize: s, color: c)),
  InvitationFontOption('Sacramento', 'Script',
      (s, c) => GoogleFonts.sacramento(fontSize: s, color: c)),
  InvitationFontOption('Dancing Script', 'Script',
      (s, c) => GoogleFonts.dancingScript(
          fontSize: s, color: c, fontWeight: FontWeight.w700)),
  InvitationFontOption('Pinyon Script', 'Script',
      (s, c) => GoogleFonts.pinyonScript(fontSize: s, color: c)),
  InvitationFontOption('Alex Brush', 'Script',
      (s, c) => GoogleFonts.alexBrush(fontSize: s, color: c)),
  InvitationFontOption('Allura', 'Script',
      (s, c) => GoogleFonts.allura(fontSize: s, color: c)),
  InvitationFontOption('Tangerine', 'Script',
      (s, c) => GoogleFonts.tangerine(
          fontSize: s, color: c, fontWeight: FontWeight.w700)),
  InvitationFontOption('Parisienne', 'Script',
      (s, c) => GoogleFonts.parisienne(fontSize: s, color: c)),
  InvitationFontOption('Playfair Display', 'Serif',
      (s, c) => GoogleFonts.playfairDisplay(
          fontSize: s, color: c, fontWeight: FontWeight.bold)),
  InvitationFontOption('Cormorant Garamond', 'Serif',
      (s, c) => GoogleFonts.cormorantGaramond(
          fontSize: s, color: c, fontWeight: FontWeight.w600)),
  InvitationFontOption('Cinzel', 'Serif',
      (s, c) =>
          GoogleFonts.cinzel(fontSize: s, color: c, fontWeight: FontWeight.w700)),
  InvitationFontOption('EB Garamond', 'Serif',
      (s, c) => GoogleFonts.ebGaramond(
          fontSize: s, color: c, fontWeight: FontWeight.w600)),
  InvitationFontOption('Lora', 'Serif',
      (s, c) =>
          GoogleFonts.lora(fontSize: s, color: c, fontWeight: FontWeight.w600)),
  InvitationFontOption('Bodoni Moda', 'Serif',
      (s, c) => GoogleFonts.bodoniModa(
          fontSize: s, color: c, fontWeight: FontWeight.w700)),
  InvitationFontOption('Montserrat', 'Modern',
      (s, c) => GoogleFonts.montserrat(
          fontSize: s, color: c, fontWeight: FontWeight.w600)),
  InvitationFontOption('Raleway', 'Modern',
      (s, c) => GoogleFonts.raleway(
          fontSize: s, color: c, fontWeight: FontWeight.w600)),
  InvitationFontOption('Josefin Sans', 'Modern',
      (s, c) => GoogleFonts.josefinSans(
          fontSize: s, color: c, fontWeight: FontWeight.w600)),
  InvitationFontOption('Lobster', 'Decorative',
      (s, c) => GoogleFonts.lobster(fontSize: s, color: c)),
  InvitationFontOption('Pacifico', 'Decorative',
      (s, c) => GoogleFonts.pacifico(fontSize: s, color: c)),
  InvitationFontOption('Libre Baskerville', 'Decorative',
      (s, c) => GoogleFonts.libreBaskerville(
          fontSize: s, color: c, fontWeight: FontWeight.bold)),
];
