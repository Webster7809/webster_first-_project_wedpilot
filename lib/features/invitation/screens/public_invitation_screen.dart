import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/invitation_fonts.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/services/invitation_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/invitation.dart';
import '../../../widgets/loading_shimmer.dart';
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
  final _mealCtrl = TextEditingController();
  final _dietaryCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;
  bool _alreadyResponded = false;
  String? _guestName;
  String? _error;
  Invitation? _invitation;
  List<MealOption> _mealOptions = const [];
  List<RsvpQuestion> _rsvpQuestions = const [];
  // Keyed by RsvpQuestion.id. Values are String for
  // yes_no/single_choice/short_text/long_text/number, List<String> for
  // multi_choice — matches what _QuestionField reads/writes for its type.
  Map<String, dynamic> _answerValues = {};
  AttendingStatus _attending = AttendingStatus.yes;
  int _guestCount = 1;

  /// Upper bound on party size for this specific guest link — null means
  /// either uncapped or (for the broadcast link) simply unknown until a name
  /// is typed, in which case the server has the final say on submit.
  int? _maxPartySize;

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
          _maxPartySize = result?.maxPartySize;
          _mealOptions = result?.mealOptions ?? const [];
          _rsvpQuestions = result?.rsvpQuestions ?? const [];
          _alreadyResponded = result?.alreadyResponded ?? false;
          if (_guestName != null) _nameCtrl.text = _guestName!;
          if (_alreadyResponded) {
            if (result?.respondedAttending != null) _attending = result!.respondedAttending!;
            _guestCount = result?.respondedGuestCount ?? 1;
            _mealCtrl.text = result?.respondedMealPreference ?? '';
            _dietaryCtrl.text = result?.respondedDietaryNotes ?? '';
            _messageCtrl.text = result?.respondedMessage ?? '';
            _answerValues = {
              for (final a in result?.respondedAnswers ?? const <RsvpAnswer>[])
                a.questionId: a.answerJson.isNotEmpty ? a.answerJson : a.answerText,
            };
          } else {
            // The couple sets this per guest — never a choice the guest makes.
            _guestCount = _maxPartySize ?? 1;
          }
          _loading = false;
        });
      } else {
        final view = await InvitationApiService.instance.fetchPublicInvitation(widget.shareToken!);
        if (!mounted) return;
        setState(() {
          _invitation = view?.invitation;
          _mealOptions = view?.mealOptions ?? const [];
          _rsvpQuestions = view?.rsvpQuestions ?? const [];
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
      final meal = draft['meal'] as String?;
      if (meal != null) _mealCtrl.text = meal;
      final dietary = draft['dietary'] as String?;
      if (dietary != null) _dietaryCtrl.text = dietary;
      final message = draft['message'] as String?;
      if (message != null) _messageCtrl.text = message;
      final answers = draft['answers'];
      if (answers is Map) {
        _answerValues = answers.map((k, v) => MapEntry(k as String, v is List ? v.cast<String>() : v));
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mealCtrl.dispose();
    _dietaryCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  /// Mirrors the server's own required-question check (skipped when
  /// declining) so a guest sees the problem immediately rather than after a
  /// round trip. Returns the question text of the first unanswered required
  /// question, or null if everything required is filled in.
  String? _firstMissingRequiredQuestion() {
    if (_attending == AttendingStatus.no) return null;
    for (final q in _rsvpQuestions) {
      if (!q.isRequired) continue;
      final value = _answerValues[q.id];
      final hasValue = value is List ? value.isNotEmpty : (value is String && value.trim().isNotEmpty);
      if (!hasValue) return q.questionText;
    }
    return null;
  }

  List<RsvpAnswerInput> _buildAnswerInputs() {
    final inputs = <RsvpAnswerInput>[];
    for (final q in _rsvpQuestions) {
      final value = _answerValues[q.id];
      if (q.type == RsvpQuestionType.multiChoice) {
        if (value is List && value.isNotEmpty) {
          inputs.add(RsvpAnswerInput(questionId: q.id, answerJson: value.cast<String>()));
        }
      } else if (value is String && value.trim().isNotEmpty) {
        inputs.add(RsvpAnswerInput(questionId: q.id, answerText: value.trim()));
      }
    }
    return inputs;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final missing = _firstMissingRequiredQuestion();
    if (missing != null) {
      setState(() => _error = 'Please answer: $missing');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    final meal = _mealCtrl.text.trim().isEmpty ? null : _mealCtrl.text.trim();
    final dietary = _dietaryCtrl.text.trim().isEmpty ? null : _dietaryCtrl.text.trim();
    final message = _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim();
    final answers = _buildAnswerInputs();
    // Declining never sends a party size — the couple-set count is
    // meaningless once the answer is no (the server zeroes it either way).
    final count = _attending == AttendingStatus.no ? 1 : _guestCount;
    try {
      if (_isGuestLink) {
        await InvitationApiService.instance.submitGuestInviteRsvp(
          widget.inviteToken!,
          attending: _attending,
          guestCount: count,
          mealPreference: meal,
          dietaryNotes: dietary,
          message: message,
          answers: answers,
        );
      } else {
        await InvitationApiService.instance.submitPublicRsvp(
          widget.shareToken!,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          attending: _attending,
          mealPreference: meal,
          dietaryNotes: dietary,
          message: message,
          answers: answers,
        );
      }
      await _draftBox.delete(_draftKey);
      if (mounted) {
        setState(() { _submitting = false; _submitted = true; _alreadyResponded = true; });
      }
    } on InvitationApiException catch (e) {
      if (!mounted) return;
      setState(() { _submitting = false; _error = e.message; });
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
                const Icon(Icons.mail_outlined, size: 56, color: AppColors.textHint),
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
    final subtitle = data['subtitle'] as String?;
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
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(220),
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
          child: CachedNetworkImage(
            imageUrl: resolveInvitationMediaUrl(backgroundImageUrl),
            fit: BoxFit.cover,
            memCacheWidth: 800,
            placeholder: (context, url) => Container(
              color: AppColors.forestGreen,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(color: AppColors.forestGreen),
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
    final churchTheme = data['churchTheme'] as String?;
    final churchTime = data['churchTime'] as String?;
    final time = data['time'] as String?;
    final dressCode = data['dressCode'] as String?;
    final parking = data['parking'] as String?;
    final receptionVenue = data['receptionVenue'] as String?;
    final rsvpBy = data['rsvpBy'] as String?;
    final giftType = data['giftType'] as String?;
    final contact = data['contact'] as String?;
    final message = data['message'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (venue != null && venue.isNotEmpty) ...[
            _InfoCard(icon: Icons.location_on_outlined, label: 'Venue', value: venue),
            const SizedBox(height: 12),
          ],
          if (churchTheme != null && churchTheme.isNotEmpty) ...[
            _InfoCard(icon: Icons.record_voice_over_outlined, label: 'Service theme', value: churchTheme),
            const SizedBox(height: 12),
          ],
          if (churchTime != null && churchTime.isNotEmpty && churchTime != time) ...[
            _InfoCard(icon: Icons.access_time_outlined, label: 'Church service time', value: churchTime),
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
            const SizedBox(height: 12),
          ],
          if (giftType != null && giftType.isNotEmpty) ...[
            _InfoCard(icon: Icons.card_giftcard_outlined, label: 'Gifts', value: giftType),
            const SizedBox(height: 12),
          ],
          if (contact != null && contact.isNotEmpty) ...[
            _InfoCard(
              icon: Icons.phone_outlined,
              label: 'Contact',
              value: contact,
              onTap: () => launchUrl(Uri.parse('tel:$contact')),
            ),
            const SizedBox(height: 16),
          ],
          if (message != null && message.isNotEmpty) ...[
            _MessageCard(message: message, accentColor: accentColor),
            const SizedBox(height: 16),
          ],
          _RsvpFormCard(
            formKey: _formKey,
            nameCtrl: _nameCtrl,
            emailCtrl: _emailCtrl,
            mealCtrl: _mealCtrl,
            dietaryCtrl: _dietaryCtrl,
            messageCtrl: _messageCtrl,
            rsvpBy: rsvpBy,
            attending: _attending,
            onAttendingChanged: (v) => setState(() => _attending = v),
            guestCount: _isGuestLink ? _guestCount : null,
            mealOptions: _mealOptions,
            rsvpQuestions: _rsvpQuestions,
            answerValues: _answerValues,
            onAnswerChanged: (id, value) => setState(() => _answerValues[id] = value),
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
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: VendorCategoryImages.galleryFor('DJ & MC')[2],
              width: 104,
              height: 104,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (_, _) =>
                  const LoadingShimmer(width: 104, height: 104, borderRadius: 52),
              errorWidget: (_, _, _) =>
                  const Text('🎊', style: TextStyle(fontSize: 72)),
            ),
          ),
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
            // Both links are single-use now: a personal link locks to its one
            // guest, and the shared link locks per name on the couple's guest
            // list — see invitations.js's two public RSVP routes. Neither can
            // be reopened to change an answer, by the original guest or anyone
            // it was forwarded to. The shared link reports that on submit (a
            // 409 shown inline on the form) rather than here, since it can't
            // know which guest it is until a name is typed.
            justSubmitted || !_isGuestLink
                ? 'Your RSVP has been received.\n$coupleName look forward to celebrating with you!'
                : 'This invitation link has already been used and can no longer be changed.\nContact $coupleName if you need to update your response.',
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
      'meal': _mealCtrl.text.trim(),
      'dietary': _dietaryCtrl.text.trim(),
      'message': _messageCtrl.text.trim(),
      'answers': _answerValues,
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
                          const Icon(Icons.arrow_forward, size: 18),
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
  final VoidCallback? onTap;
  const _InfoCard(
      {required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
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
            child: Icon(icon, size: 20, color: AppColors.goldDeep),
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
                    color: onTap != null ? AppColors.forestGreen : AppColors.textPrimary,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: card),
    );
  }
}

// ── Personal message card ───────────────────────────────────────────────────

class _MessageCard extends StatelessWidget {
  final String message;
  final Color accentColor;
  const _MessageCard({required this.message, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote, color: accentColor, size: 22),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontStyle: FontStyle.italic,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared field decoration ───────────────────────────────────────────────────

InputDecoration _rsvpFieldDec(String hint, {String? helperText}) => InputDecoration(
      hintText: hint,
      helperText: helperText,
      helperMaxLines: 3,
      helperStyle: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textHint),
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
        borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );

// Shown when the couple hasn't configured any meal options for this
// invitation — a reasonable default rather than showing nothing.
const _kDefaultMealOptions = ['Chicken', 'Beef', 'Vegetarian'];

// ── Meal preference: chip choices sourced from the couple's configured
// options (or the default set above), with an "Other" chip that reveals a
// free-text field — never hard-coded as the only way to answer. ──────────────

class _MealChoiceField extends StatefulWidget {
  final List<String> options;
  final TextEditingController controller;
  const _MealChoiceField({required this.options, required this.controller});

  @override
  State<_MealChoiceField> createState() => _MealChoiceFieldState();
}

class _MealChoiceFieldState extends State<_MealChoiceField> {
  late bool _custom = widget.controller.text.isNotEmpty &&
      !widget.options.contains(widget.controller.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in widget.options)
              _chip(
                option,
                selected: !_custom && widget.controller.text == option,
                onTap: () => setState(() {
                  _custom = false;
                  widget.controller.text = option;
                }),
              ),
            _chip(
              'Other',
              selected: _custom,
              onTap: () => setState(() {
                _custom = true;
                widget.controller.clear();
              }),
            ),
          ],
        ),
        if (_custom) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: widget.controller,
            decoration: _rsvpFieldDec('Enter your meal preference'),
          ),
        ],
      ],
    );
  }

  Widget _chip(String label, {required bool selected, required VoidCallback onTap}) {
    return Material(
      color: selected ? AppColors.forestGreen.withAlpha(23) : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.forestGreen : AppColors.divider,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.forestGreen : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom RSVP question: one input per RsvpQuestionType ─────────────────────

class _QuestionField extends StatelessWidget {
  final RsvpQuestion question;

  /// String for yes_no/single_choice/short_text/long_text/number;
  /// `List<String>` for multi_choice.
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final Color accentColor;

  const _QuestionField({
    required this.question,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case RsvpQuestionType.yesNo:
        return Row(
          children: [
            Expanded(child: _choiceChip('Yes', value == 'Yes', () => onChanged('Yes'))),
            const SizedBox(width: 8),
            Expanded(child: _choiceChip('No', value == 'No', () => onChanged('No'))),
          ],
        );
      case RsvpQuestionType.singleChoice:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in question.options)
              _choiceChip(option, value == option, () => onChanged(option)),
          ],
        );
      case RsvpQuestionType.multiChoice:
        final selected = (value is List ? value.cast<String>() : const <String>[]);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in question.options)
              _choiceChip(option, selected.contains(option), () {
                final next = List<String>.from(selected);
                next.contains(option) ? next.remove(option) : next.add(option);
                onChanged(next);
              }),
          ],
        );
      case RsvpQuestionType.number:
        return TextFormField(
          key: ValueKey(question.id),
          initialValue: value is String ? value : null,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _rsvpFieldDec('Enter a number'),
          onChanged: onChanged,
        );
      case RsvpQuestionType.longText:
        return TextFormField(
          key: ValueKey(question.id),
          initialValue: value is String ? value : null,
          maxLines: 3,
          decoration: _rsvpFieldDec('Your answer'),
          onChanged: onChanged,
        );
      case RsvpQuestionType.shortText:
        return TextFormField(
          key: ValueKey(question.id),
          initialValue: value is String ? value : null,
          decoration: _rsvpFieldDec('Your answer'),
          onChanged: onChanged,
        );
    }
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? accentColor.withAlpha(23) : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? accentColor : AppColors.divider, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? accentColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── RSVP form card ────────────────────────────────────────────────────────────

class _RsvpFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController mealCtrl;
  final TextEditingController dietaryCtrl;
  final TextEditingController messageCtrl;
  final String? rsvpBy;
  final AttendingStatus attending;
  final ValueChanged<AttendingStatus> onAttendingChanged;
  // Set entirely by the couple (via Guest.maxPartySize) — the guest confirms
  // yes/no/maybe but never chooses this number themselves. Null when the link
  // itself doesn't identify a guest yet (the shared broadcast link), so the
  // form describes the rule instead of stating a number it can't know.
  final int? guestCount;
  final List<MealOption> mealOptions;
  final List<RsvpQuestion> rsvpQuestions;
  final Map<String, dynamic> answerValues;
  final void Function(String questionId, dynamic value) onAnswerChanged;
  final String? error;
  final bool showEmailField;
  final bool readOnlyName;
  final Color accentColor;

  const _RsvpFormCard({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.mealCtrl,
    required this.dietaryCtrl,
    required this.messageCtrl,
    required this.rsvpBy,
    required this.attending,
    required this.onAttendingChanged,
    required this.guestCount,
    required this.mealOptions,
    this.rsvpQuestions = const [],
    this.answerValues = const {},
    required this.onAnswerChanged,
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
              // On the shared link the name is a lookup against the couple's
              // guest list, not free text — say so up front, so a mismatch
              // reads as a typo to fix rather than a broken invitation.
              decoration: _rsvpFieldDec(
                'Full name',
                helperText: readOnlyName
                    ? null
                    : 'Enter your name exactly as the couple wrote it on their guest list.',
              ),
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
                decoration: _rsvpFieldDec('Email address (optional)'),
              ),
            ],
            const SizedBox(height: 14),
            _FormLabel('Will you attend?'),
            const SizedBox(height: 8),
            _AttendRow(value: attending, onChanged: onAttendingChanged, accentColor: accentColor),
            if (attending != AttendingStatus.no) ...[
              const SizedBox(height: 16),
              _FormLabel('Guests covered by this invitation'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        // Null on the shared link: the couple's number lives
                        // against the guest record the name resolves to, and
                        // looking it up before submitting would turn this form
                        // into a "who's invited?" oracle. Showing "Just you"
                        // there was simply wrong for a family invitation.
                        guestCount == null
                            ? 'As set by the couple on your invitation'
                            : guestCount == 1
                                ? 'Just you'
                                : '$guestCount guests',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormLabel('Meal preference'),
              const SizedBox(height: 8),
              _MealChoiceField(
                options: mealOptions.isNotEmpty
                    ? mealOptions.map((o) => o.label).toList()
                    : _kDefaultMealOptions,
                controller: mealCtrl,
              ),
              const SizedBox(height: 14),
              _FormLabel('Dietary restrictions or allergies'),
              const SizedBox(height: 8),
              TextFormField(
                controller: dietaryCtrl,
                decoration: _rsvpFieldDec('Optional'),
              ),
              for (final question in rsvpQuestions.where((q) => q.isEnabled)) ...[
                const SizedBox(height: 14),
                _FormLabel(question.isRequired ? '${question.questionText} *' : question.questionText),
                const SizedBox(height: 8),
                _QuestionField(
                  question: question,
                  value: answerValues[question.id],
                  onChanged: (v) => onAnswerChanged(question.id, v),
                  accentColor: accentColor,
                ),
              ],
            ],
            const SizedBox(height: 14),
            _FormLabel('Message for the couple'),
            const SizedBox(height: 8),
            TextFormField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: _rsvpFieldDec('Optional'),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            ],
          ],
        ),
      ),
    );
  }
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
