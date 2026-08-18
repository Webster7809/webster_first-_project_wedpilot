import 'package:flutter/material.dart';
import '../../../widgets/legal_document_scaffold.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScaffold(
      title: 'Terms of Service',
      lastUpdated: 'August 2026',
      disclaimer:
          'This is a standard terms-of-service draft written for Wedpilot\'s '
          'actual features. It is not legal advice — have it reviewed by a '
          'lawyer before relying on it for compliance in your region.',
      sections: [
        LegalSection(
          'Acceptance of terms',
          'By creating a Wedpilot account, you agree to these terms. If you '
              'don\'t agree, please don\'t use the app.',
        ),
        LegalSection(
          'What Wedpilot is',
          'Wedpilot is a platform that helps couples plan a wedding and '
              'connects them with vendors — budgeting tools, AI-assisted '
              'vendor matching, messaging, and invitation/RSVP management. '
              'Wedpilot is not a party to any booking arrangement a couple '
              'makes with a vendor, and does not process payments between '
              'them — any payment terms are agreed directly between the '
              'couple and the vendor.',
        ),
        LegalSection(
          'Your account',
          'You\'re responsible for the accuracy of the information you '
              'provide and for keeping your password secure. Each account is '
              'for one person or one vendor business.',
        ),
        LegalSection(
          'Vendor listings and verification',
          'Vendors are responsible for the accuracy of their listed '
              'business information, pricing, and availability. A '
              '"verified" badge reflects that Wedpilot reviewed the '
              'credentials a vendor submitted — it is not a guarantee of '
              'quality, licensing, or the outcome of any booking.',
        ),
        LegalSection(
          'Acceptable use',
          'Don\'t post fraudulent or misleading listings, harass other '
              'users through messaging, scrape or misuse the service, or '
              'attempt to circumvent its security. We may suspend accounts '
              'that violate this.',
        ),
        LegalSection(
          'Your content',
          'You keep ownership of photos and content you upload (profile '
              'photos, vendor media, invitation images, receipts). By '
              'uploading them, you give Wedpilot the license needed to '
              'store and display that content back to you and, where '
              'relevant, to the other party in a booking or conversation, '
              'solely to operate the service.',
        ),
        LegalSection(
          'Ending your account',
          'You can delete your own account at any time from Settings. We '
              'may suspend or terminate an account that violates these '
              'terms.',
        ),
        LegalSection(
          'No warranty',
          'Wedpilot is provided "as is." We don\'t guarantee that any '
              'particular vendor will be available, accurately represented, '
              'or a good fit for your wedding — that judgment stays with '
              'you.',
        ),
        LegalSection(
          'Limitation of liability',
          'To the extent permitted by law, Wedpilot is not liable for '
              'indirect or consequential losses arising from your use of the '
              'app, including disputes between a couple and a vendor.',
        ),
        LegalSection(
          'Changes to these terms',
          'If these terms change, we\'ll update the "Last updated" date '
              'above.',
        ),
        LegalSection(
          'Contact',
          'Questions about these terms can be sent to support@wedpilot.app.',
        ),
      ],
    );
  }
}
