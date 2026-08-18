import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A gold fill can never carry a white label — white on gold is 2.42:1, well
/// under the 4.5:1 needed for text, and the result reads as a *disabled*
/// button rather than a low-contrast one. That is exactly what happened to the
/// "Create Invitation" button: it looked unclickable, and was reported as a
/// broken button rather than a colour bug.
///
/// `design_system_test.dart` already pins the underlying measurement
/// (`white/gold < 3.0`), and `AppTheme` sets the right foreground — but a
/// screen can still override it locally, which six call sites across five
/// files had quietly done. Contrast is invisible in a code review, so this
/// scans the source instead.
void main() {
  test('no gold or amber fill carries a white foreground', () {
    final offenders = <String>[];

    // backgroundColor: AppColors.gold|amber  ...  foregroundColor: Colors.white
    // within a short window, which is how ElevatedButton.styleFrom and
    // ButtonStyle blocks are written throughout this app.
    final pattern = RegExp(
      r'backgroundColor:\s*AppColors\.(gold|amber)\s*,'
      r'(?:[^;{}]{0,200}?)'
      r'foregroundColor:\s*Colors\.white',
      dotAll: true,
    );

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final match in pattern.allMatches(source)) {
        final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('${entity.path}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'White on a gold fill is 2.42:1 and reads as disabled. Use '
          'AppColors.textOnSecondary (ink on gold, 6.44:1) at:\n'
          '${offenders.join('\n')}',
    );
  });
}
