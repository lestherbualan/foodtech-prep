import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../exam/domain/exam_subject.dart';
import '../../../exam/presentation/providers/dashboard_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final permissions = ref.watch(userPermissionsProvider);
    final role = ref.watch(userRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SecondaryScreenHeader(title: 'Profile'),
          if (user == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  // ── 1. Compact profile summary card ──
                  _ProfileSummaryCard(
                    displayName: user.displayName ?? 'Student',
                    email: user.email ?? '',
                    photoURL: user.photoURL,
                    providerData: user.providerData,
                    role: role,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── 2. Study stats grid ──
                  _StudyStatsSection(userId: user.uid),

                  const SizedBox(height: AppSpacing.lg),

                  // ── 3. Subject insight card ──
                  _SubjectInsightSection(userId: user.uid),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Admin: Reported Questions ──
                  if (permissions.canViewReports)
                    _AdminReportButton(
                      onTap: () => context.push(RouteNames.reportList),
                    ),

                  // ── Super Admin: Manage Users ──
                  if (permissions.canManageAdmins) ...[
                    const SizedBox(height: AppSpacing.sm + 2),
                    _AdminManageButton(
                      onTap: () => context.push(RouteNames.adminManagement),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // ── Debug: Push notification testing (super_admin only) ──
                  if (role == UserRole.superAdmin) ...[
                    _DebugNotificationSection(uid: user.uid),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // ── 4. Sign out — calmer treatment ──
                  _SignOutButton(
                    onTap: () {
                      ref.read(authActionProvider.notifier).signOut();
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. Profile summary card — compact, elegant
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.displayName,
    required this.email,
    required this.photoURL,
    required this.providerData,
    required this.role,
  });

  final String displayName;
  final String email;
  final String? photoURL;
  final List providerData;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Avatar ──
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 2.5,
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundImage: photoURL != null
                  ? NetworkImage(photoURL!)
                  : null,
              child: photoURL == null
                  ? const Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: Colors.white70,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // ── Name + email + provider badge ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        _signInMethod(providerData),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    if (role != UserRole.user) ...[
                      const SizedBox(width: AppSpacing.xs + 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                        ),
                        child: Text(
                          role.displayLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10.5,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _signInMethod(List providerData) {
    for (final provider in providerData) {
      if (provider.providerId == 'google.com') return 'Google';
      if (provider.providerId == 'password') return 'Email';
    }
    return 'Signed in';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. Study stats — 2×2 grid
// ═══════════════════════════════════════════════════════════════════════════════

class _StudyStatsSection extends ConsumerWidget {
  const _StudyStatsSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider(userId));

    return statsAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.totalAttempts == 0) {
          return _EmptyCard(text: 'Take your first exam to see stats here.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(title: 'Study Performance'),
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Total Exams',
                    value: '${stats.totalAttempts}',
                    icon: Icons.assignment_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: _StatTile(
                    label: 'Best Score',
                    value: '${stats.bestScore.round()}%',
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Average',
                    value: '${stats.averageScore.round()}%',
                    icon: Icons.analytics_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: _StatTile(
                    label: 'Latest',
                    value: '${stats.latestScore.round()}%',
                    icon: Icons.update_rounded,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. Subject insight card — strongest / weakest
// ═══════════════════════════════════════════════════════════════════════════════

class _SubjectInsightSection extends ConsumerWidget {
  const _SubjectInsightSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider(userId));

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.strongestSubject == null && stats.weakestSubject == null) {
          return const SizedBox.shrink();
        }

        final strongAbbr = stats.strongestSubject != null
            ? ExamSubject.abbreviate(stats.strongestSubject!)
            : null;
        final weakAbbr = stats.weakestSubject != null
            ? ExamSubject.abbreviate(stats.weakestSubject!)
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(title: 'Subject Focus'),
            const SizedBox(height: AppSpacing.sm + 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md + 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (strongAbbr != null)
                    _InsightRow(
                      icon: Icons.star_rounded,
                      label: 'Strongest',
                      value: strongAbbr,
                      color: AppColors.success,
                    ),
                  if (strongAbbr != null && weakAbbr != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Divider(
                        height: 1,
                        color: AppColors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                  if (weakAbbr != null)
                    _InsightRow(
                      icon: Icons.trending_down_rounded,
                      label: 'Needs Work',
                      value: weakAbbr,
                      color: AppColors.warning,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Admin — Reported Questions entry point
// ═══════════════════════════════════════════════════════════════════════════════

class _AdminReportButton extends StatelessWidget {
  const _AdminReportButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.flag_outlined, size: 18, color: AppColors.warning),
      label: Text(
        'Reported Questions',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: AppColors.warning),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

class _AdminManageButton extends StatelessWidget {
  const _AdminManageButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(
        Icons.admin_panel_settings_outlined,
        size: 18,
        color: AppColors.tertiary,
      ),
      label: Text(
        'Manage Admins',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.tertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: AppColors.tertiary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Debug — Push notification testing (debug builds only)
// ═══════════════════════════════════════════════════════════════════════════════

class _DebugNotificationSection extends StatefulWidget {
  const _DebugNotificationSection({required this.uid});
  final String uid;

  @override
  State<_DebugNotificationSection> createState() =>
      _DebugNotificationSectionState();
}

class _DebugNotificationSectionState extends State<_DebugNotificationSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification sent ✓')));
      }
    } catch (e) {
      debugPrint('[DebugNotif] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.tertiary,
      fontWeight: FontWeight.w600,
    );
    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      side: const BorderSide(color: AppColors.tertiary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Debug · Push Notifications',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _run(
                  () => PushNotificationService.sendNotificationToUser(
                    uid: widget.uid,
                    title: 'FoodTech Prep',
                    body: 'Send-by-uid backend pattern is working! 🎉',
                  ),
                ),
          icon: Icon(Icons.send_rounded, size: 18, color: AppColors.tertiary),
          label: Text('Test Send-by-UID', style: textStyle),
          style: buttonStyle,
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _run(
                  () => PushNotificationService.sendCountdownReminder(
                    uid: widget.uid,
                  ),
                ),
          icon: Icon(
            Icons.calendar_today_rounded,
            size: 18,
            color: AppColors.tertiary,
          ),
          label: Text('Test Countdown Reminder', style: textStyle),
          style: buttonStyle,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Broadcast · All Users',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _run(() async {
                  final result =
                      await PushNotificationService.sendNotificationToAllUsers(
                    title: 'FoodTech Prep',
                    body:
                        'Keep studying! Your board exam is getting closer. 📚',
                  );
                  if (mounted) {
                    final sent = result['sent'] ?? 0;
                    final skipped = result['skipped'] ?? 0;
                    final failed = result['failed'] ?? 0;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Broadcast: $sent sent, $skipped skipped, $failed failed',
                        ),
                      ),
                    );
                  }
                }),
          icon: Icon(
            Icons.campaign_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          label: Text(
            'Broadcast to All Users',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: AppColors.warning),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. Sign out — subtle, not dominant
// ═══════════════════════════════════════════════════════════════════════════════

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        Icons.logout_rounded,
        size: 18,
        color: AppColors.textSecondary,
      ),
      label: Text(
        'Sign Out',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared helpers
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}
