import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// ---------------------------------------------------------------------------
// Providers scoped to admin management
// ---------------------------------------------------------------------------

final _privilegedUsersProvider = FutureProvider.autoDispose<List<UserProfile>>((
  ref,
) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getPrivilegedUsers();
});

final _userSearchProvider = FutureProvider.autoDispose
    .family<List<UserProfile>, String>((ref, query) async {
      if (query.trim().isEmpty) return const [];
      final repo = ref.watch(userRepositoryProvider);
      return repo.searchUsers(query.trim());
    });

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() =>
      _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final privilegedAsync = ref.watch(_privilegedUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SecondaryScreenHeader(title: 'Manage Admins'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                // ── Search users ──
                _SectionLabel(title: 'Search Users'),
                const SizedBox(height: AppSpacing.sm),
                _SearchField(
                  controller: _searchController,
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value.trim());
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                if (_searchQuery.isNotEmpty) ...[
                  _SearchResults(
                    query: _searchQuery,
                    onRoleChanged: _onRoleChanged,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Current privileged users ──
                _SectionLabel(title: 'Current Privileged Users'),
                const SizedBox(height: AppSpacing.sm),
                privilegedAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Failed to load: $e',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ),
                  data: (users) {
                    if (users.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'No privileged users found.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textHint),
                        ),
                      );
                    }
                    return Column(
                      children: users
                          .map(
                            (u) => _UserRoleCard(
                              profile: u,
                              onRoleChanged: _onRoleChanged,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRoleChanged(String uid, UserRole newRole) async {
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateUserRole(uid, newRole);

      ref.invalidate(_privilegedUsersProvider);
      if (_searchQuery.isNotEmpty) {
        ref.invalidate(_userSearchProvider(_searchQuery));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role updated to ${newRole.displayLabel}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search by name or email…',
        hintStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.onRoleChanged});

  final String query;
  final Future<void> Function(String uid, UserRole newRole) onRoleChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(_userSearchProvider(query));

    return resultsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Search failed: $e',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.error),
        ),
      ),
      data: (users) {
        if (users.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'No users found for "$query"',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${users.length} result${users.length != 1 ? "s" : ""}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...users.map(
              (u) => _UserRoleCard(profile: u, onRoleChanged: onRoleChanged),
            ),
          ],
        );
      },
    );
  }
}

class _UserRoleCard extends StatelessWidget {
  const _UserRoleCard({required this.profile, required this.onRoleChanged});

  final UserProfile profile;
  final Future<void> Function(String uid, UserRole newRole) onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final roleBadgeColor = _roleColor(profile.role);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: profile.photoURL != null
                    ? NetworkImage(profile.photoURL!)
                    : null,
                child: profile.photoURL == null
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      profile.email ?? '',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: roleBadgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  profile.role.displayLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: roleBadgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              if (profile.role != UserRole.questionAdmin)
                _RoleActionChip(
                  label: 'Make Question Admin',
                  color: AppColors.primary,
                  onTap: () =>
                      onRoleChanged(profile.uid, UserRole.questionAdmin),
                ),
              if (profile.role != UserRole.user) ...[
                if (profile.role != UserRole.questionAdmin)
                  const SizedBox(width: AppSpacing.sm),
                _RoleActionChip(
                  label: 'Revoke to User',
                  color: AppColors.error,
                  onTap: () => onRoleChanged(profile.uid, UserRole.user),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return AppColors.tertiary;
      case UserRole.questionAdmin:
        return AppColors.primary;
      case UserRole.user:
        return AppColors.textSecondary;
    }
  }
}

class _RoleActionChip extends StatelessWidget {
  const _RoleActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
