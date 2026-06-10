import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/invitation_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

class InvitationEditorScreen extends ConsumerStatefulWidget {
  final String? invitationId;
  const InvitationEditorScreen({super.key, this.invitationId});

  @override
  ConsumerState<InvitationEditorScreen> createState() => _InvitationEditorScreenState();
}

class _InvitationEditorScreenState extends ConsumerState<InvitationEditorScreen> {
  final _nameCtrl = TextEditingController(text: 'Alex & Jordan');
  final _dateCtrl = TextEditingController(text: 'June 14, 2027');
  final _timeCtrl = TextEditingController(text: '4:00 PM');
  final _venueCtrl = TextEditingController(text: 'The Garden Venue, Long Island, NY');
  final _rsvpCtrl = TextEditingController(text: 'May 1, 2027');
  final _msgCtrl = TextEditingController(text: 'Together with their families, we joyfully invite you to share in the celebration of our marriage.');
  Color _primaryColor = AppColors.secondary;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _venueCtrl.dispose();
    _rsvpCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Invitation'),
        actions: [
          TextButton(
            onPressed: () {
              if (widget.invitationId != null) {
                ref.read(invitationsProvider.notifier).publish(widget.invitationId!);
              }
              showWedSnackBar(context, 'Invitation published! ✨', type: SnackType.success);
              context.pop();
            },
            child: const Text('Publish', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Row(
        children: [
          // Editor panel
          SizedBox(
            width: MediaQuery.of(context).size.width < 700
                ? MediaQuery.of(context).size.width
                : 360,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live preview
                  _InvitationPreview(
                    names: _nameCtrl.text,
                    date: _dateCtrl.text,
                    time: _timeCtrl.text,
                    venue: _venueCtrl.text,
                    message: _msgCtrl.text,
                    color: _primaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text('Customize', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 12),
                  _EditorField(label: 'Couple Names', controller: _nameCtrl, onChanged: (_) => setState(() {})),
                  _EditorField(label: 'Wedding Date', controller: _dateCtrl, onChanged: (_) => setState(() {})),
                  _EditorField(label: 'Time', controller: _timeCtrl, onChanged: (_) => setState(() {})),
                  _EditorField(label: 'Venue', controller: _venueCtrl, onChanged: (_) => setState(() {})),
                  _EditorField(label: 'RSVP By', controller: _rsvpCtrl, onChanged: (_) => setState(() {})),
                  _EditorField(label: 'Personal Message', controller: _msgCtrl, maxLines: 3, onChanged: (_) => setState(() {})),
                  const SizedBox(height: 16),
                  Text('Accent Color', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppColors.secondary, AppColors.tertiary, AppColors.goldPremium,
                      const Color(0xFF1A1A4E), const Color(0xFF8B6914),
                    ].map((c) => GestureDetector(
                      onTap: () => setState(() => _primaryColor = c),
                      child: Container(
                        width: 32, height: 32,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor == c ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: _primaryColor == c
                              ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
                              : [],
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: WedButton(
                          label: 'Share Link',
                          variant: WedButtonVariant.secondary,
                          onPressed: () => showWedSnackBar(context, 'Link copied!', type: SnackType.success),
                          icon: Icons.link,
                          height: 44,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: WedButton(
                          label: 'Export PDF',
                          variant: WedButtonVariant.secondary,
                          onPressed: () => showWedSnackBar(context, 'PDF generated!', type: SnackType.success),
                          icon: Icons.picture_as_pdf_outlined,
                          height: 44,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const _EditorField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }
}

class _InvitationPreview extends StatelessWidget {
  final String names;
  final String date;
  final String time;
  final String venue;
  final String message;
  final Color color;

  const _InvitationPreview({
    required this.names,
    required this.date,
    required this.time,
    required this.venue,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12)],
      ),
      child: Column(
        children: [
          Text('💍', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text('Together with their families', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          Text(names, style: AppTextStyles.displayMedium.copyWith(color: color)),
          const SizedBox(height: 8),
          Container(width: 60, height: 1, color: color.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.bodySmall.copyWith(height: 1.6, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(date, style: AppTextStyles.headlineSmall.copyWith(color: color)),
          Text('at $time', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(venue, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
