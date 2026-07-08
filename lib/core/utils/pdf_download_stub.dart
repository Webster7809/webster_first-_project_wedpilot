import 'dart:typed_data';

Future<void> downloadPdfFileImpl(String filename, Uint8List bytes) async {
  // Fallback for non-web platforms: no-op, use Printing.sharePdf instead.
}
