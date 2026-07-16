import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/highlighted_text.dart';
import '../../../widgets/typeahead_field.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _faqs = [
    _Faq(
      'How does the AI budget allocation work?',
      'Wedpilot\'s AI analyzes industry averages, your guest count, location, and priorities to recommend how to distribute your budget across 12 wedding categories. You can adjust any category and the AI explains its reasoning.',
    ),
    _Faq(
      'How are vendors verified?',
      'Each vendor submits business credentials, portfolio samples, and proof of insurance. Our admin team reviews these within 48 hours. Verified vendors display a blue verified badge.',
    ),
    _Faq(
      'Can my partner access the account?',
      'Yes! Go to Settings → Partner Access and invite your partner via email. They\'ll get full access to plan together in real time.',
    ),
    _Faq(
      'How do I send a wedding invitation?',
      'Go to Invitations from the dashboard, choose a template, customize with your details, and share via link, WhatsApp, email, or QR code. Guests can RSVP directly from the link.',
    ),
    _Faq(
      'Is my payment information secure?',
      'Absolutely. All payments are processed through Stripe with PCI DSS Level 1 compliance. We never store any card details.',
    ),
    _Faq(
      'Can I export my budget?',
      'Yes! On the Budget Overview screen, tap the export icon to download your budget as a PDF or CSV file.',
    ),
    _Faq(
      'How do I track RSVPs?',
      'Once your invitation is published, go to Invitations → RSVP Dashboard to see real-time responses, guest counts, meal preferences, and send reminders.',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase();
    final filtered = query.isEmpty
        ? _faqs
        : _faqs
              .where(
                (f) =>
                    f.question.toLowerCase().contains(query) ||
                    f.answer.toLowerCase().contains(query),
              )
              .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TypeaheadField<_Faq>(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              hint: 'Search help topics...',
              fillColor: AppColors.surface,
              onChanged: (_) => setState(() {}),
              suggestionsCallback: (q) => _faqs
                  .where((f) =>
                      f.question.toLowerCase().contains(q.toLowerCase()) ||
                      f.answer.toLowerCase().contains(q.toLowerCase()))
                  .take(8)
                  .toList(),
              displayStringForOption: (f) => f.question,
              onSelected: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (query.isEmpty) ...[
                  // Contact card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.secondary.withAlpha(51),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Still need help?',
                                style: AppTextStyles.titleMedium,
                              ),
                              Text(
                                'Chat with our support team (Mon–Fri, 9am–6pm)',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Chat',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Frequently Asked Questions',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                ],
                ...filtered.map((faq) => _FaqTile(faq: faq, query: query)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;
  final String query;
  const _FaqTile({required this.faq, this.query = ''});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: HighlightedText(
          text: widget.faq.question,
          query: widget.query,
          style: AppTextStyles.titleMedium,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.faq.answer,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
        onExpansionChanged: (_) {},
      ),
    );
  }
}
