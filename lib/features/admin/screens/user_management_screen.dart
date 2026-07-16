import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_utils.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/highlighted_text.dart';
import '../../../widgets/typeahead_field.dart';
import '../../../widgets/wed_avatar.dart';
import '../../../widgets/wed_snack_bar.dart';

List<AdminUser> filterAdminUsers(
  List<AdminUser> users,
  String query,
  String roleFilter,
) {
  final q = query.toLowerCase();
  return users.where((u) {
    final matchesFilter = roleFilter == 'All' || u.role == roleFilter.toLowerCase();
    final matchesSearch = q.isEmpty ||
        u.name.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q);
    return matchesFilter && matchesSearch;
  }).toList();
}

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _confirmToggleSuspend(BuildContext context, AdminUser user) {
    final action = user.isSuspended ? 'unsuspend' : 'suspend';
    final actionLabel = user.isSuspended ? 'Unsuspend' : 'Suspend';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$actionLabel account?'),
        content: Text(
          user.isSuspended
              ? '${user.name} will be restored to active status.'
              : '${user.name} will no longer be able to log in.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final token = ref.read(authProvider.notifier).accessToken;
              if (token == null) return;
              try {
                await AdminApiService.instance.setUserSuspended(
                  token,
                  user.id,
                  !user.isSuspended,
                );
                ref.invalidate(adminUsersProvider);
                if (context.mounted) {
                  showWedSnackBar(
                    context,
                    '${user.name} ${action}ed.',
                    type: user.isSuspended
                        ? SnackType.success
                        : SnackType.warning,
                  );
                }
              } on AdminApiException catch (e) {
                if (context.mounted) {
                  showWedSnackBar(context, e.message, type: SnackType.error);
                }
              }
            },
            child: Text(
              actionLabel,
              style: TextStyle(
                color: user.isSuspended ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          'This will permanently remove ${user.name}. This cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final token = ref.read(authProvider.notifier).accessToken;
              if (token == null) return;
              try {
                await AdminApiService.instance.deleteUser(token, user.id);
                ref.invalidate(adminUsersProvider);
                if (context.mounted) {
                  showWedSnackBar(
                    context,
                    '${user.name} deleted.',
                    type: SnackType.error,
                  );
                }
              } on AdminApiException catch (e) {
                if (context.mounted) {
                  showWedSnackBar(context, e.message, type: SnackType.error);
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(user.name),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProfileRow(label: 'Email', value: user.email),
            const SizedBox(height: 8),
            _ProfileRow(
              label: 'Role',
              value: user.role[0].toUpperCase() + user.role.substring(1),
            ),
            const SizedBox(height: 8),
            _ProfileRow(
              label: 'Status',
              value: user.isSuspended ? 'Suspended' : 'Active',
            ),
            const SizedBox(height: 8),
            _ProfileRow(label: 'Joined', value: fmtRelativeTime(user.joinedAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider).valueOrNull ?? [];

    final filtered = filterAdminUsers(users, _searchCtrl.text, _filter);

    return Scaffold(
      backgroundColor: AppColors.adminPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.divider,
        title: Text(
          'User Management',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${users.length} users',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter ─────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TypeaheadField<AdminUser>(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  hint: 'Search by name or email…',
                  prefixIcon: Icons.search,
                  fillColor: AppColors.adminPage,
                  onChanged: (_) => setState(() {}),
                  suggestionsCallback: (q) =>
                      filterAdminUsers(users, q, _filter).take(8).toList(),
                  displayStringForOption: (u) => u.name,
                  onSelected: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Couple', 'Vendor', 'Admin'].map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: selected ? AppColors.adminIndigo : AppColors.adminPage,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setState(() => _filter = f),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              child: Text(
                                f,
                                style: AppTextStyles.caption.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.adminNeutralBg),

          // ── User List ───────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_search_rounded,
                          size: 56,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No users found',
                          style: AppTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try adjusting your search or filter.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: AppColors.adminNeutralBg,
                    ),
                    itemBuilder: (ctx, i) {
                      final user = filtered[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: ColorFiltered(
                          colorFilter: user.isSuspended
                              ? const ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.saturation,
                                )
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                ),
                          child: WedAvatar(
                            imageUrl: user.photoUrl,
                            name: user.name,
                            radius: 22,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: HighlightedText(
                                text: user.name,
                                query: _searchCtrl.text,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: user.isSuspended
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user.isSuspended)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.adminRedBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Suspended',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: HighlightedText(
                          text:
                              '${user.email}  ·  Joined ${fmtRelativeTime(user.joinedAt)}',
                          query: _searchCtrl.text,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RoleBadge(role: user.role),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              onSelected: (action) {
                                switch (action) {
                                  case 'view':
                                    _showUserDetails(context, user);
                                    break;
                                  case 'suspend':
                                    _confirmToggleSuspend(context, user);
                                    break;
                                  case 'delete':
                                    _confirmDelete(context, user);
                                    break;
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Text('View Profile'),
                                ),
                                PopupMenuItem(
                                  value: 'suspend',
                                  child: Text(
                                    user.isSuspended
                                        ? 'Unsuspend Account'
                                        : 'Suspend Account',
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete Account',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Role Badge ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color => switch (role) {
    'admin' => AppColors.adminIndigo,
    'vendor' => AppColors.adminBlue,
    _ => AppColors.adminGreen,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: AppTextStyles.caption.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Profile Row ───────────────────────────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
