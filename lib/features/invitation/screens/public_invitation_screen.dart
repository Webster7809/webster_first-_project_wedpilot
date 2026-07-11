import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/invitation_fonts.dart';
import '../../../core/services/invitation_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/invitation.dart';
import '../../../widgets/wed_snack_bar.dart';

class PublicInvitationScreen extends StatefulWidget {
  final String? shareToken;
  final String? inviteToken;
  const PublicInvitationScreen({super.key, this.shareToken, this.inviteToken})
      : assert(shareToken != null || inviteToken != null);

  @override
  State<PublicInvitationScreen> createState() => _PublicInvitationScreenState();
}

class _PublicInvitationScreenState extends State<PublicInvitationScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;
  bool _alreadyResponded = false;
  String? _guestName;
  String? _error;
  Invitation? _invitation;
  AttendingStatus _attending = AttendingStatus.yes;

  bool get _isGuestLink => widget.inviteToken != null;

  // Local-only draft storage (device-scoped), keyed by the link's token so an
  // unfinished RSVP survives closing the tab/app before it's submitted.
  String get _draftKey => 'rsvp_draft_${widget.inviteToken ?? widget.shareToken}';
  Box get _draftBox => Hive.box('invitation_drafts');

  @override
  void initState() {
    super.initState();
    _loadInvitation();
  }

  Future<void> _loadInvitation() async {
    try {
      if (_isGuestLink) {
        final result = await InvitationApiService.instance.fetchGuestInvitation(widget.inviteToken!);
        if (!mounted) return;
        setState(() {
          _invitation = result?.invitation;
          _guestName = result?.guestName;
          _alreadyResponded = result?.alreadyResponded ?? false;
          if (_guestName != null) _nameCtrl.text = _guestName!;
          if (_alreadyResponded && result?.respondedAttending != null) {
            _attending = result!.respondedAttending!;
          }
          _loading = false;
        });
      } else {
        final invitation = await InvitationApiService.instance.fetchPublicInvitation(widget.shareToken!);
        if (!mounted) return;
        setState(() {
          _invitation = invitation;
          _loading = false;
        });
      }
      if (!_alreadyResponded) _loadDraft();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadDraft() {
    final draft = _draftBox.get(_draftKey) as Map?;
    if (draft == null) return;
    setState(() {
      if (!_isGuestLink) {
        final name = draft['name'] as String?;
        if (name != null && name.isNotEmpty) _nameCtrl.text = name;
      }
      final email = draft['email'] as String?;
      if (email != null) _emailCtrl.text = email;
      final attending = draft['attending'] as String?;
      _attending = AttendingStatus.values.firstWhere(
        (s) => s.name == attending,
        orElse: () => _attending,
      );
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _error = null; });
    try {
      if (_isGuestLink) {
        await InvitationApiService.instance.submitGuestInviteRsvp(
          widget.inviteToken!,
          attending: _attending,
          guestCount: 1,
        );
      } else {
        await InvitationApiService.instance.submitPublicRsvp(
          widget.shareToken!,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          attending: _attending,
          guestCount: 1,
        );
      }
      await _draftBox.delete(_draftKey);
      if (mounted) setState(() { _submitting = false; _submitted = true; });
    } on InvitationApiException catch (e) {
      if (!mounted) return;
      if (e.message == 'You have already responded to this invitation.') {
        // Rare double-submit race (e.g. double-tap): treat identically to
        // having loaded in an already-responded state.
        setState(() { _submitting = false; _alreadyResponded = true; });
      } else {
        setState(() { _submitting = false; _error = e.message; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
      );
    }
    if (_invitation == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mail_outline_rounded, size: 56, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('Invitation not found',
                    style: AppTextStyles.headlineMedium.copyWith(color: AppColors.forestGreen)),
                const SizedBox(height: 8),
                Text(
                  'This invitation link may have expired or is no longer available.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _invitation!.customData;
    final showSuccess = _submitted || _alreadyResponded;
    final accentColor = _accentColorFrom(data);

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
                    _buildHeader(context, data, accentColor),
                    if (showSuccess)
                      _buildSuccess(data, justSubmitted: _submitted)
                    else
                      _buildBody(data, accentColor),
                  ],
                ),
              ),
            ),
            if (!showSuccess) _buildBottomBar(context, accentColor),
          ],
        ),
      ),
    );
  }

  // Reflects the couple's actual accent color choice from the editor, so the
  // guest-facing page matches the card they designed instead of always
  // showing a fixed generic color.
  Color _accentColorFrom(Map<String, dynamic> data) {
    final value = data['accentColor'] as int?;
    return value != null ? Color(value) : AppColors.amber;
  }

  // Splits "Chanda & Mwila" into two gold names joined by a white "&", to
  // match the couple's card design. Falls back to a single-color name when
  // the text doesn't contain a clean "&" separator.
  Widget _buildCoupleName(String coupleName, TextStyle nameStyle) {
    final parts = coupleName.split('&');
    if (parts.length != 2 || parts.any((p) => p.trim().isEmpty)) {
      return Text(coupleName, style: nameStyle, textAlign: TextAlign.center);
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: parts[0].trim(), style: nameStyle),
          TextSpan(text: ' & ', style: nameStyle.copyWith(color: Colors.white)),
          TextSpan(text: parts[1].trim(), style: nameStyle),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  // ── Dark green full-bleed header ──────────────────────────────────────────

  Widget _buildHeader(BuildContext context, Map<String, dynamic> data, Color accentColor) {
    final coupleName = (data['coupleName'] as String?) ?? 'the happy couple';
    final date = data['date'] as String?;
    final time = data['time'] as String?;
    final backgroundImageUrl = data['backgroundImageUrl'] as String?;
    final hasPhoto = backgroundImageUrl != null && backgroundImageUrl.isNotEmpty;

    // Reflects the couple's actual font choice from the editor. Over a photo,
    // force white text (matching the editor's own photo-mode preview) since
    // the accent color alone isn't guaranteed to stay legible against an
    // arbitrary background image.
    final fontIndex = data['fontIndex'] as int?;
    final nameFont = (fontIndex != null && fontIndex >= 0 && fontIndex < invitationFontOptions.length)
        ? invitationFontOptions[fontIndex]
        : null;
    final nameColor = hasPhoto ? Colors.white : accentColor;
    final nameStyle = nameFont?.style(32, nameColor) ??
        GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: nameColor);

    final content = Padding(
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
          _buildCoupleName(coupleName, nameStyle),
          if (date != null && date.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              date,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (time != null && time.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withAlpha(204),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (!hasPhoto) {
      return Container(width: double.infinity, color: AppColors.forestGreen, child: content);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            resolveInvitationMediaUrl(backgroundImageUrl),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppColors.forestGreen),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withAlpha(115), Colors.black.withAlpha(140)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }

  // ── Info cards + RSVP form ────────────────────────────────────────────────

  Widget _buildBody(Map<String, dynamic> data, Color accentColor) {
    final venue = data['venue'] as String?;
    final dressCode = data['dressCode'] as String?;
    final parking = data['parking'] as String?;
    final receptionVenue = data['receptionVenue'] as String?;
    final rsvpBy = data['rsvpBy'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (venue != null && venue.isNotEmpty) ...[
            _InfoCard(icon: Icons.location_on_outlined, label: 'Venue', value: venue),
            const SizedBox(height: 12),
          ],
          if (dressCode != null && dressCode.isNotEmpty) ...[
            _InfoCard(icon: Icons.checkroom_outlined, label: 'Dress code', value: dressCode),
            const SizedBox(height: 12),
          ],
          if (parking != null && parking.isNotEmpty) ...[
            _InfoCard(icon: Icons.directions_car_outlined, label: 'Parking', value: parking),
            const SizedBox(height: 12),
          ],
          if (receptionVenue != null && receptionVenue.isNotEmpty) ...[
            _InfoCard(icon: Icons.celebration_outlined, label: 'Reception', value: receptionVenue),
            const SizedBox(height: 16),
          ],
          _RsvpFormCard(
            formKey: _formKey,
            nameCtrl: _nameCtrl,
            emailCtrl: _emailCtrl,
            rsvpBy: rsvpBy,
            attending: _attending,
            onAttendingChanged: (v) => setState(() => _attending = v),
            error: _error,
            showEmailField: !_isGuestLink,
            readOnlyName: _isGuestLink,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  // ── Success state ─────────────────────────────────────────────────────────

  Widget _buildSuccess(Map<String, dynamic> data, {required bool justSubmitted}) {
    final coupleName = (data['coupleName'] as String?) ?? 'We';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        children: [
          const Text('🎊', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 20),
          Text(
            justSubmitted ? 'Thank You!' : 'You\'ve already responded',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.forestGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your RSVP has been received.\n$coupleName look forward to celebrating with you!',
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

  Future<void> _saveDraft(BuildContext context) async {
    await _draftBox.put(_draftKey, {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'attending': _attending.name,
    });
    if (context.mounted) {
      showWedSnackBar(context, 'Draft saved', type: SnackType.success);
    }
  }

  Widget _buildBottomBar(BuildContext context, Color accentColor) {
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
          Expanded(
            child: OutlinedButton(
              onPressed: _submitting ? null : () => _saveDraft(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Save draft',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accentColor.withAlpha(153),
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
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
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
  final String? rsvpBy;
  final AttendingStatus attending;
  final ValueChanged<AttendingStatus> onAttendingChanged;
  final String? error;
  final bool showEmailField;
  final bool readOnlyName;
  final Color accentColor;

  const _RsvpFormCard({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.rsvpBy,
    required this.attending,
    required this.onAttendingChanged,
    required this.error,
    this.showEmailField = true,
    this.readOnlyName = false,
    this.accentColor = AppColors.forestGreen,
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
              (rsvpBy != null && rsvpBy!.isNotEmpty) ? 'RSVP by $rsvpBy' : 'RSVP',
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
              enabled: !readOnlyName,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDec('Full name'),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
            ),
            if (showEmailField) ...[
              const SizedBox(height: 14),
              _FormLabel('Your email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDec('Email address (optional)'),
              ),
            ],
            const SizedBox(height: 14),
            _FormLabel('Will you attend?'),
            const SizedBox(height: 8),
            _AttendRow(value: attending, onChanged: onAttendingChanged, accentColor: accentColor),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            ],
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

class _AttendRow extends StatelessWidget {
  final AttendingStatus value;
  final ValueChanged<AttendingStatus> onChanged;
  final Color accentColor;
  const _AttendRow({required this.value, required this.onChanged, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: 'Going ✅', status: AttendingStatus.yes, selected: value, onTap: onChanged, accentColor: accentColor),
        const SizedBox(width: 8),
        _Chip(label: 'Maybe 🤔', status: AttendingStatus.maybe, selected: value, onTap: onChanged, accentColor: accentColor),
        const SizedBox(width: 8),
        _Chip(label: 'No ❌', status: AttendingStatus.no, selected: value, onTap: onChanged, accentColor: accentColor),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final AttendingStatus status;
  final AttendingStatus selected;
  final ValueChanged<AttendingStatus> onTap;
  final Color accentColor;

  const _Chip({
    required this.label,
    required this.status,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = status == selected;
    return Expanded(
      child: Material(
        animationDuration: const Duration(milliseconds: 180),
        color: isSelected ? accentColor.withAlpha(23) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? accentColor : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTap(status),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
