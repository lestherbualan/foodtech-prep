import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../exam/presentation/providers/dashboard_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // ── Avatar + Name ──
                Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? const Icon(Icons.person, size: 44)
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    user.displayName ?? 'Student',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    user.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    _signInMethod(user.providerData),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Stats Summary ──
                _StatsSection(userId: user.uid),

                const SizedBox(height: AppSpacing.xl),

                // ── Sign Out ──
                FilledButton.icon(
                  onPressed: () {
                    ref.read(authActionProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
    );
  }

  String _signInMethod(List providerData) {
    for (final provider in providerData) {
      if (provider.providerId == 'google.com') return 'Signed in with Google';
      if (provider.providerId == 'password') return 'Signed in with Email';
    }
    return 'Signed in';
  }
}

// ─── Stats Section ──────────────────────────────────────────────────────────

class _StatsSection extends ConsumerWidget {
  const _StatsSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider(userId));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.totalAttempts == 0) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'No exams taken yet — start your first practice!',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _StatRow(label: 'Total Exams', value: '${stats.totalAttempts}'),
              const Divider(height: AppSpacing.lg),
              _StatRow(
                label: 'Best Score',
                value: '${stats.bestScore.round()}%',
              ),
              const Divider(height: AppSpacing.lg),
              _StatRow(
                label: 'Average Score',
                value: '${stats.averageScore.round()}%',
              ),
              const Divider(height: AppSpacing.lg),
              _StatRow(
                label: 'Latest Score',
                value: '${stats.latestScore.round()}%',
              ),
              if (stats.weakestSubject != null) ...[
                const Divider(height: AppSpacing.lg),
                _StatRow(
                  label: 'Weakest Subject',
                  value: stats.weakestSubject!,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
