import 'dart:io';
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
  // Scripts
  _FontOption('Great Vibes', 'Script',
      (s, c) => GoogleFonts.greatVibes(fontSize: s, color: c)),
  _FontOption('Sacramento', 'Script',
      (s, c) => GoogleFonts.sacramento(fontSize: s, color: c)),
  _FontOption('Dancing Script', 'Script',
      (s, c) => GoogleFonts.dancingScript(fontSize: s, color: c, fontWeight: FontWeight.w700)),
  _FontOption('Pinyon Script', 'Script',
      (s, c) => GoogleFonts.pinyonScript(fontSize: s, color: c)),
  _FontOption('Alex Brush', 'Script',
      (s, c) => GoogleFonts.alexBrush(fontSize: s, color: c)),
  _FontOption('Allura', 'Script',
      (s, c) => GoogleFonts.allura(fontSize: s, color: c)),
  _FontOption('Tangerine', 'Script',
      (s, c) => GoogleFonts.tangerine(fontSize: s, color: c, fontWeight: FontWeight.w700)),
  _FontOption('Parisienne', 'Script',
      (s, c) => GoogleFonts.parisienne(fontSize: s, color: c)),
  // Serif
  _FontOption('Playfair Display', 'Serif',
      (s, c) => GoogleFonts.playfairDisplay(fontSize: s, color: c, fontWeight: FontWeight.bold)),
  _FontOption('Cormorant Garamond', 'Serif',
      (s, c) => GoogleFonts.cormorantGaramond(fontSize: s, color: c, fontWeight: FontWeight.w600)),
  _FontOption('Cinzel', 'Serif',
      (s, c) => GoogleFonts.cinzel(fontSize: s, color: c, fontWeight: FontWeight.w700)),
  _FontOption('EB Garamond', 'Serif',
      (s, c) => GoogleFonts.ebGaramond(fontSize: s, color: c, fontWeight: FontWeight.w600)),
  _FontOption('Lora', 'Serif',
      (s, c) => GoogleFonts.lora(fontSize: s, color: c, fontWeight: FontWeight.w600)),
  _FontOption('Bodoni Moda', 'Serif',
      (s, c) => GoogleFonts.bodoniModa(fontSize: s, color: c, fontWeight: FontWeight.w700)),
  // Modern
  _FontOption('Montserrat', 'Modern',
      (s, c) => GoogleFonts.montserrat(fontSize: s, color: c, fontWeight: FontWeight.w600)),
  _FontOption('Raleway', 'Modern',
      (s, c) => GoogleFonts.raleway(fontSize: s, color: c, fontWeight: FontWeight.w600)),
  _FontOption('Josefin Sans', 'Modern',
      (s, c) => GoogleFonts.josefinSans(fontSize: s, color: c, fontWeight: FontWeight.w600)),
  // Decorative
  _FontOption('Lobster', 'Decorative',
      (s, c) => GoogleFonts.lobster(fontSize: s, color: c)),
  _FontOption('Pacifico', 'Decorative',
      (s, c) => GoogleFonts.pacifico(fontSize: s, color: c)),
  _FontOption('Libre Baskerville', 'Decorative',
      (s, c) => GoogleFonts.libreBaskerville(fontSize: s, color: c, fontWeight: FontWeight.bold)),
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
    extends ConsumerState<InvitationEditorScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController(text: 'Alex & Jordan');
  final _subtitleCtrl =
      TextEditingController(text: 'Together with their families');
  final _dateCtrl = TextEditingController(text: 'June 14, 2027');
  final _timeCtrl = TextEditingController(text: '4:00 PM');
  final _venueCtrl =
      TextEditingController(text: 'The Garden Venue, Long Island, NY');
  final _rsvpCtrl = TextEditingController(text: 'May 1, 2027');
  final _dressCodeCtrl = TextEditingController(text: 'Black Tie Optional');
  final _msgCtrl = TextEditingController(
    text:
        'Together with their families, we joyfully invite you to share in the celebration of our marriage.',
  );

  Color _accentColor = const Color(0xFFC2185B);
  int _selectedFont = 0;
  File? _backgroundImage;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
    _rsvpCtrl.text = (data['rsvpBy'] as String?) ?? _rsvpCtrl.text;
    _dressCodeCtrl.text =
        (data['dressCode'] as String?) ?? _dressCodeCtrl.text;
    _msgCtrl.text = (data['message'] as String?) ?? _msgCtrl.text;

    final fontIndex = data['fontIndex'] as int?;
    final colorValue = data['accentColor'] as int?;
    if (fontIndex != null && fontIndex < _fontOptions.length) {
      _selectedFont = fontIndex;
    }
    if (colorValue != null) _accentColor = Color(colorValue);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _venueCtrl.dispose();
    _rsvpCtrl.dispose();
    _dressCodeCtrl.dispose();
    _msgCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildCustomData() => {
        'coupleName': _nameCtrl.text.trim(),
        'subtitle': _subtitleCtrl.text.trim(),
        'date': _dateCtrl.text.trim(),
        'time': _timeCtrl.text.trim(),
        'venue': _venueCtrl.text.trim(),
        'rsvpBy': _rsvpCtrl.text.trim(),
        'dressCode': _dressCodeCtrl.text.trim(),
        'message': _msgCtrl.text.trim(),
        'fontIndex': _selectedFont,
        'accentColor': _accentColor.toARGB32(),
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
    if (file != null) setState(() => _backgroundImage = File(file.path));
  }

  Future<void> _pickImageFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'bmp', 'gif'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _backgroundImage = File(result.files.single.path!));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Photo', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 4),
              Text('Supports JPG, PNG, WebP and more.',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.secondary),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Photos & images'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_open_rounded,
                      color: AppColors.info),
                ),
                title: const Text('Browse Files'),
                subtitle: const Text('JPG, PNG, WebP, HEIC, GIF…'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromFiles();
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.textSecondary),
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_backgroundImage != null)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error),
                  ),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _backgroundImage = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Design Your Invitation'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
        actions: [
          if (widget.invitationId != null)
            TextButton(
              onPressed: () {
                _saveEdits();
                showWedSnackBar(context, 'Saved!', type: SnackType.success);
              },
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary),
              child: const Text('Save'),
            ),
          TextButton.icon(
            onPressed: _saveAndShare,
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Share'),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.secondary),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Live preview ────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            height: keyboardOpen ? 0 : 232,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: _InvitationPreview(
              names: _nameCtrl.text,
              subtitle: _subtitleCtrl.text,
              date: _dateCtrl.text,
              time: _timeCtrl.text,
              venue: _venueCtrl.text,
              color: _accentColor,
              fontOption: _fontOptions[_selectedFont],
              backgroundImage: _backgroundImage,
              onPhotoTap: _showImageSourceSheet,
            ),
          ),

          // ── Tab bar ─────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.secondary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.secondary,
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(
                    icon: Icon(Icons.edit_rounded, size: 18),
                    text: 'Details'),
                Tab(
                    icon: Icon(Icons.font_download_rounded, size: 18),
                    text: 'Font'),
                Tab(
                    icon: Icon(Icons.palette_rounded, size: 18),
                    text: 'Style'),
              ],
            ),
          ),

          // ── Tab content ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _DetailsTab(
                    nameCtrl: _nameCtrl,
                    subtitleCtrl: _subtitleCtrl,
                    dateCtrl: _dateCtrl,
                    timeCtrl: _timeCtrl,
                    venueCtrl: _venueCtrl,
                    rsvpCtrl: _rsvpCtrl,
                    dressCodeCtrl: _dressCodeCtrl,
                    msgCtrl: _msgCtrl,
                    onChanged: () => setState(() {}),
                    onPhotoTap: _showImageSourceSheet,
                    hasPhoto: _backgroundImage != null,
                  ),
                  _FontTab(
                    selectedIndex: _selectedFont,
                    accentColor: _accentColor,
                    previewText: _nameCtrl.text,
                    onSelect: (i) => setState(() => _selectedFont = i),
                  ),
                  _StyleTab(
                    selectedColor: _accentColor,
                    onColorSelect: (c) => setState(() => _accentColor = c),
                    onShareLink: _saveAndShare,
                    onExportPdf: () => showWedSnackBar(
                        context, 'PDF generated!',
                        type: SnackType.success),
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

// ─── Live Preview ───────────────────────────────────────────────────────────

class _InvitationPreview extends StatelessWidget {
  final String names, subtitle, date, time, venue;
  final Color color;
  final _FontOption fontOption;
  final File? backgroundImage;
  final VoidCallback onPhotoTap;

  const _InvitationPreview({
    required this.names,
    required this.subtitle,
    required this.date,
    required this.time,
    required this.venue,
    required this.color,
    required this.fontOption,
    required this.onPhotoTap,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = backgroundImage != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      height: 208,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (hasPhoto)
              Positioned.fill(
                  child: Image.file(backgroundImage!, fit: BoxFit.cover)),
            if (hasPhoto)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.45),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.06),
                        color.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

            // Accent border
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: color.withValues(alpha: 0.3), width: 1.5),
                ),
              ),
            ),

            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subtitle.isEmpty
                          ? 'Together with their families'
                          : subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 1.5,
                        color: hasPhoto
                            ? Colors.white.withValues(alpha: 0.85)
                            : color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      names.isEmpty ? 'Couple Names' : names,
                      style: fontOption.style(
                          24, hasPhoto ? Colors.white : color),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 1,
                          color: (hasPhoto ? Colors.white : color)
                              .withValues(alpha: 0.5),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.favorite_rounded,
                              size: 10,
                              color: hasPhoto ? Colors.white : color),
                        ),
                        Container(
                          width: 28,
                          height: 1,
                          color: (hasPhoto ? Colors.white : color)
                              .withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${date.isEmpty ? 'Date' : date} · ${time.isEmpty ? 'Time' : time}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasPhoto ? Colors.white : color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      venue.isEmpty ? 'Venue' : venue,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: hasPhoto
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Photo button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onPhotoTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasPhoto
                        ? Colors.black54
                        : color.withValues(alpha: 0.12),
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
                        color: hasPhoto ? Colors.white : color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasPhoto ? 'Change Photo' : 'Add Photo',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: hasPhoto ? Colors.white : color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Details Tab ─────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final TextEditingController nameCtrl,
      subtitleCtrl,
      dateCtrl,
      timeCtrl,
      venueCtrl,
      rsvpCtrl,
      dressCodeCtrl,
      msgCtrl;
  final VoidCallback onChanged;
  final VoidCallback onPhotoTap;
  final bool hasPhoto;

  const _DetailsTab({
    required this.nameCtrl,
    required this.subtitleCtrl,
    required this.dateCtrl,
    required this.timeCtrl,
    required this.venueCtrl,
    required this.rsvpCtrl,
    required this.dressCodeCtrl,
    required this.msgCtrl,
    required this.onChanged,
    required this.onPhotoTap,
    required this.hasPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Photo import button
        GestureDetector(
          onTap: onPhotoTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: hasPhoto
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.secondary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasPhoto ? AppColors.success : AppColors.secondary,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasPhoto
                      ? Icons.check_circle_rounded
                      : Icons.add_photo_alternate_rounded,
                  color:
                      hasPhoto ? AppColors.success : AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  hasPhoto
                      ? 'Photo added — tap to change'
                      : 'Import a Photo for Your Card',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasPhoto
                        ? AppColors.success
                        : AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        _SectionLabel('Couple'),
        _EditorField(
            label: 'Couple Names',
            icon: Icons.favorite_rounded,
            controller: nameCtrl,
            onChanged: (_) => onChanged()),
        _EditorField(
            label: 'Opening Line',
            icon: Icons.format_quote_rounded,
            controller: subtitleCtrl,
            onChanged: (_) => onChanged()),

        const SizedBox(height: 4),
        _SectionLabel('Event Details'),
        _EditorField(
            label: 'Wedding Date',
            icon: Icons.calendar_today_rounded,
            controller: dateCtrl,
            onChanged: (_) => onChanged()),
        _EditorField(
            label: 'Time',
            icon: Icons.schedule_rounded,
            controller: timeCtrl,
            onChanged: (_) => onChanged()),
        _EditorField(
            label: 'Venue',
            icon: Icons.location_on_rounded,
            controller: venueCtrl,
            onChanged: (_) => onChanged()),
        _EditorField(
            label: 'RSVP By',
            icon: Icons.reply_rounded,
            controller: rsvpCtrl,
            onChanged: (_) => onChanged()),
        _EditorField(
            label: 'Dress Code',
            icon: Icons.checkroom_rounded,
            controller: dressCodeCtrl,
            onChanged: (_) => onChanged()),

        const SizedBox(height: 4),
        _SectionLabel('Message'),
        _EditorField(
            label: 'Personal Message',
            icon: Icons.message_rounded,
            controller: msgCtrl,
            maxLines: 3,
            onChanged: (_) => onChanged()),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(icon, size: 18, color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.secondary, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

// ─── Font Tab ────────────────────────────────────────────────────────────────

Color _categoryColor(String cat) => switch (cat) {
      'Script' => const Color(0xFF8E24AA),
      'Serif' => const Color(0xFF1565C0),
      'Modern' => const Color(0xFF00897B),
      'Decorative' => const Color(0xFFE65100),
      _ => AppColors.textSecondary,
    };

class _FontTab extends StatelessWidget {
  final int selectedIndex;
  final Color accentColor;
  final String previewText;
  final ValueChanged<int> onSelect;

  const _FontTab({
    required this.selectedIndex,
    required this.accentColor,
    required this.previewText,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<(int, _FontOption)>>{};
    for (int i = 0; i < _fontOptions.length; i++) {
      final f = _fontOptions[i];
      groups.putIfAbsent(f.category, () => []).add((i, f));
    }
    final displayName =
        previewText.trim().isEmpty ? 'Alex & Jordan' : previewText;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final entry in groups.entries) ...[
          _FontGroupHeader(entry.key),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              for (final (idx, font) in entry.value)
                _FontCard(
                  font: font,
                  isSelected: idx == selectedIndex,
                  accentColor: accentColor,
                  previewText: displayName,
                  onTap: () => onSelect(idx),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _FontGroupHeader extends StatelessWidget {
  final String category;
  const _FontGroupHeader(this.category);

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
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
    final catColor = _categoryColor(font.category);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.divider,
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
                    width: 18,
                    height: 18,
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
                  17, isSelected ? accentColor : AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              font.label,
              style: GoogleFonts.inter(
                  fontSize: 9, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Style Tab ───────────────────────────────────────────────────────────────

class _StyleTab extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelect;
  final VoidCallback onShareLink;
  final VoidCallback onExportPdf;

  const _StyleTab({
    required this.selectedColor,
    required this.onColorSelect,
    required this.onShareLink,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text('Style Colour', style: AppTextStyles.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Sets the primary colour for text and decorations on your invitation.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 16),

        for (final category in _colorCategories) ...[
          _ColorCategoryRow(
            category: category,
            selectedColor: selectedColor,
            onColorSelect: onColorSelect,
          ),
          const SizedBox(height: 16),
        ],

        // Custom colour picker entry
        GestureDetector(
          onTap: () =>
              _openCustomColorPicker(context, selectedColor, onColorSelect),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
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
                      Text('Mix your own with RGB controls',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 20),

        Text('Share & Export', style: AppTextStyles.labelLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: WedButton(
                label: 'Share Link',
                variant: WedButtonVariant.secondary,
                onPressed: onShareLink,
                icon: Icons.link_rounded,
                height: 48,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WedButton(
                label: 'Export PDF',
                variant: WedButtonVariant.secondary,
                onPressed: onExportPdf,
                icon: Icons.picture_as_pdf_outlined,
                height: 48,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
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
                            : AppColors.textSecondary,
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
    return AlertDialog(
      title: Text('Custom Color', style: AppTextStyles.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 72,
              height: 72,
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
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
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
                fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
