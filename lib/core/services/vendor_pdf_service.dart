import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/budget.dart';
import '../../models/couple_profile.dart';
import '../../models/vendor_profile.dart';

class VendorPdfService {
  VendorPdfService._();

  static const _green = PdfColor.fromInt(0xFF1B4332);
  static const _amber = PdfColor.fromInt(0xFFD4A24C);
  static const _grey = PdfColor.fromInt(0xFF6B7280);

  static Future<Uint8List> buildWeddingPlanPdf({
    CoupleProfile? couple,
    Budget? budget,
    required List<VendorProfile> vendors,
    Map<String, String> reasoningByVendorId = const {},
  }) async {
    final doc = pw.Document();
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
          if (budget != null) ...[
            _buildBudgetBreakdown(budget),
            pw.SizedBox(height: 24),
          ],
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

  static pw.Widget _buildBudgetBreakdown(Budget budget) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Budget Breakdown',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold, color: _green)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Total budget: ${budget.currency} ${budget.totalAmount.toStringAsFixed(0)}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(children: [
                _tableCell('Category', bold: true),
                _tableCell('Allocated', bold: true),
                _tableCell('% of budget', bold: true),
              ]),
              for (final c in budget.categories.where((c) => c.allocatedAmount > 0))
                pw.TableRow(children: [
                  _tableCell('${c.categoryIcon}  ${c.categoryName}'),
                  _tableCell(
                      '${budget.currency} ${c.allocatedAmount.toStringAsFixed(0)}'),
                  _tableCell(budget.totalAmount > 0
                      ? '${(c.allocatedAmount / budget.totalAmount * 100).toStringAsFixed(0)}%'
                      : '—'),
                ]),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

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
            'Prepared by WedPilot — AI-matched $vendorCount vendor${vendorCount == 1 ? '' : 's'} across $categoryCount '
            'categor${categoryCount == 1 ? 'y' : 'ies'}, with full budget breakdown',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
          ),
          if (couple != null) ...[
            pw.SizedBox(height: 14),
            pw.Wrap(spacing: 18, runSpacing: 6, children: [
              if (couple.weddingDate != null)
                _coverFact('Wedding date',
                    _formatDate(couple.weddingDate!)),
              if (couple.location != null && couple.location!.isNotEmpty)
                _coverFact('Location', couple.location!),
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
        category,
        style: pw.TextStyle(
            fontSize: 14, fontWeight: pw.FontWeight.bold, color: _green),
      ),
    );
  }

  static pw.Widget _buildVendorBlock(VendorProfile v, String? reasoning) {
    final mapsUrl = (v.latitude != null && v.longitude != null)
        ? 'https://www.google.com/maps?q=${v.latitude},${v.longitude}'
        : null;

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
              pw.Text(v.businessName,
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
            pw.Text('Location: ${v.location}',
                style: const pw.TextStyle(fontSize: 10)),
          if (mapsUrl != null)
            pw.UrlLink(
              destination: mapsUrl,
              child: pw.Text('View exact location on map',
                  style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.blue,
                      decoration: pw.TextDecoration.underline)),
            ),
          if (v.phone != null && v.phone!.isNotEmpty)
            pw.Text('Phone: ${v.phone}', style: const pw.TextStyle(fontSize: 10)),
          if (v.website != null && v.website!.isNotEmpty)
            pw.Text('Website: ${v.website}', style: const pw.TextStyle(fontSize: 10)),
          if (v.priceMax > 0)
            pw.Text(
              'Price range: ${v.priceMin.toStringAsFixed(0)} - ${v.priceMax.toStringAsFixed(0)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          if (v.description != null && v.description!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(v.description!,
                  style: const pw.TextStyle(fontSize: 9, color: _grey)),
            ),
          if (reasoning != null) ...[
            pw.SizedBox(height: 6),
            pw.Text('Why WedPilot picked this vendor:',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _green)),
            pw.Text(reasoning, style: const pw.TextStyle(fontSize: 9)),
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
