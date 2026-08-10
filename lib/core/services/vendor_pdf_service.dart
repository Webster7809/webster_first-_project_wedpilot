import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/couple_profile.dart';
import '../../models/vendor_profile.dart';

class VendorPdfService {
  VendorPdfService._();

  static const _green = PdfColor.fromInt(0xFF1B4332);
  static const _amber = PdfColor.fromInt(0xFFD4A24C);
  static const _grey = PdfColor.fromInt(0xFF6B7280);

  // The pdf package's built-in Helvetica only covers Latin-1, so glyphs like
  // '★', '·', em-dashes, or emoji trigger "Unable to find a font to draw"
  // warnings and render as empty boxes. Every string that can carry
  // model-authored or user-authored text goes through here: known symbols are
  // rewritten to WinAnsi-safe equivalents, anything else outside Latin-1 is
  // dropped.
  static String _pdfSafe(String text) => text
      .replaceAll('★', ' stars')
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('·', '-')
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('…', '...')
      .replaceAll(RegExp(r'[^\x00-\xFF]'), '')
      .trim();

  // The pdf package's built-in Helvetica is a Type1 font with no Unicode
  // support (it prints "Helvetica has no Unicode support" for anything beyond
  // WinAnsi). Embedding a real TTF is the proper fix — Open Sans is fetched
  // once by the printing package and cached. If it can't be fetched (offline),
  // we fall back to Helvetica, where the _pdfSafe sanitizing below keeps
  // every string within what Helvetica can draw.
  static Future<pw.ThemeData?> _unicodeTheme() async {
    try {
      return pw.ThemeData.withFont(
        base: await PdfGoogleFonts.openSansRegular(),
        bold: await PdfGoogleFonts.openSansBold(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> buildWeddingPlanPdf({
    CoupleProfile? couple,
    required List<VendorProfile> vendors,
    Map<String, String> reasoningByVendorId = const {},
  }) async {
    final doc = pw.Document(theme: await _unicodeTheme());
    final byCategory = <String, List<VendorProfile>>{};
    for (final v in vendors) {
      byCategory.putIfAbsent(v.category, () => []).add(v);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => context.pageNumber == 1
            ? pw.Container()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text('WedPilot Wedding Plan',
                    style: pw.TextStyle(color: _grey, fontSize: 10)),
              ),
        build: (context) => [
          _buildCover(couple, vendors.length, byCategory.keys.length),
          pw.SizedBox(height: 20),
          for (final entry in byCategory.entries) ...[
            _buildCategoryHeader(entry.key),
            pw.SizedBox(height: 8),
            for (final v in entry.value) ...[
              _buildVendorBlock(v, reasoningByVendorId[v.id]),
              pw.SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildCover(
      CoupleProfile? couple, int vendorCount, int categoryCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _green,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Your Wedding Plan',
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(
            'Prepared by WedPilot - AI-matched $vendorCount vendor${vendorCount == 1 ? '' : 's'} across $categoryCount '
            'categor${categoryCount == 1 ? 'y' : 'ies'}',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
          ),
          if (couple != null) ...[
            pw.SizedBox(height: 14),
            pw.Wrap(spacing: 18, runSpacing: 6, children: [
              if (couple.weddingDate != null)
                _coverFact('Wedding date',
                    _formatDate(couple.weddingDate!)),
              if (couple.location != null && couple.location!.isNotEmpty)
                _coverFact('Location', _pdfSafe(couple.location!)),
              if (couple.guestCount != null)
                _coverFact('Guests', '${couple.guestCount}'),
              if (couple.totalBudget != null)
                _coverFact('Budget',
                    '${couple.currency} ${couple.totalBudget!.toStringAsFixed(0)}'),
            ]),
          ],
        ],
      ),
    );
  }

  static pw.Widget _coverFact(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(),
            style: pw.TextStyle(
                color: PdfColors.white, fontSize: 8, letterSpacing: 1)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildCategoryHeader(String category) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _amber, width: 1.5)),
      ),
      child: pw.Text(
        _pdfSafe(category),
        style: pw.TextStyle(
            fontSize: 14, fontWeight: pw.FontWeight.bold, color: _green),
      ),
    );
  }

  static pw.Widget _buildVendorBlock(VendorProfile v, String? reasoning) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(_pdfSafe(v.businessName),
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
              if (v.isCustomEntry)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: _amber,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text('ADDED BY YOU',
                      style: const pw.TextStyle(
                          fontSize: 7, color: PdfColors.white)),
                )
              else if (v.rating != null)
                pw.Text('${v.rating!.toStringAsFixed(1)} stars (${v.feedbackCount} ratings)',
                    style: const pw.TextStyle(fontSize: 9, color: _grey)),
            ],
          ),
          pw.SizedBox(height: 4),
          if (v.location != null && v.location!.isNotEmpty)
            pw.Text('Location: ${_pdfSafe(v.location!)}',
                style: const pw.TextStyle(fontSize: 10)),
          if (v.phone != null && v.phone!.isNotEmpty)
            pw.Text('Phone: ${_pdfSafe(v.phone!)}',
                style: const pw.TextStyle(fontSize: 10)),
          if (v.website != null && v.website!.isNotEmpty)
            pw.Text('Website: ${_pdfSafe(v.website!)}',
                style: const pw.TextStyle(fontSize: 10)),
          if (v.priceMax > 0)
            pw.Text(
              'Price range: ${v.priceMin.toStringAsFixed(0)} - ${v.priceMax.toStringAsFixed(0)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          if (v.description != null && v.description!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(_pdfSafe(v.description!),
                  style: const pw.TextStyle(fontSize: 9, color: _grey)),
            ),
          if (reasoning != null) ...[
            pw.SizedBox(height: 6),
            pw.Text('Why WedPilot picked this vendor:',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _green)),
            pw.Text(_pdfSafe(reasoning), style: const pw.TextStyle(fontSize: 9)),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
