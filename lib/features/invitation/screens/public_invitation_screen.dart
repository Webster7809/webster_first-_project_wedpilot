import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PublicInvitationScreen extends StatefulWidget {
  final String shareToken;
  const PublicInvitationScreen({super.key, required this.shareToken});

  @override
  State<PublicInvitationScreen> createState() => _PublicInvitationScreenState();
}

class _PublicInvitationScreenState extends State<PublicInvitationScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() { _submitting = false; _submitted = true; });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    if (_submitted)
                      _buildSuccess()
                    else
                      _buildBody(),
                  ],
                ),
              ),
            ),
            if (!_submitted) _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // ── Dark green full-bleed header ──────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.forestGreen,
      padding: EdgeInsets.fromLTRB(
        24, MediaQuery.of(context).padding.top + 28, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "You're invited to the\nwedding of",
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Chanda',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber,
                  ),
                ),
                TextSpan(
                  text: ' & ',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: 'Mwila',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            'Saturday, 12 September 2026',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '6:00 PM',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withAlpha(204),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Info cards + RSVP form ────────────────────────────────────────────────

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoCard(
            icon: Icons.location_on_outlined,
            label: 'Venue',
            value: 'Mukuba Gardens, Ndola',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.checkroom_outlined,
            label: 'Dress code',
            value: 'Formal or traditional attire',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.local_shipping_outlined,
            label: 'Parking',
            value: 'Available (80 spaces reserved)',
          ),
          const SizedBox(height: 16),
          _RsvpFormCard(
            formKey: _formKey,
            nameCtrl: _nameCtrl,
            emailCtrl: _emailCtrl,
          ),
        ],
      ),
    );
  }

  // ── Success state ─────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        children: [
          const Text('🎊', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 20),
          Text(
            'Thank You!',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.forestGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your RSVP has been received.\nChanda & Mwila look forward to celebrating with you!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Sticky bottom bar ─────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Save draft
          Expanded(
            child: OutlinedButton(
              onPressed: _submitting ? null : () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Save draft',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Submit RSVP
          Expanded(
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.amber.withAlpha(153),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Submit RSVP',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.amber.withAlpha(31),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.amber),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── RSVP form card ────────────────────────────────────────────────────────────

class _RsvpFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;

  const _RsvpFormCard({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'RSVP by 1 August 2026',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            _FormLabel('Your name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDec('Full name'),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            _FormLabel('Your email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDec('Email address (optional)'),
            ),
            const SizedBox(height: 14),
            _FormLabel('Will you attend?'),
            const SizedBox(height: 8),
            _AttendRow(),
          ],
        ),
      ),
    );
  }

  static InputDecoration _fieldDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textHint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.forestGreen, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _AttendRow extends StatefulWidget {
  const _AttendRow();

  @override
  State<_AttendRow> createState() => _AttendRowState();
}

class _AttendRowState extends State<_AttendRow> {
  String _value = 'yes';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: 'Going ✅', value: 'yes', selected: _value,
            onTap: (v) => setState(() => _value = v)),
        const SizedBox(width: 8),
        _Chip(label: 'Maybe 🤔', value: 'maybe', selected: _value,
            onTap: (v) => setState(() => _value = v)),
        const SizedBox(width: 8),
        _Chip(label: 'No ❌', value: 'no', selected: _value,
            onTap: (v) => setState(() => _value = v)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _Chip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.forestGreen.withAlpha(23)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.forestGreen : AppColors.divider,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.forestGreen : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
