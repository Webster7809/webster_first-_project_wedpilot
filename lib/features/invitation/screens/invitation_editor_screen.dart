import 'dart:math' show min;
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
import '../../../widgets/wed_text_field.dart';

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

const _cardThemeColors = [
  Color(0xFF1B3A2D), // Forest green
  Color(0xFF00695C), // Deep teal
  Color(0xFF8B1A1A), // Wine/crimson
  Color(0xFF4A148C), // Deep purple
  Color(0xFFBF360C), // Deep orange
];

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

  // Editor panel & image transform state
  int _selectedTab = 0; // 0=Photo 1=Text 2=Font 3=Color 4=Layout
  Color _cardBgColor = AppColors.forestGreen;
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
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _backgroundImageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      showWedSnackBar(
        context,
        'Could not load image. Please check permissions and try again.',
        type: SnackType.error,
      );
    }
  }

  Future<void> _pickImageFromFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'bmp', 'gif'],
        withData: true,
      );
      if (result == null || !mounted) return;
      final bytes = result.files.single.bytes;
      if (bytes != null) setState(() => _backgroundImageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      showWedSnackBar(
        context,
        'Could not load image from files. Please try again.',
        type: SnackType.error,
      );
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
                    style: AppTextStyles.titleMedium.copyWith(
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
              color: color.withAlpha(23),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () {
            _saveEdits();
            Navigator.maybePop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1.5),
              color: Colors.white,
            ),
            child: const Icon(Icons.chevron_left_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
        ),
      ),
      title: Text(
        'INVITATION CARD',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
          color: AppColors.amber,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            onPressed: _saveAndShare,
            icon: const Icon(Icons.share_rounded, size: 14),
            label: Text(
              'Share',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (_, constraints) {
          final w = constraints.maxWidth;
          Widget body;
          if (w >= 700) {
            body = _buildWideLayout(theme, w);
          } else {
            body = _buildNarrowLayout(theme, w);
          }
          // Centre-cap content on large desktop screens
          if (w >= 900) {
            body = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: body,
              ),
            );
          }
          return body;
        },
      ),
    );
  }

  // ── Narrow (mobile) — portrait card + tab chips + scrollable content card ──
  Widget _buildNarrowLayout(ThemeData theme, double screenWidth) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final cardMaxHeight = (screenHeight * 0.40).clamp(180.0, 400.0);
    final cardWidth = screenWidth - 40.0;
    final cardHeight = (cardWidth * (4 / 3)).clamp(0.0, cardMaxHeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card preview — floats on cream background
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Center(
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(46),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: cardHeight,
                  child: _buildPreview(),
                ),
              ),
            ),
          ),
        ),
        // Tab chips — individual floating chips on cream background with gaps
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildTabBar(theme),
        ),
        const SizedBox(height: 10),
        // Content card — separate white rounded card, cream visible on sides
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: _buildTabContent(theme),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Wide (tablet / desktop) — preview left, editor panel right ──────────
  Widget _buildWideLayout(ThemeData theme, double screenWidth) {
    const editorWidth = 420.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview panel — cream background, portrait card centred
        Expanded(
          child: Container(
            color: AppColors.cream,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: 340, maxHeight: 480),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildPreview(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Editor panel — white, fixed width, always scrollable
        Container(
          width: editorWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 12,
                offset: const Offset(-3, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _buildTabBar(theme),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildTabContent(theme),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab bar — individual floating chips on cream background ─────────────
  Widget _buildTabBar(ThemeData theme) {
    const tabs = [
      (icon: Icons.camera_alt_rounded, label: 'Photo'),
      (icon: Icons.text_fields_rounded, label: 'Text'),
      (icon: Icons.draw_rounded, label: 'Font'),
      (icon: Icons.color_lens_rounded, label: 'Color'),
      (icon: Icons.grid_view_rounded, label: 'Layout'),
    ];
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _selectedTab == i
                      ? AppColors.forestGreen
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[i].icon,
                      size: 20,
                      color: _selectedTab == i
                          ? AppColors.amber
                          : theme.colorScheme.onSurface.withAlpha(153),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tabs[i].label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == i
                            ? AppColors.amber
                            : theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Tab content dispatch ──────────────────────────────────────────────────
  Widget _buildTabContent(ThemeData theme) {
    return switch (_selectedTab) {
      0 => _buildPhotoTabContent(theme),
      1 => _buildDetailsContent(theme),
      2 => _buildFontContent(theme),
      3 => _buildStyleContent(theme),
      _ => _buildLayoutTabContent(theme),
    };
  }

  // ── Photo tab: camera / gallery / files picker ────────────────────────────
  Widget _buildPhotoTabContent(ThemeData theme) {
    final hasPhoto = _backgroundImageBytes != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Background Photo',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a photo to use as your invitation background.',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _photoOptionButton(
                context,
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: _accentColor,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              _photoOptionButton(
                context,
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: _accentColor,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              _photoOptionButton(
                context,
                icon: Icons.folder_open_rounded,
                label: 'Files',
                color: _accentColor,
                onTap: () => _pickImageFromFiles(),
              ),
            ],
          ),
          if (hasPhoto) ...[
            const SizedBox(height: 20),
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
                          color: _accentColor.withAlpha(26),
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
                      inactiveTrackColor: _accentColor.withAlpha(51),
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
                      onChanged: (v) => setState(() => _imageScale = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('50%',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: theme.colorScheme.onSurface
                                  .withAlpha(102))),
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
                                  .withAlpha(102))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pinch to zoom • drag to reposition',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withAlpha(115),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _backgroundImageBytes = null),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withAlpha(77)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Remove Photo',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Layout tab: card background colour ───────────────────────────────────
  Widget _buildLayoutTabContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Background',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Background colour used when no photo is set.',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final clr in _cardThemeColors)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _cardBgColor = clr),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: clr,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _cardBgColor.toARGB32() == clr.toARGB32()
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: clr.withAlpha(
                                _cardBgColor.toARGB32() == clr.toARGB32()
                                    ? 100
                                    : 40),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: _cardBgColor.toARGB32() == clr.toARGB32()
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
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
        cardBgColor: _cardBgColor,
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

  // ── Details content ───────────────────────────────────────────────────────
  Widget _buildDetailsContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel('Couple'),
          _fieldPad(WedTextField(
            label: 'Couple Names',
            prefixIcon: Icons.favorite_rounded,
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
          )),
          _fieldPad(WedTextField(
            label: 'Opening Line',
            prefixIcon: Icons.format_quote_rounded,
            controller: _subtitleCtrl,
            onChanged: (_) => setState(() {}),
          )),

          _SectionLabel('Ceremony'),
          _fieldPad(WedTextField(
            label: 'Church / Ceremony Venue',
            prefixIcon: Icons.church_rounded,
            controller: _venueCtrl,
            onChanged: (_) => setState(() {}),
          )),
          _fieldPad(WedTextField(
            label: 'Wedding Date',
            prefixIcon: Icons.calendar_today_rounded,
            controller: _dateCtrl,
            onChanged: (_) => setState(() {}),
          )),
          _fieldPad(WedTextField(
            label: 'Ceremony Time',
            prefixIcon: Icons.schedule_rounded,
            controller: _timeCtrl,
            onChanged: (_) => setState(() {}),
          )),
          _fieldPad(WedTextField(
            label: 'Church Service Theme / Talk',
            prefixIcon: Icons.record_voice_over_rounded,
            controller: _churchThemeCtrl,
            onChanged: (_) => setState(() {}),
          )),
          _fieldPad(WedTextField(
            label: 'Church Service Time',
            prefixIcon: Icons.access_time_rounded,
            controller: _churchTimeCtrl,
            onChanged: (_) => setState(() {}),
          )),

          _SectionLabel('Reception'),
          _fieldPad(WedTextField(
            label: 'Reception Venue',
            prefixIcon: Icons.location_on_rounded,
            controller: _receptionVenueCtrl,
            onChanged: (_) => setState(() {}),
          )),

          _SectionLabel('RSVP & Gifts'),
          _fieldPad(WedTextField(
            label: 'RSVP By Date',
            prefixIcon: Icons.event_available_rounded,
            controller: _rsvpCtrl,
            onChanged: (_) => setState(() {}),
          )),
          _fieldPad(WedTextField(
            label: 'Contact Number',
            prefixIcon: Icons.phone_rounded,
            controller: _contactCtrl,
            onChanged: (_) => setState(() {}),
          )),
          _fieldPad(WedTextField(
            label: 'Dress Code',
            prefixIcon: Icons.checkroom_rounded,
            controller: _dressCodeCtrl,
            onChanged: (_) => setState(() {}),
          )),
          _fieldPad(WedTextField(
            label: 'Gift Type',
            prefixIcon: Icons.card_giftcard_rounded,
            controller: _giftTypeCtrl,
            onChanged: (_) => setState(() {}),
          )),

          _SectionLabel('Message'),
          _fieldPad(WedTextField(
            label: 'Personal Message',
            prefixIcon: Icons.message_rounded,
            controller: _msgCtrl,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          )),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                            .withAlpha(140),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _accentColor.withAlpha(26),
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
                                .withAlpha(76),
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
                              _accentColor.withAlpha(51),
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
                                .withAlpha(76),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Style Colour', style: AppTextStyles.labelLarge),
          const SizedBox(height: 4),
          Text(
            'Sets the primary colour for text and decorations on your invitation.',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
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
                                .withAlpha(140),
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
                          .withAlpha(102)),
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

// ─── Live Preview ─────────────────────────────────────────────────────────────

class _InvitationPreview extends StatefulWidget {
  final String names, subtitle, date, time, venue, receptionVenue, rsvpBy,
      contact, dressCode, message, churchTheme, churchTime, giftType;
  final Color color;
  final Color cardBgColor;
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
    required this.cardBgColor,
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

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.backgroundImageBytes != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── No-photo: dark themed card ──────────────────────────────────
        if (!hasPhoto) ...[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.cardBgColor,
                    _darkenColor(widget.cardBgColor, 0.22),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Decorative accent circle ring
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (_, bc) {
                  final sz = bc.maxWidth * 0.84;
                  return Align(
                    alignment: const Alignment(0, -0.08),
                    child: SizedBox(
                      width: sz,
                      height: sz,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.color.withAlpha(110),
                            width: 0.9,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Card content
          Positioned.fill(child: _buildDarkCardContent()),
        ],

        // ── Photo mode ──────────────────────────────────────────────────
        if (hasPhoto) ...[
          Positioned.fill(child: Container(color: Colors.white)),
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
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withAlpha(115),
                      Colors.black.withAlpha(128),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10, left: 16, right: 16,
            child: IgnorePointer(
              child: Center(
                child: FittedBox(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(107),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_with_rounded,
                            size: 10, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Pinch to zoom • drag to reposition',
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
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(height: 3, color: widget.color),
          ),
          // Photo-mode text overlay — all invitation details
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (_, bc) {
                  final w = bc.maxWidth;
                  final h = bc.maxHeight;
                  final accent = widget.color;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                        w * 0.07, h * 0.05, w * 0.07, h * 0.12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w * 0.86),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Opening line
                            Text(
                              widget.subtitle.isEmpty
                                  ? 'Together with their families'
                                  : widget.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                letterSpacing: 1.5,
                                color: Colors.white.withAlpha(220),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            // Names in selected script font
                            Text(
                              widget.names.isEmpty ? 'Couple Names' : widget.names,
                              style: widget.fontOption.style(widget.fontSize, Colors.white),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 7),
                            Container(width: 40, height: 0.9, color: accent.withAlpha(210)),
                            const SizedBox(height: 7),
                            // Date + Time
                            Text(
                              [
                                if (widget.date.isNotEmpty) widget.date.toUpperCase(),
                                if (widget.time.isNotEmpty) widget.time,
                              ].join('  •  '),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Church service time
                            if (widget.churchTime.isNotEmpty &&
                                widget.churchTime != widget.time) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Church Service: ${widget.churchTime}',
                                style: GoogleFonts.inter(
                                  fontSize: 7.5,
                                  color: Colors.white.withAlpha(190),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            // Ceremony venue
                            if (widget.venue.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.venue,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: Colors.white.withAlpha(200),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // Church theme
                            if (widget.churchTheme.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                '"${widget.churchTheme}"',
                                style: GoogleFonts.inter(
                                  fontSize: 7.5,
                                  fontStyle: FontStyle.italic,
                                  color: accent.withAlpha(220),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // Reception venue
                            if (widget.receptionVenue.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'RECEPTION',
                                style: GoogleFonts.inter(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.8,
                                  color: accent.withAlpha(230),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.receptionVenue,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: Colors.white.withAlpha(200),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // Personal message
                            if (widget.message.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.message,
                                style: GoogleFonts.inter(
                                  fontSize: 7.5,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white.withAlpha(180),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(width: 30, height: 0.6, color: accent.withAlpha(150)),
                            const SizedBox(height: 6),
                            // RSVP
                            if (widget.rsvpBy.isNotEmpty)
                              Text(
                                'RSVP BY ${widget.rsvpBy.toUpperCase()}',
                                style: GoogleFonts.inter(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: Colors.white.withAlpha(210),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            // Dress code
                            if (widget.dressCode.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.dressCode,
                                style: GoogleFonts.inter(
                                  fontSize: 7.5,
                                  color: Colors.white.withAlpha(190),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // Gift type
                            if (widget.giftType.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.giftType,
                                style: GoogleFonts.inter(
                                  fontSize: 7.5,
                                  color: Colors.white.withAlpha(175),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // Contact
                            if (widget.contact.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.contact,
                                style: GoogleFonts.inter(
                                  fontSize: 7.5,
                                  color: Colors.white.withAlpha(190),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

      ],
    );
  }

  // ── Dark card content (no-photo mode) ────────────────────────────────────
  Widget _buildDarkCardContent() {
    final accent = widget.color;
    final names = widget.names.isEmpty ? 'Chanda & Mwila' : widget.names;
    final parts =
        names.contains(' & ') ? names.split(' & ') : <String>[names];

    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Scale fonts to card dimensions — cap nameSz by height so tall cards
        // don't push names beyond what the column can fit.
        final nameSz = (widget.fontSize * (w / 180.0)).clamp(22.0, min(52.0, h * 0.13)).toDouble();
        final andSz = (nameSz * 0.68).clamp(16.0, 36.0);
        final labelSz = (w * 0.030).clamp(8.0, 14.0);
        final venueSz = (w * 0.026).clamp(7.0, 12.0);
        final rsvpSz = (w * 0.028).clamp(7.0, 12.0);
        final vGap = h * 0.038;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.07, vertical: h * 0.05),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: w * 0.86),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
              // Subtitle — small accent uppercase
              Text(
                (widget.subtitle.isEmpty
                        ? 'Together with their families'
                        : widget.subtitle)
                    .toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: labelSz,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.2,
                  color: accent,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: vGap),

              // Name 1
              Text(
                parts[0],
                style: widget.fontOption.style(nameSz, Colors.white),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // "&" in accent + Name 2
              if (parts.length == 2) ...[
                Text(
                  '&',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: andSz,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  parts[1],
                  style: widget.fontOption.style(nameSz, Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: vGap),
              // Accent horizontal divider
              Container(width: 36, height: 0.8, color: accent.withAlpha(204)),
              SizedBox(height: vGap * 0.9),

              // Date — uppercase bold white
              Text(
                (widget.date.isEmpty ? 'Wedding Date' : widget.date)
                    .toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: labelSz,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Venue — lighter white
              if (widget.venue.isNotEmpty) ...[
                SizedBox(height: vGap * 0.45),
                Text(
                  widget.venue,
                  style: GoogleFonts.inter(
                    fontSize: venueSz,
                    color: Colors.white.withAlpha(178),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: vGap * 1.6),
              // RSVP NOW — outlined accent pill button
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.075, vertical: h * 0.018),
                decoration: BoxDecoration(
                  border: Border.all(color: accent.withAlpha(204), width: 1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'RSVP NOW',
                  style: GoogleFonts.inter(
                    fontSize: rsvpSz,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ],
          ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _darkenColor(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

// Adds consistent bottom spacing between form fields.
Widget _fieldPad(Widget field) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: field);

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
          color: theme.colorScheme.onSurface.withAlpha(115),
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
              ? accentColor.withAlpha(18)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withAlpha(38),
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
                    color: catColor.withAlpha(31),
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
                  color: theme.colorScheme.onSurface.withAlpha(128)),
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
            color: theme.colorScheme.onSurface.withAlpha(128),
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
                                .withAlpha(140),
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
                    color: _current.withAlpha(115),
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
              inactiveTrackColor: activeColor.withAlpha(51),
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
                    .withAlpha(140)),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
