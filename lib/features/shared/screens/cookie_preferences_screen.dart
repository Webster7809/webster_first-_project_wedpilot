import 'package:flutter/material.dart';
import '../../../widgets/legal_document_scaffold.dart';

class CookiePreferencesScreen extends StatelessWidget {
  const CookiePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScaffold(
      title: 'Cookie Preferences',
      lastUpdated: 'August 2026',
      disclaimer:
          'Wedpilot doesn\'t use third-party advertising or analytics '
          'cookies, so there\'s no ad-tracking consent to switch on or off '
          'here. This page explains what "cookies" actually means for this '
          'app instead of showing toggles that wouldn\'t control anything '
          'real.',
      sections: [
        LegalSection(
          'What we store on your device',
          'Your sign-in session is kept in encrypted secure storage on '
              'Android, or your browser\'s local storage on the web version. '
              'App preferences — theme, text size, and your notification '
              'choices — are kept in a small local database so they persist '
              'between visits without needing a server round-trip.',
        ),
        LegalSection(
          'No ad tracking',
          'Wedpilot does not use third-party ad networks or cross-site '
              'tracking cookies. Nothing about your activity in the app is '
              'sold or shared with advertisers.',
        ),
        LegalSection(
          'Managing local storage',
          'Signing out clears your locally stored session. On the web '
              'version, clearing your browser\'s site data for Wedpilot has '
              'the same effect. App preferences reset if the app is '
              'reinstalled or its local storage is cleared.',
        ),
        LegalSection(
          'If this changes',
          'If Wedpilot ever adds third-party analytics or advertising '
              'cookies, this page will be updated to describe them and, '
              'where required, a real consent control will be added here.',
        ),
      ],
    );
  }
}
