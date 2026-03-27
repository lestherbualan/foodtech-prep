import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/feature_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final greeting = user?.displayName ?? user?.email ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () {
              ref.read(authActionProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $greeting!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ready to ace your Food Technology exam?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  children: [
                    FeatureCard(
                      title: AppConstants.practiceMode,
                      icon: Icons.menu_book_rounded,
                      color: AppColors.primary,
                      onTap: () => context.push(RouteNames.questionBank),
                    ),
                    FeatureCard(
                      title: AppConstants.timedExam,
                      icon: Icons.timer_rounded,
                      color: AppColors.secondary,
                      onTap: () {},
                    ),
                    FeatureCard(
                      title: AppConstants.results,
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.warning,
                      onTap: () {},
                    ),
                    FeatureCard(
                      title: AppConstants.profile,
                      icon: Icons.person_rounded,
                      color: AppColors.primaryLight,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
