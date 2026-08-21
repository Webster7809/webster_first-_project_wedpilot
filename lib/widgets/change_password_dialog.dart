import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_error.dart';
import '../core/services/auth_service.dart';
import '../providers/auth_provider.dart';
import 'wed_button.dart';
import 'wed_snack_bar.dart';
import 'wed_text_field.dart';

/// Change-password dialog shared by the couple and vendor account screens.
/// Requires the current password rather than trusting the signed-in session
/// alone — see backend/routes/auth.js's rationale on POST /api/auth/change-password.
Future<void> showChangePasswordDialog(BuildContext context, WidgetRef ref) async {
  final formKey = GlobalKey<FormState>();
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  bool submitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WedTextField(
                label: 'Current password',
                controller: currentCtrl,
                isPassword: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your current password' : null,
              ),
              const SizedBox(height: 12),
              WedTextField(
                label: 'New password',
                controller: newCtrl,
                isPassword: true,
                validator: (v) =>
                    (v == null || v.length < 8) ? 'Min 8 characters' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          WedButton(
            label: 'Update',
            isLoading: submitting,
            shrinkWrap: true,
            height: 40,
            onPressed: submitting
                ? null
                : () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    setState(() => submitting = true);
                    final token = ref.read(authProvider.notifier).accessToken;
                    if (token == null) return;
                    try {
                      await AuthService.instance.changePassword(
                        accessToken: token,
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text,
                      );
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      if (context.mounted) {
                        showWedSnackBar(context, 'Password updated.', type: SnackType.success);
                      }
                    } on AuthApiException catch (e) {
                      setState(() => submitting = false);
                      if (dialogContext.mounted) {
                        showWedSnackBar(dialogContext, e.message, type: SnackType.error);
                      }
                    } catch (e) {
                      setState(() => submitting = false);
                      if (dialogContext.mounted) {
                        showWedSnackBar(dialogContext, describeError(e), type: SnackType.error);
                      }
                    }
                  },
          ),
        ],
      ),
    ),
  );
  currentCtrl.dispose();
  newCtrl.dispose();
}
