import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/question.dart';
import '../providers/admin_review_session_provider.dart';
import '../providers/practice_session_provider.dart';
import 'admin_question_player_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route args
// ─────────────────────────────────────────────────────────────────────────────

/// Args passed to [SubtopicReviewScreen] via GoRouter.
class SubtopicReviewArgs {
  const SubtopicReviewArgs({
    required this.questions,
    required this.subtopicName,
    required this.subjectName,
    this.isAdminView = false,
  });

  final List<Question> questions;
  final String subtopicName;
  final String subjectName;

  /// When true, extra metadata (ID, status, confidence, review flag)
  /// is rendered on each question card.
  final bool isAdminView;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Question navigator / table-of-contents for a single subtopic.
///
/// Opened instead of going directly to Practice Mode, allowing the learner
/// to browse, search, and filter questions before entering a session.
class SubtopicReviewScreen extends ConsumerStatefulWidget {
  const SubtopicReviewScreen({super.key, required this.args});

  final SubtopicReviewArgs args;

  @override
  ConsumerState<SubtopicReviewScreen> createState() =>
      _SubtopicReviewScreenState();
}

class _SubtopicReviewScreenState extends ConsumerState<SubtopicReviewScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _difficultyFilter;
  String? _sourceFilter;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Derived data ────────────────────────────────────────────────────────────

  List<Question> get _filtered {
    var qs = widget.args.questions;
    if (_searchQuery.isNotEmpty) {
      final lower = _searchQuery.toLowerCase();
      qs = qs
          .where((q) => q.questionText.toLowerCase().contains(lower))
          .toList();
    }
    if (_difficultyFilter != null) {
      qs = qs.where((q) => q.difficulty == _difficultyFilter).toList();
    }
    if (_sourceFilter != null) {
      qs = qs.where((q) => q.sourceFile == _sourceFilter).toList();
    }
    return qs;
  }

  List<String> get _difficulties {
    final seen = <String>{};
    for (final q in widget.args.questions) {
      seen.add(q.difficulty);
    }
    return seen.toList()..sort();
  }

  List<String> get _sources {
    final seen = <String>{};
    for (final q in widget.args.questions) {
      if (q.sourceFile != null && q.sourceFile!.isNotEmpty) {
        seen.add(q.sourceFile!);
      }
    }
    return seen.toList()..sort();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  /// Stable session key for this subtopic's persisted resume state.
  ///
  /// Uses `{subjectId}|{subtopicId}` from the question bank so the key
  /// remains valid even if the subtopic display name changes.
  String get _sessionKey {
    final qs = widget.args.questions;
    if (qs.isEmpty) return widget.args.subtopicName;
    return '${qs.first.subjectId}|${qs.first.subtopicId}';
  }

  void _launchPractice(List<Question> questions) {
    if (questions.isEmpty) return;
    context.push(
      RouteNames.practice,
      extra: PracticeSessionArgs(questions: questions, startIndex: 0),
    );
  }

  void _launchAdminPlayer(
    List<Question> questions,
    int startIndex, {
    bool clearPrevious = false,
  }) {
    if (questions.isEmpty) return;
    final storeNotifier = ref.read(adminReviewSessionStoreProvider.notifier);
    final existing = storeNotifier.load(_sessionKey);
    final AdminReviewSession session;
    // Create a fresh session when explicitly requested, when no session exists,
    // or when only a skeleton (disk-loaded, empty questions) session is present.
    if (clearPrevious || existing == null || existing.questions.isEmpty) {
      session = AdminReviewSession.create(questions, startIndex);
    } else {
      session = existing.copyWith(currentIndex: startIndex);
    }
    storeNotifier.save(_sessionKey, session);
    context.push(
      RouteNames.adminQuestionPlayer,
      extra: AdminQuestionPlayerArgs(
        questions: session.questions,
        startIndex: session.currentIndex,
        sessionKey: _sessionKey,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final filtered = _filtered;
    final total = args.questions.length;

    // Derive admin status from permissions — no need to rely on the args flag.
    final isAdmin = ref.watch(userPermissionsProvider).canViewQuestionSource;
    final hasResumeSession = ref.watch(
      adminReviewSessionStoreProvider.select(
        (m) =>
            m.containsKey(_sessionKey) &&
            (m[_sessionKey]?.hasProgress ?? false),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────────
          SecondaryScreenHeader(
            title: args.subtopicName,
            subtitle: args.subjectName,
            trailing: _CountBadge(count: total),
          ),

          // ── Scrollable body ──────────────────────────────────────────────────
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Summary / action card ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _SummaryCard(
                      totalQuestions: total,
                      sourceCount: _sources.length,
                      onStartSequential: isAdmin
                          ? () => _launchAdminPlayer(
                              args.questions,
                              0,
                              clearPrevious: true,
                            )
                          : () => _launchPractice(args.questions),
                      onStartShuffled: () {
                        final shuffled = List<Question>.from(args.questions)
                          ..shuffle();
                        if (isAdmin) {
                          _launchAdminPlayer(shuffled, 0, clearPrevious: true);
                        } else {
                          _launchPractice(shuffled);
                        }
                      },
                      onResume: (isAdmin && hasResumeSession)
                          ? () {
                              // Reconstruct from the lightweight payload if
                              // this is a skeleton loaded after app restart.
                              final session = ref
                                  .read(
                                    adminReviewSessionStoreProvider.notifier,
                                  )
                                  .resolveForResume(
                                    _sessionKey,
                                    widget.args.questions,
                                  );
                              if (session == null) return;
                              _launchAdminPlayer(
                                session.questions,
                                session.currentIndex,
                              );
                            }
                          : null,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),

                // ── Filter bar ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _FilterBar(
                    controller: _searchController,
                    difficulties: _difficulties,
                    sources: _sources,
                    selectedDifficulty: _difficultyFilter,
                    selectedSource: _sourceFilter,
                    onSearch: (v) => setState(() => _searchQuery = v),
                    onDifficultySelected: (v) => setState(() {
                      _difficultyFilter = _difficultyFilter == v ? null : v;
                    }),
                    onSourceSelected: (v) => setState(() {
                      _sourceFilter = _sourceFilter == v ? null : v;
                    }),
                  ),
                ),

                // ── Result count ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: Text(
                      _searchQuery.isEmpty &&
                              _difficultyFilter == null &&
                              _sourceFilter == null
                          ? '$total question${total == 1 ? '' : 's'}'
                          : '${filtered.length} of $total question${total == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // ── Empty state ─────────────────────────────────────────────────
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No questions match your filters.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textHint),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                // ── Question list ──────────────────────────────────────────────
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final q = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _QuestionCard(
                            question: q,
                            number: index + 1,
                            isAdminView: isAdmin,
                            onTap: () {
                              if (isAdmin) {
                                final startIndex = args.questions.indexOf(q);
                                _launchAdminPlayer(
                                  args.questions,
                                  startIndex >= 0 ? startIndex : 0,
                                );
                              } else {
                                context.push(
                                  RouteNames.questionDetail,
                                  extra: q,
                                );
                              }
                            },
                          ),
                        );
                      }, childCount: filtered.length),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Count badge  (header trailing)
// ─────────────────────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$count Q',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary / action card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalQuestions,
    required this.sourceCount,
    required this.onStartSequential,
    required this.onStartShuffled,
    this.onResume,
  });

  final int totalQuestions;
  final int sourceCount;
  final VoidCallback onStartSequential;
  final VoidCallback onStartShuffled;
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      gradient: AppColors.heroGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: icon + helper text ─────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text(
                  'Browse questions before starting',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.80),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Stat pills ──────────────────────────────────────────────────────
          Wrap(
            spacing: AppSpacing.xs + 2,
            runSpacing: AppSpacing.xs,
            children: [
              _StatPill(
                icon: Icons.quiz_outlined,
                label:
                    '$totalQuestions question${totalQuestions == 1 ? '' : 's'}',
              ),
              if (sourceCount > 0)
                _StatPill(
                  icon: Icons.source_outlined,
                  label:
                      '$sourceCount ${sourceCount == 1 ? 'source file' : 'source files'}',
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md + 4),

          // ── Action buttons ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.format_list_numbered_rounded,
                  label: 'Sequential',
                  onPressed: onStartSequential,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionButton(
                  icon: Icons.shuffle_rounded,
                  label: 'Shuffled',
                  onPressed: onStartShuffled,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionButton(
                  icon: Icons.restore_rounded,
                  label: 'Resume',
                  onPressed: onResume,
                  isDisabled: onResume == null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDisabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm + 2,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDisabled ? 0.08 : 0.18),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDisabled ? 0.08 : 0.28),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white.withValues(alpha: isDisabled ? 0.35 : 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: isDisabled ? 0.35 : 1.0),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.controller,
    required this.difficulties,
    required this.sources,
    required this.selectedDifficulty,
    required this.selectedSource,
    required this.onSearch,
    required this.onDifficultySelected,
    required this.onSourceSelected,
  });

  final TextEditingController controller;
  final List<String> difficulties;
  final List<String> sources;
  final String? selectedDifficulty;
  final String? selectedSource;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onDifficultySelected;
  final ValueChanged<String> onSourceSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search field ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: TextField(
            controller: controller,
            onChanged: onSearch,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search questions…',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textHint,
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: AppColors.textHint,
                      onPressed: () {
                        controller.clear();
                        onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        // ── Difficulty chips ─────────────────────────────────────────────────
        if (difficulties.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: difficulties.map((d) {
                final selected = selectedDifficulty == d;
                final color = _difficultyColor(d);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs + 2),
                  child: FilterChip(
                    label: Text(d),
                    selected: selected,
                    onSelected: (_) => onDifficultySelected(d),
                    selectedColor: color.withValues(alpha: 0.12),
                    checkmarkColor: color,
                    showCheckmark: true,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? color : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: selected
                          ? color.withValues(alpha: 0.45)
                          : AppColors.outline,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // ── Source chips ─────────────────────────────────────────────────────
        if (sources.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: sources.map((s) {
                final selected = selectedSource == s;
                final label = s.length > 30 ? '${s.substring(0, 27)}…' : s;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs + 2),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => onSourceSelected(s),
                    selectedColor: AppColors.primarySurface,
                    checkmarkColor: AppColors.primary,
                    showCheckmark: true,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.40)
                          : AppColors.outline,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  static Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'hard':
      case 'difficult':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Question list item card
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.number,
    required this.isAdminView,
    required this.onTap,
  });

  final Question question;
  final int number;
  final bool isAdminView;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final q = question;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: number + badges + chevron ───────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Difficulty + type badges
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _DifficultyBadge(difficulty: q.difficulty),
                        if (q.questionType != null &&
                            q.questionType!.isNotEmpty)
                          _Badge(
                            label: q.questionType!,
                            color: AppColors.tertiary,
                            bgColor: AppColors.tertiarySurface,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textHint,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // ── Question text preview ─────────────────────────────────────
              Text(
                q.questionText,
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // ── Source row ────────────────────────────────────────────────
              if (q.sourceFile != null || q.sourceReference != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _sourceLabel(q),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _sourceLabel(Question q) {
    final parts = <String>[];
    final ref = q.sourceReference?.trim();
    final file = q.sourceFile?.trim();
    if (ref != null && ref.isNotEmpty) {
      parts.add(_formatRef(ref));
    }
    if (file != null && file.isNotEmpty) {
      var name = file.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
      name = name.replaceAll('_', ' ').replaceAll(RegExp(r' {2,}'), ' ').trim();
      parts.add(name);
    }
    return parts.join(' \u00b7 ');
  }

  /// Normalises a raw page reference into `p. X` or `pp. X–Y`.
  /// Handles inputs like `Page A1-1`, `Pages A1-1–A1-2`, `p. 8`, `pp. 8–9`, `8`.
  static String _formatRef(String raw) {
    var s = raw.trim();
    // Strip any existing p./pp. abbreviation prefix
    s = s.replaceAll(RegExp(r'^pp\.\s*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'^p\.\s*', caseSensitive: false), '');
    // Strip English words Page / Pages
    s = s.replaceAll(RegExp(r'^[Pp]ages?\s+'), '');
    s = s.trim();
    // Range if it contains an en-dash, em-dash, or ` - ` (space-hyphen-space)
    final isRange =
        s.contains('\u2013') || s.contains('\u2014') || s.contains(' - ');
    return '${isRange ? 'pp.' : 'p.'} $s';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small badge widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    return _Badge(
      label: difficulty,
      color: _color(difficulty),
      bgColor: _bgColor(difficulty),
    );
  }

  static Color _color(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'hard':
      case 'difficult':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  static Color _bgColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return AppColors.successLight;
      case 'hard':
      case 'difficult':
        return AppColors.errorLight;
      default:
        return AppColors.warningLight;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _AdminChip extends StatelessWidget {
  const _AdminChip({required this.label, this.color, this.bgColor});

  final String label;
  final Color? color;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.textSecondary,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
