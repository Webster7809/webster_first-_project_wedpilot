import 'dart:typed_data';

import 'pdf_download_stub.dart' if (dart.library.html) 'pdf_download_web.dart';

Future<void> downloadPdfFile(String filename, Uint8List bytes) =>
    downloadPdfFileImpl(filename, bytes);
