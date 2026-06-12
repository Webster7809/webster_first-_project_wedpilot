import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';

enum _Step { invitation, form, success }

// ── Root widget ──────────────────────────────────────────────────────────────

class PublicInvitationScreen extends StatefulWidget {
  final String shareToken;
  const PublicInvitationScreen({super.key, required this.shareToken});

  @override
  State<PublicInvitationScreen> createState() => _PublicInvitationScreenState();
}

class _PublicInvitationScreenState extends State<PublicInvitationScreen> {
  _Step _step = _Step.invitation;

  // Form state lives here so it survives step transitions
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _attending = 'going';
  int _guestCount = 1;

  // Countdown
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;
  // In production this comes from the invitation data resolved by shareToken
  final _weddingDate = DateTime(2027, 6, 14, 16, 0);

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    final diff = _weddingDate.difference(DateTime.now());
    if (mounted) setState(() => _timeLeft = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: switch (_step) {
          _Step.invitation => _InvitationView(
              key: const ValueKey('inv'),
              timeLeft: _timeLeft,
              onRsvp: () => setState(() => _step = _Step.form),
            ),
          _Step.form => _FormView(
              key: const ValueKey('form'),
              nameCtrl: _nameCtrl,
              phoneCtrl: _phoneCtrl,
              messageCtrl: _messageCtrl,
              formKey: _formKey,
              attending: _attending,
              guestCount: _guestCount,
              onAttending: (v) => setState(() => _attending = v),
              onGuests: (v) => setState(() => _guestCount = v),
              onBack: () => setState(() => _step = _Step.invitation),
              onSubmit: () {
                if (_formKey.currentState!.validate()) {
                  setState(() => _step = _Step.success);
                }
              },
            ),
          _Step.success => _SuccessView(
              key: const ValueKey('ok'),
              name: _nameCtrl.text,
              attending: _attending,
              guestCount: _guestCount,
              message: _messageCtrl.text,
              onBack: () => setState(() => _step = _Step.invitation),
            ),
        },
      ),
    );
  }
}

// ── Screen 1: Invitation Landing ─────────────────────────────────────────────

class _InvitationView extends StatelessWidget {
  final Duration timeLeft;
  final VoidCallback onRsvp;
  const _InvitationView({super.key, required this.timeLeft, required this.onRsvp});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: false,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _DetailsCard(),
                  const SizedBox(height: 28),
                  Text(
                    'COUNTING DOWN TO THE BIG DAY',
                    style: AppTextStyles.caption.copyWith(letterSpacing: 2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _CountdownRow(timeLeft: timeLeft),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.location_on_outlined, size: 18),
                    label: const Text('View Venue on Map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: AppTextStyles.buttonText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  WedButton(label: 'RSVP Now  💌', onPressed: onRsvp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD81B8A), AppColors.secondary, Color(0xFF880E4F)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            const Text('💍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text(
              'Alex & Jordan',
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Are getting married!',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.white.withAlpha(217),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Please RSVP by May 1, 2027',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.primary.withAlpha(160), width: 1.5),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date & Time',
            value: 'June 14, 2027 · 4:00 PM',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Venue',
            value: 'The Garden Venue\nLong Island, NY',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Text(
            '"We joyfully invite you to share\nin our happiness as we begin our\njourney together."',
            style: GoogleFonts.playfairDisplay(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(80),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.secondary),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.headlineSmall),
          ],
        ),
      ],
    );
  }
}

class _CountdownRow extends StatelessWidget {
  final Duration timeLeft;
  const _CountdownRow({required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final days = timeLeft.inDays;
    final hours = timeLeft.inHours.remainder(24);
    final mins = timeLeft.inMinutes.remainder(60);
    final secs = timeLeft.inSeconds.remainder(60);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CountdownBox(value: days.toString().padLeft(3, '0'), label: 'Days'),
        _Colon(),
        _CountdownBox(value: hours.toString().padLeft(2, '0'), label: 'Hours'),
        _Colon(),
        _CountdownBox(value: mins.toString().padLeft(2, '0'), label: 'Mins'),
        _Colon(),
        _CountdownBox(value: secs.toString().padLeft(2, '0'), label: 'Secs'),
      ],
    );
  }
}

class _CountdownBox extends StatelessWidget {
  final String value;
  final String label;
  const _CountdownBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withAlpha(76), blurRadius: 10),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        ':',
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}

// ── Screen 2: RSVP Form ──────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController messageCtrl;
  final GlobalKey<FormState> formKey;
  final String attending;
  final int guestCount;
  final ValueChanged<String> onAttending;
  final ValueChanged<int> onGuests;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _FormView({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.messageCtrl,
    required this.formKey,
    required this.attending,
    required this.guestCount,
    required this.onAttending,
    required this.onGuests,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: onBack,
                  color: AppColors.secondary,
                ),
                Expanded(
                  child: Text(
                    'Your RSVP',
                    style: AppTextStyles.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Alex & Jordan · June 14, 2027',
            style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
            textAlign: TextAlign.center,
          ),
        ),
        const Divider(height: 1),

        // ── Scrollable form ──
        Expanded(
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Name
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fieldDec(
                      'Full Name',
                      Icons.person_outline,
                    ),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 14),

                  // Phone
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _fieldDec(
                      'Phone Number (optional)',
                      Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Attendance
                  Text('Will you be attending?', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _AttendanceCard(
                        emoji: '🎉',
                        label: 'Going',
                        value: 'going',
                        selected: attending,
                        activeColor: AppColors.secondary,
                        onTap: onAttending,
                      ),
                      const SizedBox(width: 8),
                      _AttendanceCard(
                        emoji: '😔',
                        label: 'Not Going',
                        value: 'not_going',
                        selected: attending,
                        activeColor: AppColors.neutralDark,
                        onTap: onAttending,
                      ),
                      const SizedBox(width: 8),
                      _AttendanceCard(
                        emoji: '🤔',
                        label: 'Maybe',
                        value: 'maybe',
                        selected: attending,
                        activeColor: AppColors.goldPremium,
                        onTap: onAttending,
                      ),
                    ],
                  ),

                  // Guest count — animated, hidden when not going
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    child: attending == 'not_going'
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: _GuestCountRow(
                              count: guestCount,
                              onChanged: onGuests,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Message
                  Text('Message to the Couple', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: messageCtrl,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Share your wishes or a personal note…',
                      hintStyle: AppTextStyles.bodySmall,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.secondary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 28),

                  WedButton(label: 'Send RSVP  💌', onPressed: onSubmit),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static InputDecoration _fieldDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String selected;
  final Color activeColor;
  final ValueChanged<String> onTap;

  const _AttendanceCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.divider,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withAlpha(70),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 5),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestCountRow extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;
  const _GuestCountRow({required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Number of Guests', style: AppTextStyles.labelLarge),
          ),
          _StepBtn(
            icon: Icons.remove,
            enabled: count > 1,
            onTap: () => onChanged(count - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              '$count',
              style: AppTextStyles.headlineMedium.copyWith(color: AppColors.secondary),
            ),
          ),
          _StepBtn(
            icon: Icons.add,
            enabled: count < 10,
            onTap: () => onChanged(count + 1),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.divider,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.secondary : AppColors.textHint,
        ),
      ),
    );
  }
}

// ── Screen 3: Success ────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final String name;
  final String attending;
  final int guestCount;
  final String message;
  final VoidCallback onBack;

  const _SuccessView({
    super.key,
    required this.name,
    required this.attending,
    required this.guestCount,
    required this.message,
    required this.onBack,
  });

  String get _attendingLabel => switch (attending) {
        'going' => '🎉 Going',
        'not_going' => '😔 Not Going',
        _ => '🤔 Maybe',
      };

  String get _firstName => name.trim().split(' ').first;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text('🎊', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 20),
                    Text(
                      'Thank You, $_firstName!',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your RSVP has been received.\nAlex & Jordan look forward to hearing from you!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Summary card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(153),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withAlpha(22),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 20),
                              const SizedBox(width: 8),
                              Text('RSVP Summary', style: AppTextStyles.headlineSmall),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 14),
                          _SummaryRow(label: 'Name', value: name),
                          const SizedBox(height: 10),
                          _SummaryRow(label: 'Attendance', value: _attendingLabel),
                          if (attending != 'not_going') ...[
                            const SizedBox(height: 10),
                            _SummaryRow(
                              label: 'Guests',
                              value:
                                  '$guestCount ${guestCount == 1 ? 'person' : 'people'}',
                            ),
                          ],
                          if (message.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _SummaryRow(label: 'Message', value: '"${message.trim()}"'),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    Text(
                      'We can\'t wait to celebrate\nthis special day with you!',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            WedButton(
              label: 'Back to Invitation',
              onPressed: onBack,
              variant: WedButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
