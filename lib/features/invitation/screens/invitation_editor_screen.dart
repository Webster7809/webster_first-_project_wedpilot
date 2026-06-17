import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/invitation_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

// ─── Font options ───────────────────────────────────────────────────────────

class _FontOption {
  final String label;
  final String category;
  final TextStyle Function(double size, Color color) style;
  const _FontOption(this.label, this.category, this.style);
}

final _fontOptions = <_FontOption>[
  _FontOption('Great Vibes', 'Script',
      (s, c) => GoogleFonts.greatVibes(fontSize: s, color: c)),
  _FontOption('Sacramento', 'Script',
      (s, c) => GoogleFonts.sacramento(fontSize: s, color: c)),
  _FontOption('Dancing Script', 'Script',
      (s, c) => GoogleFonts.dancingScript(
          fontSize: s, color: c, fontWeight: FontWeight.w700)),
  _FontOption('Pinyon Script', 'Script',
      (s, c) => GoogleFonts.pinyonScript(fontSize: s, color: c)),
  _FontOption('Alex Brush', 'Script',
      (s, c) => GoogleFonts.alexBrush(fontSize: s, color: c)),
  _FontOption('Allura', 'Script',
      (s, c) => GoogleFonts.allura(fontSize: s, color: c)),
  _FontOption('Tangerine', 'Script',
      (s, c) => GoogleFonts.tangerine(
          fontSize: s, color: c, fontWeight: FontWeight.w700)),
  _FontOption('Parisienne', 'Script',
      (s, c) => GoogleFonts.parisienne(fontSize: s, color: c)),
  _FontOption('Playfair Display', 'Serif',
      (s, c) => GoogleFonts.playfairDisplay(
          fontSize: s, color: c, fontWeight: FontWeight.bold)),
  _FontOption('Cormorant Garamond', 'Serif',
      (s, c) => GoogleFonts.cormorantGaramond(
          fontSize: s, color: c, fontWeight: FontWeight.w600)),
  _FontOption('Cinzel', 'Serif',
      (s, c) =>
          GoogleFonts.cinzel(fontSize: s, color: c, fontWeight: FontWeight.w700)),
  _FontOption('EB Garamond', 'Serif',
      (s, c) => GoogleFonts.ebGaramond(
          fontSize: s, color: c, fontWeight: FontWeight.w600)),
  _FontOption('Lora', 'Serif',
      (s, c) =>
          GoogleFonts.lora(fontSize: s, color: c, fontWeight: FontWeight.w600)),
  _FontOption('Bodoni Moda', 'Serif',
      (s, c) => GoogleFonts.bodoniModa(
          fontSize: s, color: c, fontWeight: FontWeight.w700)),
  _FontOption('Montserrat', 'Modern',
      (s, c) => GoogleFonts.montserrat(
          fontSize: s, color: c, fontWeight: FontWeight.w600)),
  _FontOption('Raleway', 'Modern',
      (s, c) => GoogleFonts.raleway(
          fontSize: s, color: c, fontWeight: FontWeight.w600)),
  _FontOption('Josefin Sans', 'Modern',
      (s, c) => GoogleFonts.josefinSans(
          fontSize: s, color: c, fontWeight: FontWeight.w600)),
  _FontOption('Lobster', 'Decorative',
      (s, c) => GoogleFonts.lobster(fontSize: s, color: c)),
  _FontOption('Pacifico', 'Decorative',
      (s, c) => GoogleFonts.pacifico(fontSize: s, color: c)),
  _FontOption('Libre Baskerville', 'Decorative',
      (s, c) => GoogleFonts.libreBaskerville(
          fontSize: s, color: c, fontWeight: FontWeight.bold)),
];

// ─── Colour palette ─────────────────────────────────────────────────────────

class _ColorSwatch {
  final String name;
  final Color color;
  const _ColorSwatch(this.name, this.color);
}

class _ColorCategory {
  final String name;
  final List<_ColorSwatch> swatches;
  const _ColorCategory(this.name, this.swatches);
}

final _colorCategories = <_ColorCategory>[
  _ColorCategory('Romantic', [
    _ColorSwatch('Blush', const Color(0xFFF06292)),
    _ColorSwatch('Deep Rose', const Color(0xFFC2185B)),
    _ColorSwatch('Bordeaux', const Color(0xFF880E4F)),
    _ColorSwatch('Coral', const Color(0xFFFF5722)),
    _ColorSwatch('Dusty Rose', const Color(0xFFEF9A9A)),
  ]),
  _ColorCategory('Royal', [
    _ColorSwatch('Royal Purple', const Color(0xFF7B1FA2)),
    _ColorSwatch('Lavender', const Color(0xFF9575CD)),
    _ColorSwatch('Plum', const Color(0xFF6A1B9A)),
    _ColorSwatch('Sage Gold', const Color(0xFFD4A854)),
    _ColorSwatch('Champagne', const Color(0xFFBFA980)),
  ]),
  _ColorCategory('Nature', [
    _ColorSwatch('Navy', const Color(0xFF1A237E)),
    _ColorSwatch('Sky Blue', const Color(0xFF0288D1)),
    _ColorSwatch('Emerald', const Color(0xFF2E7D32)),
    _ColorSwatch('Sage', const Color(0xFF558B2F)),
    _ColorSwatch('Teal', const Color(0xFF00695C)),
  ]),
  _ColorCategory('Neutral', [
    _ColorSwatch('Brown', const Color(0xFF5D4037)),
    _ColorSwatch('Terracotta', const Color(0xFFBF360C)),
    _ColorSwatch('Midnight', const Color(0xFF0D0D2B)),
    _ColorSwatch('Charcoal', const Color(0xFF37474F)),
    _ColorSwatch('Rose Gold', const Color(0xFFB76E79)),
  ]),
];

// ─── Screen ────────────────────────────────────────────────────────────────

class InvitationEditorScreen extends ConsumerStatefulWidget {
  final String? invitationId;
  const InvitationEditorScreen({super.key, this.invitationId});

  @override
  ConsumerState<InvitationEditorScreen> createState() =>
      _InvitationEditorScreenState();
}

class _InvitationEditorScreenState
    extends ConsumerState<InvitationEditorScreen> {
  // ── Existing fields ──────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController(text: 'Chanda & Mwila');
  final _subtitleCtrl =
      TextEditingController(text: 'Together with their families');
  final _dateCtrl = TextEditingController(text: '14 June 2027');
  final _timeCtrl = TextEditingController(text: '10:00 AM');
  final _venueCtrl =
      TextEditingController(text: 'St. Ignatius Catholic Church, Lusaka');
  final _receptionVenueCtrl =
      TextEditingController(text: 'Lusaka Intercontinental Hotel, Lusaka');
  final _rsvpCtrl = TextEditingController(text: '31 May 2027');
  final _dressCodeCtrl =
      TextEditingController(text: 'Traditional Zambian Attire');
  final _contactCtrl = TextEditingController(text: '+260 97 1234567');
  final _msgCtrl = TextEditingController(
    text: 'We joyfully invite you to share in the celebration of our marriage.',
  );

  // ── New fields ───────────────────────────────────────────────────────────
  final _churchThemeCtrl = TextEditingController(text: 'A Covenant Love');
  final _churchTimeCtrl = TextEditingController(text: '09:00 AM');
  final _giftTypeCtrl = TextEditingController(text: 'Cash gifts appreciated');

  Color _accentColor = const Color(0xFFF06292);
  int _selectedFont = 0;
  double _fontSize = 24.0;
  Uint8List? _backgroundImageBytes;

  // 'details' | 'font' | 'style' | null (all collapsed)
  String? _expandedSection;

  // Editor panel & image transform state
  bool _editorOpen = false;
  double _imageScale = 1.0;
  Offset _imageOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.invitationId == null) return;
    final invitations = ref.read(invitationsProvider);
    final existing =
        invitations.where((i) => i.id == widget.invitationId).firstOrNull;
    if (existing == null) return;

    final data = existing.customData;
    _nameCtrl.text = (data['coupleName'] as String?) ?? _nameCtrl.text;
    _subtitleCtrl.text = (data['subtitle'] as String?) ?? _subtitleCtrl.text;
    _dateCtrl.text = (data['date'] as String?) ?? _dateCtrl.text;
    _timeCtrl.text = (data['time'] as String?) ?? _timeCtrl.text;
    _venueCtrl.text = (data['venue'] as String?) ?? _venueCtrl.text;
    _receptionVenueCtrl.text =
        (data['receptionVenue'] as String?) ?? _receptionVenueCtrl.text;
    _rsvpCtrl.text = (data['rsvpBy'] as String?) ?? _rsvpCtrl.text;
    _dressCodeCtrl.text =
        (data['dressCode'] as String?) ?? _dressCodeCtrl.text;
    _contactCtrl.text = (data['contact'] as String?) ?? _contactCtrl.text;
    _msgCtrl.text = (data['message'] as String?) ?? _msgCtrl.text;
    _churchThemeCtrl.text =
        (data['churchTheme'] as String?) ?? _churchThemeCtrl.text;
    _churchTimeCtrl.text =
        (data['churchTime'] as String?) ?? _churchTimeCtrl.text;
    _giftTypeCtrl.text = (data['giftType'] as String?) ?? _giftTypeCtrl.text;

    final fontIndex = data['fontIndex'] as int?;
    final colorValue = data['accentColor'] as int?;
    final fs = data['fontSize'] as double?;
    if (fontIndex != null && fontIndex < _fontOptions.length) {
      _selectedFont = fontIndex;
    }
    if (colorValue != null) _accentColor = Color(colorValue);
    if (fs != null) _fontSize = fs.clamp(18.0, 48.0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _venueCtrl.dispose();
    _receptionVenueCtrl.dispose();
    _rsvpCtrl.dispose();
    _dressCodeCtrl.dispose();
    _contactCtrl.dispose();
    _msgCtrl.dispose();
    _churchThemeCtrl.dispose();
    _churchTimeCtrl.dispose();
    _giftTypeCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildCustomData() => {
        'coupleName': _nameCtrl.text.trim(),
        'subtitle': _subtitleCtrl.text.trim(),
        'date': _dateCtrl.text.trim(),
        'time': _timeCtrl.text.trim(),
        'venue': _venueCtrl.text.trim(),
        'receptionVenue': _receptionVenueCtrl.text.trim(),
        'rsvpBy': _rsvpCtrl.text.trim(),
        'dressCode': _dressCodeCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'message': _msgCtrl.text.trim(),
        'churchTheme': _churchThemeCtrl.text.trim(),
        'churchTime': _churchTimeCtrl.text.trim(),
        'giftType': _giftTypeCtrl.text.trim(),
        'fontIndex': _selectedFont,
        'accentColor': _accentColor.toARGB32(),
        'fontSize': _fontSize,
      };

  void _saveEdits() {
    if (widget.invitationId == null) return;
    ref
        .read(invitationsProvider.notifier)
        .updateCustomData(widget.invitationId!, _buildCustomData());
  }

  Future<void> _saveAndShare() async {
    if (widget.invitationId == null) {
      showWedSnackBar(context, 'Please select a design first',
          type: SnackType.info);
      return;
    }
    final notifier = ref.read(invitationsProvider.notifier);
    notifier.updateCustomData(widget.invitationId!, _buildCustomData());
    notifier.publish(widget.invitationId!);

    final invitation = ref
        .read(invitationsProvider)
        .where((i) => i.id == widget.invitationId)
        .firstOrNull;

    final shareUrl = invitation?.shareUrl ??
        'https://wedpilot.app/i/${invitation?.shareToken ?? ''}';
    final coupleName =
        _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Us';

    await Share.share(
      'You\'re invited to celebrate our wedding! 💍\n\n'
      'View our invitation here: $shareUrl',
      subject: 'Wedding Invitation – $coupleName',
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _backgroundImageBytes = bytes);
    }
  }

  Future<void> _pickImageFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'bmp', 'gif'],
      withData: true,
    );
    if (result != null) {
      final bytes = result.files.single.bytes;
      if (bytes != null) setState(() => _backgroundImageBytes = bytes);
    }
  }

  void _showImageSourceSheet() {
    final hasPhoto = _backgroundImageBytes != null;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _photoOptionButton(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: _accentColor,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _photoOptionButton(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: _accentColor,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _photoOptionButton(
                    context,
                    icon: Icons.folder_open_rounded,
                    label: 'Files',
                    color: _accentColor,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _pickImageFromFiles();
                    },
                  ),
                ],
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 20),
                Divider(color: theme.dividerColor, height: 1),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    setState(() => _backgroundImageBytes = null);
                  },
                  child: Text(
                    'Remove Photo',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _photoOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSection(String? id) =>
      setState(() => _expandedSection = id);

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 640;
    final previewH =
        (MediaQuery.sizeOf(context).height * 0.28).clamp(180.0, 240.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Design Your Invitation',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: theme.dividerColor),
        ),
        actions: [
          // Editor sections toggle — narrow layout only
          if (!isWide) _buildEditorToggle(theme),
          if (widget.invitationId != null)
            TextButton(
              onPressed: () {
                _saveEdits();
                showWedSnackBar(context, 'Saved!', type: SnackType.success);
              },
              style: TextButton.styleFrom(
                  foregroundColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              child: Text('Save',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          TextButton.icon(
            onPressed: _saveAndShare,
            icon: const Icon(Icons.share_rounded, size: 16),
            label: Text('Share',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.secondary),
          ),
        ],
      ),
      body: isWide
          ? _buildWideLayout(theme, previewH)
          : _buildNarrowLayout(theme, screenWidth),
    );
  }

  // ── Narrow (mobile) — full-screen card with floating right-side editor panel ─
  Widget _buildNarrowLayout(ThemeData theme, double screenWidth) {
    final panelWidth = (screenWidth * 0.82).clamp(260.0, 350.0);
    return Stack(
      children: [
        // Full-screen invitation card preview
        Positioned.fill(child: _buildPreview()),

        // Tap-outside scrim to close editor
        if (_editorOpen)
          Positioned(
            top: 0, left: 0, bottom: 0,
            right: panelWidth,
            child: GestureDetector(
              onTap: () => setState(() => _editorOpen = false),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),

        // Animated floating editor panel sliding from right
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          top: 0,
          bottom: 0,
          right: _editorOpen ? 0 : -panelWidth,
          width: panelWidth,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.97),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(-6, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Panel header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.06),
                    border: Border(
                        bottom: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded,
                          size: 15, color: _accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Editor Sections',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _accentColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55)),
                        onPressed: () =>
                            setState(() => _editorOpen = false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                // Accordion sections
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildAccordionColumn(theme),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Editor toggle button (shown in AppBar for narrow layout only) ─────────
  Widget _buildEditorToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _editorOpen = !_editorOpen),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _editorOpen
                  ? _accentColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: _editorOpen
                  ? Border.all(
                      color: _accentColor.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded,
                    size: 14,
                    color: _editorOpen
                        ? _accentColor
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.65)),
                const SizedBox(width: 4),
                Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _editorOpen
                        ? _accentColor
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: _editorOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _editorOpen
                        ? _accentColor
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Wide (tablet / desktop) ───────────────────────────────────────────────
  Widget _buildWideLayout(ThemeData theme, double previewH) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left sidebar
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border:
                Border(right: BorderSide(color: theme.dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded,
                        size: 15, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Editor Sections',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildAccordionColumn(theme),
                ),
              ),
            ],
          ),
        ),
        // Right: preview + actions
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: theme.scaffoldBackgroundColor,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildPreview(),
                      ),
                    ),
                  ),
                ),
              ),
              Container(height: 1, color: theme.dividerColor),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    if (widget.invitationId != null) ...[
                      Expanded(
                        child: WedButton(
                          label: 'Save',
                          variant: WedButtonVariant.secondary,
                          onPressed: () {
                            _saveEdits();
                            showWedSnackBar(context, 'Saved!',
                                type: SnackType.success);
                          },
                          icon: Icons.save_outlined,
                          height: 44,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: WedButton(
                        label: 'Share Invitation',
                        onPressed: _saveAndShare,
                        icon: Icons.share_rounded,
                        height: 44,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Invitation preview ────────────────────────────────────────────────────
  Widget _buildPreview() => _InvitationPreview(
        names: _nameCtrl.text,
        subtitle: _subtitleCtrl.text,
        date: _dateCtrl.text,
        time: _timeCtrl.text,
        venue: _venueCtrl.text,
        receptionVenue: _receptionVenueCtrl.text,
        rsvpBy: _rsvpCtrl.text,
        contact: _contactCtrl.text,
        dressCode: _dressCodeCtrl.text,
        message: _msgCtrl.text,
        churchTheme: _churchThemeCtrl.text,
        churchTime: _churchTimeCtrl.text,
        giftType: _giftTypeCtrl.text,
        color: _accentColor,
        fontOption: _fontOptions[_selectedFont],
        fontSize: _fontSize,
        backgroundImageBytes: _backgroundImageBytes,
        imageScale: _imageScale,
        imageOffset: _imageOffset,
        onPhotoTap: _showImageSourceSheet,
        onImageTransform: (scale, offset) => setState(() {
          _imageScale = scale;
          _imageOffset = offset;
        }),
      );

  // ── Accordion column ──────────────────────────────────────────────────────
  Widget _buildAccordionColumn(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccordionSection(
          id: 'details',
          title: 'Details',
          subtitle: 'Names, dates & venue',
          icon: Icons.edit_rounded,
          expandedId: _expandedSection,
          onToggle: _toggleSection,
          accentColor: _accentColor,
          content: _buildDetailsContent(theme),
        ),
        Container(height: 1, color: theme.dividerColor),
        _AccordionSection(
          id: 'font',
          title: 'Font',
          subtitle: 'Typography & size',
          icon: Icons.font_download_rounded,
          expandedId: _expandedSection,
          onToggle: _toggleSection,
          accentColor: _accentColor,
          content: _buildFontContent(theme),
        ),
        Container(height: 1, color: theme.dividerColor),
        _AccordionSection(
          id: 'style',
          title: 'Style',
          subtitle: 'Colours & accent',
          icon: Icons.palette_rounded,
          expandedId: _expandedSection,
          onToggle: _toggleSection,
          accentColor: _accentColor,
          content: _buildStyleContent(theme),
        ),
        Container(height: 1, color: theme.dividerColor),
      ],
    );
  }

  // ── Details content ───────────────────────────────────────────────────────
  Widget _buildDetailsContent(ThemeData theme) {
    final hasPhoto = _backgroundImageBytes != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo import
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: hasPhoto
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.secondary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasPhoto
                      ? AppColors.success
                      : AppColors.secondary,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasPhoto
                        ? Icons.check_circle_rounded
                        : Icons.add_photo_alternate_rounded,
                    color: hasPhoto
                        ? AppColors.success
                        : AppColors.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      hasPhoto
                          ? 'Photo added — tap to change'
                          : 'Import a Photo for Your Card',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasPhoto
                            ? AppColors.success
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Image scale & position controls (visible only when photo is loaded)
          if (hasPhoto) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_size_select_large_rounded,
                          size: 13, color: AppColors.secondary),
                      const SizedBox(width: 5),
                      Text(
                        'Image Scale & Position',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(_imageScale * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _accentColor,
                      thumbColor: _accentColor,
                      inactiveTrackColor:
                          _accentColor.withValues(alpha: 0.2),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14),
                    ),
                    child: Slider(
                      value: _imageScale,
                      min: 0.5,
                      max: 3.0,
                      divisions: 25,
                      onChanged: (v) =>
                          setState(() => _imageScale = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('50%',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4))),
                      if (_imageOffset != Offset.zero || _imageScale != 1.0)
                        GestureDetector(
                          onTap: () => setState(() {
                            _imageOffset = Offset.zero;
                            _imageScale = 1.0;
                          }),
                          child: Text(
                            'Reset Position',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _accentColor,
                            ),
                          ),
                        ),
                      Text('300%',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pinch to zoom in and fill the card • drag to reposition',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          _SectionLabel('Couple'),
          _EditorField(
              label: 'Couple Names',
              icon: Icons.favorite_rounded,
              controller: _nameCtrl,
              onChanged: (_) => setState(() {})),
          _EditorField(
              label: 'Opening Line',
              icon: Icons.format_quote_rounded,
              controller: _subtitleCtrl,
              onChanged: (_) => setState(() {})),

          _SectionLabel('Ceremony'),
          _EditorField(
              label: 'Church / Ceremony Venue',
              icon: Icons.church_rounded,
              controller: _venueCtrl,
              onChanged: (_) => setState(() {})),
          _EditorField(
              label: 'Wedding Date',
              icon: Icons.calendar_today_rounded,
              controller: _dateCtrl,
              onChanged: (_) => setState(() {})),
          _EditorField(
              label: 'Ceremony Time',
              icon: Icons.schedule_rounded,
              controller: _timeCtrl,
              onChanged: (_) => setState(() {})),
          _EditorField(
              label: 'Church Service Theme / Talk',
              icon: Icons.record_voice_over_rounded,
              controller: _churchThemeCtrl,
              onChanged: (_) => setState(() {})),
          _EditorField(
              label: 'Church Service Time',
              icon: Icons.access_time_rounded,
              controller: _churchTimeCtrl,
              onChanged: (_) => setState(() {})),

          _SectionLabel('Reception'),
          _EditorField(
              label: 'Reception Venue',
              icon: Icons.location_on_rounded,
              controller: _receptionVenueCtrl,
              onChanged: (_) => setState(() {})),

          _SectionLabel('RSVP & Gifts'),
          _EditorField(
              label: 'RSVP By Date',
              icon: Icons.event_available_rounded,
              controller: _rsvpCtrl,
              onChanged: (_) => setState(() {})),
          _EditorField(
              label: 'Contact Number',
              icon: Icons.phone_rounded,
              controller: _contactCtrl,
              onChanged: (_) => setState(() {})),
          _EditorField(
              label: 'Dress Code',
              icon: Icons.checkroom_rounded,
              controller: _dressCodeCtrl,
              onChanged: (_) => setState(() {})),
          _EditorField(
              label: 'Gift Type',
              icon: Icons.card_giftcard_rounded,
              controller: _giftTypeCtrl,
              onChanged: (_) => setState(() {})),

          _SectionLabel('Message'),
          _EditorField(
              label: 'Personal Message',
              icon: Icons.message_rounded,
              controller: _msgCtrl,
              maxLines: 3,
              onChanged: (_) => setState(() {})),
        ],
      ),
    );
  }

  // ── Font content ──────────────────────────────────────────────────────────
  Widget _buildFontContent(ThemeData theme) {
    final groups = <String, List<(int, _FontOption)>>{};
    for (int i = 0; i < _fontOptions.length; i++) {
      final f = _fontOptions[i];
      groups.putIfAbsent(f.category, () => []).add((i, f));
    }
    final displayName = _nameCtrl.text.trim().isEmpty
        ? 'Chanda & Mwila'
        : _nameCtrl.text.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Font size slider
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'NAME FONT SIZE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_fontSize.round()}px',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline_rounded,
                        color: _fontSize > 18
                            ? _accentColor
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                      ),
                      iconSize: 22,
                      onPressed: _fontSize > 18
                          ? () => setState(() =>
                              _fontSize = (_fontSize - 2).clamp(18.0, 48.0))
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _accentColor,
                          thumbColor: _accentColor,
                          inactiveTrackColor:
                              _accentColor.withValues(alpha: 0.2),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16),
                        ),
                        child: Slider(
                          value: _fontSize,
                          min: 18,
                          max: 48,
                          divisions: 15,
                          onChanged: (v) => setState(() => _fontSize = v),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: _fontSize < 48
                            ? _accentColor
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                      ),
                      iconSize: 22,
                      onPressed: _fontSize < 48
                          ? () => setState(() =>
                              _fontSize = (_fontSize + 2).clamp(18.0, 48.0))
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Font family groups
          for (final entry in groups.entries) ...[
            _FontGroupHeader(entry.key),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
              children: [
                for (final (idx, font) in entry.value)
                  _FontCard(
                    font: font,
                    isSelected: idx == _selectedFont,
                    accentColor: _accentColor,
                    previewText: displayName,
                    onTap: () => setState(() => _selectedFont = idx),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // ── Style content ─────────────────────────────────────────────────────────
  Widget _buildStyleContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Style Colour', style: AppTextStyles.labelLarge),
          const SizedBox(height: 4),
          Text(
            'Sets the primary colour for text and decorations on your invitation.',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),

          for (final category in _colorCategories) ...[
            _ColorCategoryRow(
              category: category,
              selectedColor: _accentColor,
              onColorSelect: (c) => setState(() => _accentColor = c),
            ),
            const SizedBox(height: 16),
          ],

          // Custom colour picker
          GestureDetector(
            onTap: () => _openCustomColorPicker(
                context, _accentColor, (c) => setState(() => _accentColor = c)),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: theme.dividerColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [
                        Colors.red,
                        Colors.orange,
                        Colors.yellow,
                        Colors.green,
                        Colors.blue,
                        Colors.purple,
                        Colors.red,
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Custom Color',
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          'Mix your own with RGB controls',
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.dividerColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 16),

          Text('Share & Export', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: WedButton(
                  label: 'Share Link',
                  variant: WedButtonVariant.secondary,
                  onPressed: _saveAndShare,
                  icon: Icons.link_rounded,
                  height: 40,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WedButton(
                  label: 'Export PDF',
                  variant: WedButtonVariant.secondary,
                  onPressed: () {
                    if (mounted) {
                      showWedSnackBar(context, 'PDF generated!',
                          type: SnackType.success);
                    }
                  },
                  icon: Icons.picture_as_pdf_outlined,
                  height: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Accordion Section ────────────────────────────────────────────────────────

class _AccordionSection extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? expandedId;
  final ValueChanged<String?> onToggle;
  final Color accentColor;
  final Widget content;

  const _AccordionSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.expandedId,
    required this.onToggle,
    required this.accentColor,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = expandedId == id;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: isExpanded
              ? accentColor.withValues(alpha: 0.06)
              : Colors.transparent,
          child: InkWell(
            onTap: () => onToggle(isExpanded ? null : id),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? accentColor.withValues(alpha: 0.15)
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 16,
                        color: isExpanded
                            ? accentColor
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isExpanded
                                ? accentColor
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: isExpanded
                          ? accentColor
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            heightFactor: isExpanded ? 1.0 : 0.0,
            child: content,
          ),
        ),
      ],
    );
  }
}

// ─── Live Preview ─────────────────────────────────────────────────────────────

class _InvitationPreview extends StatefulWidget {
  final String names, subtitle, date, time, venue, receptionVenue, rsvpBy,
      contact, dressCode, message, churchTheme, churchTime, giftType;
  final Color color;
  final _FontOption fontOption;
  final double fontSize;
  final Uint8List? backgroundImageBytes;
  final double imageScale;
  final Offset imageOffset;
  final VoidCallback onPhotoTap;
  final void Function(double scale, Offset offset)? onImageTransform;

  const _InvitationPreview({
    required this.names,
    required this.subtitle,
    required this.date,
    required this.time,
    required this.venue,
    required this.receptionVenue,
    required this.rsvpBy,
    required this.contact,
    required this.dressCode,
    required this.message,
    required this.churchTheme,
    required this.churchTime,
    required this.giftType,
    required this.color,
    required this.fontOption,
    required this.fontSize,
    required this.onPhotoTap,
    this.backgroundImageBytes,
    this.imageScale = 1.0,
    this.imageOffset = Offset.zero,
    this.onImageTransform,
  });

  @override
  State<_InvitationPreview> createState() => _InvitationPreviewState();
}

class _InvitationPreviewState extends State<_InvitationPreview> {
  // Gesture state — captured at gesture start and updated live during gesture
  bool _gestureActive = false;
  double _gestureScale = 1.0;
  Offset _gestureOffset = Offset.zero;
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  double get _displayScale => _gestureActive ? _gestureScale : widget.imageScale;
  Offset get _displayOffset => _gestureActive ? _gestureOffset : widget.imageOffset;

  void _onScaleStart(ScaleStartDetails d) {
    _startScale = widget.imageScale;
    _startOffset = widget.imageOffset;
    _startFocal = d.localFocalPoint;
    setState(() {
      _gestureActive = true;
      _gestureScale = _startScale;
      _gestureOffset = _startOffset;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _gestureScale = (_startScale * d.scale).clamp(0.5, 5.0);
      _gestureOffset = _startOffset + (d.localFocalPoint - _startFocal);
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    widget.onImageTransform?.call(_gestureScale, _gestureOffset);
    setState(() => _gestureActive = false);
  }

  Widget _dot(Color c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
            width: 1, height: 8, color: c.withValues(alpha: 0.4)),
      );

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.backgroundImageBytes != null;
    final textColor = hasPhoto ? Colors.white : widget.color;
    final subColor = hasPhoto
        ? Colors.white.withValues(alpha: 0.85)
        : widget.color.withValues(alpha: 0.7);
    final metaColor = hasPhoto
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.textSecondary;

    return Stack(
      fit: StackFit.expand,
      children: [
        // White background
        Positioned.fill(child: Container(color: Colors.white)),

        // No-photo gradient
        if (!hasPhoto)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color.withValues(alpha: 0.08),
                    widget.color.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

        // Photo layer — fitWidth fills the card edge-to-edge with no side bars.
        // Alignment.center frames the middle of the photo on upload so nothing is
        // force-cropped; user drags down to reveal the top (head) or up to reveal
        // the bottom (dress/feet), and pinches to zoom in.
        if (hasPhoto)
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: ClipRect(
                child: Transform.translate(
                  offset: _displayOffset,
                  child: Transform.scale(
                    scale: _displayScale,
                    alignment: Alignment.center,
                    child: SizedBox.expand(
                      child: Image.memory(
                        widget.backgroundImageBytes!,
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Overlay gradient for text legibility
        if (hasPhoto)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

        // Pinch & drag hint — sits just above the accent bar
        if (hasPhoto)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.open_with_rounded,
                          size: 10, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Drag up/down to reveal more • pinch to zoom',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Accent bar at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(height: 3, color: widget.color),
        ),

        // ── All invitation text ──
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: LayoutBuilder(
              builder: (ctx, bc) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(
                  width: bc.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Opening line
                      Text(
                        widget.subtitle.isEmpty
                            ? 'Together with their families'
                            : widget.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          letterSpacing: 1.4,
                          color: subColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Couple names
                      Text(
                        widget.names.isEmpty
                            ? 'Couple Names'
                            : widget.names,
                        style: widget.fontOption
                            .style(widget.fontSize, textColor),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Divider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              width: 40,
                              height: 0.8,
                              color: textColor.withValues(alpha: 0.35)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8),
                            child: Icon(Icons.favorite_rounded,
                                size: 9, color: textColor),
                          ),
                          Container(
                              width: 40,
                              height: 0.8,
                              color: textColor.withValues(alpha: 0.35)),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Date · Time
                      Text(
                        widget.time.isNotEmpty
                            ? '${widget.date.isEmpty ? 'Wedding Date' : widget.date}  ·  ${widget.time}'
                            : (widget.date.isEmpty
                                ? 'Wedding Date'
                                : widget.date),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Church venue
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.church_rounded,
                              size: 9, color: subColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.venue.isEmpty
                                  ? 'Church / Ceremony Venue'
                                  : widget.venue,
                              style: GoogleFonts.inter(
                                  fontSize: 8.5, color: metaColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),

                      // Church theme & service time
                      if (widget.churchTheme.isNotEmpty ||
                          widget.churchTime.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.record_voice_over_rounded,
                                size: 8, color: subColor),
                            const SizedBox(width: 3),
                            if (widget.churchTheme.isNotEmpty)
                              Flexible(
                                child: Text(
                                  widget.churchTheme,
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: metaColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (widget.churchTheme.isNotEmpty &&
                                widget.churchTime.isNotEmpty)
                              _dot(metaColor),
                            if (widget.churchTime.isNotEmpty)
                              Text(
                                widget.churchTime,
                                style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: metaColor,
                                    fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ],

                      // Reception venue
                      if (widget.receptionVenue.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 9, color: subColor),
                            const SizedBox(width: 4),
                            Text(
                              'Reception: ',
                              style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: subColor,
                                  fontWeight: FontWeight.w600),
                            ),
                            Flexible(
                              child: Text(
                                widget.receptionVenue,
                                style: GoogleFonts.inter(
                                    fontSize: 8.5, color: metaColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),

                      // RSVP pill — rsvpBy · contact · dressCode · giftType
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: textColor.withValues(alpha: 0.22),
                              width: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.rsvpBy.isNotEmpty) ...[
                              Icon(Icons.event_available_rounded,
                                  size: 7, color: metaColor),
                              const SizedBox(width: 2),
                              Text(
                                'RSVP: ${widget.rsvpBy}',
                                style: GoogleFonts.inter(
                                    fontSize: 7.5,
                                    color: metaColor,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                            if (widget.rsvpBy.isNotEmpty &&
                                widget.contact.isNotEmpty)
                              _dot(metaColor),
                            if (widget.contact.isNotEmpty) ...[
                              Icon(Icons.phone_rounded,
                                  size: 7, color: metaColor),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  widget.contact,
                                  style: GoogleFonts.inter(
                                      fontSize: 7.5, color: metaColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (widget.dressCode.isNotEmpty) ...[
                              _dot(metaColor),
                              Flexible(
                                child: Text(
                                  widget.dressCode,
                                  style: GoogleFonts.inter(
                                    fontSize: 7.5,
                                    color: metaColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (widget.giftType.isNotEmpty) ...[
                              _dot(metaColor),
                              Icon(Icons.card_giftcard_rounded,
                                  size: 7, color: metaColor),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  widget.giftType,
                                  style: GoogleFonts.inter(
                                      fontSize: 7.5, color: metaColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Personal message
                      if (widget.message.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.message,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 9,
                            color: subColor,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Photo tap button (top-right corner)
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: widget.onPhotoTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasPhoto
                    ? Colors.black54
                    : widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasPhoto
                        ? Icons.edit_rounded
                        : Icons.add_photo_alternate_rounded,
                    size: 12,
                    color: hasPhoto ? Colors.white : widget.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasPhoto ? 'Change Photo' : 'Add Photo',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: hasPhoto ? Colors.white : widget.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Editor Field — WedTextField style ───────────────────────────────────────

class _EditorField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const _EditorField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.secondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            onChanged: onChanged,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
              filled: true,
              fillColor: theme.colorScheme.surface,
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.secondary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

// ─── Font helpers ─────────────────────────────────────────────────────────────

Color _categoryColor(String cat) => switch (cat) {
      'Script' => const Color(0xFF8E24AA),
      'Serif' => const Color(0xFF1565C0),
      'Modern' => const Color(0xFF00897B),
      'Decorative' => const Color(0xFFE65100),
      _ => AppColors.textSecondary,
    };

class _FontGroupHeader extends StatelessWidget {
  final String category;
  const _FontGroupHeader(this.category);

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    return Row(
      children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          '$category Fonts',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _FontCard extends StatelessWidget {
  final _FontOption font;
  final bool isSelected;
  final Color accentColor;
  final String previewText;
  final VoidCallback onTap;

  const _FontCard({
    required this.font,
    required this.isSelected,
    required this.accentColor,
    required this.previewText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _categoryColor(font.category);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.07)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    font.category,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: catColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                        color: accentColor, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 12),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              previewText,
              style: font.style(
                  17, isSelected ? accentColor : theme.colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              font.label,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Colour category row ──────────────────────────────────────────────────────

class _ColorCategoryRow extends StatelessWidget {
  final _ColorCategory category;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelect;

  const _ColorCategoryRow({
    required this.category,
    required this.selectedColor,
    required this.onColorSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: category.swatches.map((swatch) {
            final selected =
                selectedColor.toARGB32() == swatch.color.toARGB32();
            return Expanded(
              child: GestureDetector(
                onTap: () => onColorSelect(swatch.color),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: selected ? 46 : 40,
                      height: selected ? 46 : 40,
                      decoration: BoxDecoration(
                        color: swatch.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: swatch.color.withValues(
                                alpha: selected ? 0.55 : 0.2),
                            blurRadius: selected ? 12 : 4,
                          ),
                        ],
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      swatch.name,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: selected
                            ? selectedColor
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Custom colour picker ─────────────────────────────────────────────────────

void _openCustomColorPicker(
  BuildContext context,
  Color initial,
  ValueChanged<Color> onApply,
) {
  showDialog<void>(
    context: context,
    builder: (ctx) =>
        _CustomColorPickerDialog(initial: initial, onApply: onApply),
  );
}

class _CustomColorPickerDialog extends StatefulWidget {
  final Color initial;
  final ValueChanged<Color> onApply;
  const _CustomColorPickerDialog(
      {required this.initial, required this.onApply});

  @override
  State<_CustomColorPickerDialog> createState() =>
      _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<_CustomColorPickerDialog> {
  late double _r, _g, _b;

  @override
  void initState() {
    super.initState();
    _r = (widget.initial.r * 255.0).roundToDouble().clamp(0, 255);
    _g = (widget.initial.g * 255.0).roundToDouble().clamp(0, 255);
    _b = (widget.initial.b * 255.0).roundToDouble().clamp(0, 255);
  }

  Color get _current =>
      Color.fromRGBO(_r.round(), _g.round(), _b.round(), 1);

  String get _hex =>
      '#'
      '${_r.round().toRadixString(16).padLeft(2, '0')}'
      '${_g.round().toRadixString(16).padLeft(2, '0')}'
      '${_b.round().toRadixString(16).padLeft(2, '0')}'.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Custom Color', style: AppTextStyles.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _current,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _current.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _RGBSlider(
              label: 'R',
              value: _r,
              activeColor: Colors.red,
              onChanged: (v) => setState(() => _r = v)),
          _RGBSlider(
              label: 'G',
              value: _g,
              activeColor: const Color(0xFF43A047),
              onChanged: (v) => setState(() => _g = v)),
          _RGBSlider(
              label: 'B',
              value: _b,
              activeColor: Colors.blue,
              onChanged: (v) => setState(() => _b = v)),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              _hex,
              style: GoogleFonts.robotoMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _current,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _current),
          onPressed: () {
            widget.onApply(_current);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _RGBSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _RGBSlider({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: activeColor),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              thumbColor: activeColor,
              inactiveTrackColor: activeColor.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 255,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            value.round().toString(),
            style: GoogleFonts.inter(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55)),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
