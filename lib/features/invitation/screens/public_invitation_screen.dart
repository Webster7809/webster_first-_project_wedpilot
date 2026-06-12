import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

class PublicInvitationScreen extends StatefulWidget {
  final String shareToken;
  const PublicInvitationScreen({super.key, required this.shareToken});

  @override
  State<PublicInvitationScreen> createState() => _PublicInvitationScreenState();
}

class _PublicInvitationScreenState extends State<PublicInvitationScreen> {
  final _nameCtrl = TextEditingController();
  String _attending = 'yes';
  int _guestCount = 1;
  String _meal = 'Standard';
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _submitted ? _ThankYouView() : Column(
            children: [
              const SizedBox(height: 20),
              // Invitation preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [BoxShadow(color: AppColors.secondary.withAlpha(31), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    const Text('💍', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text('Alex & Jordan', style: AppTextStyles.displayMedium.copyWith(color: AppColors.secondary)),
                    const SizedBox(height: 6),
                    Text('Are getting married!', style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
                    const Divider(height: 24),
                    Text('June 14, 2027 at 4:00 PM', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 4),
                    Text('The Garden Venue · Long Island, NY',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('RSVP', style: AppTextStyles.displaySmall),
              const SizedBox(height: 4),
              Text('Please respond by May 1, 2027',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  hint: Text('Full name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Will you attend?', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: ['yes', 'no', 'maybe'].map((opt) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setState(() => _attending = opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _attending == opt ? AppColors.secondary : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _attending == opt ? AppColors.secondary : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          opt == 'yes' ? '✅ Yes' : opt == 'no' ? '❌ No' : '🤔 Maybe',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: _attending == opt ? Colors.white : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),
              if (_attending == 'yes') ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Number of guests', style: AppTextStyles.labelLarge),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () { if (_guestCount > 1) setState(() => _guestCount--); }),
                        Text('$_guestCount', style: AppTextStyles.headlineSmall),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _guestCount++)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _meal,
                  decoration: InputDecoration(labelText: 'Meal Preference', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: ['Standard', 'Vegetarian', 'Vegan', 'Halal', 'Gluten-free']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _meal = v!),
                ),
              ],
              const SizedBox(height: 24),
              WedButton(
                label: 'Send RSVP 💌',
                onPressed: () {
                  if (_nameCtrl.text.isEmpty) {
                    showWedSnackBar(context, 'Please enter your name', type: SnackType.warning);
                    return;
                  }
                  setState(() => _submitted = true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThankYouView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const Text('🎉', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          Text('Thank You!', style: AppTextStyles.displayMedium),
          const SizedBox(height: 12),
          Text(
            'Your RSVP has been received.\nAlex & Jordan can\'t wait to celebrate with you!',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
