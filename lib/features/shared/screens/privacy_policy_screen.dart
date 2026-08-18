import 'package:flutter/material.dart';
import '../../../widgets/legal_document_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScaffold(
      title: 'Privacy Policy',
      lastUpdated: 'August 2026',
      disclaimer:
          'This is a standard privacy policy draft written for Wedpilot\'s '
          'actual features and data collection. It is not legal advice — have '
          'it reviewed by a lawyer before relying on it for compliance in your '
          'region.',
      sections: [
        LegalSection(
          'Who we are',
          'Wedpilot is a wedding-planning app connecting couples with vendors, '
              'with tools for budgeting, AI-assisted vendor matching, guest '
              'management, and invitations. This policy explains what '
              'information we collect through the app and how it\'s used.',
        ),
        LegalSection(
          'Information we collect',
          'Account information: your name, email address, phone number, and '
              'profile photo. Wedding planning details: wedding date, '
              'location, guest count, budget figures and category '
              'allocations, and style preferences. Vendor business '
              'information (vendor accounts only): business name, category, '
              'description, contact details, location, and uploaded photos '
              'or packages. Guest and RSVP information: names, phone '
              'numbers, emails, relationships, dietary notes, and RSVP '
              'responses that a couple enters for their own guest list. '
              'Messages exchanged between couples and vendors within the '
              'app. Uploaded files: profile photos, vendor media, invitation '
              'backgrounds, and expense receipts.',
        ),
        LegalSection(
          'How we use this information',
          'To provide core features — budgeting tools, AI vendor-match '
              'recommendations, messaging, invitations and RSVP tracking. To '
              'send account and, where you\'ve opted in, notification emails '
              '(bookings, messages, budget alerts). To respond to support '
              'requests, maintain and secure the service, and prevent fraud '
              'or abuse.',
        ),
        LegalSection(
          'Who we share it with',
          'We don\'t sell your information or share it with advertisers. '
              'Limited data passes through the services that make the app '
              'work: our hosting/database provider, a transactional email '
              'relay used to send account and notification emails, and — '
              'only if you choose to sign in that way — Google Sign-In, '
              'which verifies your identity per Google\'s own privacy policy. '
              'A vendor and a couple can see each other\'s relevant booking '
              'and message details only where they\'re already connected '
              'through an inquiry or conversation.',
        ),
        LegalSection(
          'Guest data',
          'If you\'re a couple adding guests to your invitation, you\'re '
              'responsible for having a basis to share their contact details '
              'with us. We use that information only to enable RSVP '
              'collection and invitation delivery for your wedding.',
        ),
        LegalSection(
          'Data retention and account deletion',
          'We keep your information while your account is active. If you '
              'delete your account (Settings → Delete Account), we '
              'immediately scrub your name, email, phone number and photo '
              'and permanently block login. Records tied to a completed '
              'booking or exchanged feedback are kept in de-identified form '
              'rather than removed outright — this preserves the other '
              'party\'s own booking history, which their account still '
              'legitimately needs.',
        ),
        LegalSection(
          'Your choices',
          'You can review and edit your profile information at any time, '
              'turn email notifications on or off in Settings, and delete '
              'your account from Settings whenever you choose.',
        ),
        LegalSection(
          'Security',
          'Passwords are stored as salted bcrypt hashes, never in plain '
              'text. Sign-in sessions are stored in your device\'s encrypted '
              'secure storage, and data in transit is protected with TLS.',
        ),
        LegalSection(
          'Changes to this policy',
          'If this policy changes in a way that affects how your '
              'information is used, we\'ll update the "Last updated" date '
              'above.',
        ),
        LegalSection(
          'Contact',
          'Questions about this policy can be sent to support@wedpilot.app.',
        ),
      ],
    );
  }
}
