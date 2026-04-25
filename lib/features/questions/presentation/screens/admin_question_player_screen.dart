import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/question.dart';
import '../providers/admin_review_session_provider.dart';
import '../widgets/answer_option_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route args
// ─────────────────────────────────────────────────────────────────────────────

/// Arguments for the admin question player.
class AdminQuestionPlayerArgs {
  const AdminQuestionPlayerArgs({
    required this.questions,
    required this.startIndex,
    required this.sessionKey,
  });

  /// Questions to present. Must not be empty.
  final List<Question> questions;

  /// Position to open at.
  final int startIndex;

  /// Session persistence key — must match the key used when saving the
  /// session in [adminReviewSessionStoreProvider] before navigation.
  final String sessionKey;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Interactive question attempt screen for admin review.
///
/// Behaves like Practice Mode — questions start unanswered, the user selects
/// a choice, taps "Check Answer", then the result + explanation are revealed.
///
/// Admin-specific additions:
/// - The header shows questionId, status, confidence, and review flag.
/// - Explanation always shows source file + page reference.
/// - Session state is persisted in [adminReviewSessionStoreProvider] so
///   the Resume button in [SubtopicReviewScreen] can restore the session.
class AdminQuestionPlayerScreen extends ConsumerStatefulWidget {
  const AdminQuestionPlayerScreen({super.key, required this.args});

  final AdminQuestionPlayerArgs args;

  @override
  ConsumerState<AdminQuestionPlayerScreen> createState() =>
      _AdminQuestionPlayerScreenState();
}

class _AdminQuestionPlayerScreenState
    extends ConsumerState<AdminQuestionPlayerScreen> {
  late AdminReviewSession _session;

  @override
  void initState() {
    super.initState();
    // The session was already saved by the navigation callsite in
    // SubtopicReviewScreen — we only READ it here, never mutate.
    final stored = ref.read(
      adminReviewSessionStoreProvider.select((m) => m[widget.args.sessionKey]),
    );
    _session =
        stored ??
        AdminReviewSession.create(
          widget.args.questions,
          widget.args.startIndex,
        );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Question get _currentQ => _session.questions[_session.currentIndex];
  int get _currentIndex => _session.currentIndex;
  int get _total => _session.questions.length;

  String? get _selectedAnswer => _session.selectedAnswers[_currentQ.questionId];
  bool get _isChecked =>
      _session.checkedQuestions[_currentQ.questionId] ?? false;

  String get _displayCorrectAnswer =>
      _session.displayCorrectAnswers[_currentQ.questionId] ??
      _currentQ.correctAnswerLabel;

  bool get _isCorrect => _selectedAnswer == _displayCorrectAnswer;

  List<int> get _choiceOrder =>
      _session.choiceOrders[_currentQ.questionId] ?? [0, 1, 2, 3];

  AnswerOptionState _resolveOptionState(String letter) {
    if (!_isChecked) {
      return _selectedAnswer == letter
          ? AnswerOptionState.selected
          : AnswerOptionState.idle;
    }
    if (letter == _displayCorrectAnswer) return AnswerOptionState.correct;
    if (letter == _selectedAnswer) return AnswerOptionState.incorrect;
    return AnswerOptionState.disabled;
  }

  // ── Mutations ────────────────────────────────────────────────────────────────

  void _save() {
    ref
        .read(adminReviewSessionStoreProvider.notifier)
        .save(widget.args.sessionKey, _session);
  }

  void _selectAnswer(String letter) {
    if (_isChecked) return;
    final updated = Map<String, String?>.from(_session.selectedAnswers);
    updated[_currentQ.questionId] = letter;
    setState(() => _session = _session.copyWith(selectedAnswers: updated));
    _save();
  }

  void _checkAnswer() {
    if (_selectedAnswer == null || _isChecked) return;
    final updated = Map<String, bool>.from(_session.checkedQuestions);
    updated[_currentQ.questionId] = true;
    setState(() => _session = _session.copyWith(checkedQuestions: updated));
    _save();
  }

  void _goToNext() {
    if (_currentIndex >= _total - 1) return;
    setState(
      () => _session = _session.copyWith(currentIndex: _currentIndex + 1),
    );
    _save();
  }

  void _goToPrevious() {
    if (_currentIndex <= 0) return;
    setState(
      () => _session = _session.copyWith(currentIndex: _currentIndex - 1),
    );
    _save();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final q = _currentQ;

    return Scaffold(
      backgroundColor: context.appSurfaceColor,
      appBar: AppBar(
        title: Text(
          'Question Review',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _total,
            backgroundColor: context.appDividerColor,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header card ─────────────────────────────────────────────
                  _AdminQuestionHeader(
                    questionNumber: _currentIndex + 1,
                    totalQuestions: _total,
                    question: q,
                  ),
                  const SizedBox(height: AppSpacing.md + 4),

                  // ── Question text ────────────────────────────────────────────
                  Text(
                    q.questionText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Answer choices ───────────────────────────────────────────
                  ...List.generate(q.options.length, (i) {
                    const labels = ['A', 'B', 'C', 'D'];
                    final originalIndex = _choiceOrder[i];
                    return AnswerOptionCard(
                      letter: labels[i],
                      text: q.options[originalIndex].text,
                      optionState: _resolveOptionState(labels[i]),
                      onTap: _isChecked ? null : () => _selectAnswer(labels[i]),
                    );
                  }),

                  // ── Result + explanation (revealed after check) ──────────────
                  if (_isChecked) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _ResultBanner(isCorrect: _isCorrect),
                    const SizedBox(height: AppSpacing.md),
                    _AdminExplanationCard(question: q),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom action bar ─────────────────────────────────────────────
          _BottomActionBar(
            isChecked: _isChecked,
            hasSelectedAnswer: _selectedAnswer != null,
            isCorrect: _isCorrect,
            onCheck: _checkAnswer,
            onPrevious: _currentIndex > 0 ? _goToPrevious : null,
            onNext: _currentIndex < _total - 1 ? _goToNext : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Question Header
// ─────────────────────────────────────────────────────────────────────────────

class _AdminQuestionHeader extends StatelessWidget {
  const _AdminQuestionHeader({
    required this.questionNumber,
    required this.totalQuestions,
    required this.question,
  });

  final int questionNumber;
  final int totalQuestions;
  final Question question;

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: counter + difficulty + type ──────────────────────────────
          Row(
            children: [
              _HeaderChip(
                label: 'Q$questionNumber / $totalQuestions',
                bg: AppColors.primary,
                fg: Colors.white,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              _DifficultyChip(difficulty: q.difficulty),
              if (q.questionType != null && q.questionType!.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.xs + 2),
                _HeaderChip(
                  label: q.questionType!,
                  bg: AppColors.tertiarySurface,
                  fg: AppColors.tertiary,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Row 2: subject + subtopic ────────────────────────────────────────
          Text(
            q.subjectName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.appTextPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            q.subtopicName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appTextSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.difficulty});
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (difficulty.toLowerCase()) {
      'easy' => (context.appSuccessLightColor, AppColors.success),
      'hard' || 'difficult' => (context.appErrorLightColor, AppColors.error),
      _ => (context.appWarningLightColor, AppColors.warning),
    };
    return _HeaderChip(label: difficulty, bg: bg, fg: fg);
  }
}

class _AdminMetaChip extends StatelessWidget {
  const _AdminMetaChip({required this.label, this.fg, this.bg});
  final String label;
  final Color? fg;
  final Color? bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg ?? context.appSurfaceHighColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fg ?? context.appTextSecondaryColor,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result Banner
// ─────────────────────────────────────────────────────────────────────────────

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.isCorrect});
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final icon = isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final title = isCorrect ? 'Correct!' : 'Incorrect';
    final subtitle = isCorrect
        ? 'Great — you got it right.'
        : 'Review the explanation below.';
    final color = isCorrect ? AppColors.success : AppColors.error;
    final bgColor = isCorrect
        ? context.appSuccessLightColor
        : context.appErrorLightColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
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

// ─────────────────────────────────────────────────────────────────────────────
// Admin Explanation Card (always shows source)
// ─────────────────────────────────────────────────────────────────────────────

class _AdminExplanationCard extends StatelessWidget {
  const _AdminExplanationCard({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section title ─────────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.auto_stories_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Explanation',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),

          // ── Explanation body ──────────────────────────────────────────────
          Text(
            q.explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: context.appTextPrimaryColor,
            ),
          ),

          // ── Study note ────────────────────────────────────────────────────
          if (q.studyNote != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(height: 1, color: context.appDividerColor),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Tip',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: context.appTextSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        q.studyNote!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                          color: context.appTextSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // ── Source info (always visible in admin player) ──────────────────
          if (q.sourceFile != null || q.sourceReference != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(height: 1, color: context.appDividerColor),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.source_rounded,
                  size: 16,
                  color: context.appTextHintColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Source',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: context.appTextSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatSource(q),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.45,
                          color: context.appTextHintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatSource(Question q) {
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
// Bottom Action Bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.isChecked,
    required this.hasSelectedAnswer,
    required this.isCorrect,
    required this.onCheck,
    required this.onPrevious,
    required this.onNext,
  });

  final bool isChecked;
  final bool hasSelectedAnswer;
  final bool isCorrect;
  final VoidCallback onCheck;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.appCardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Prev
            _NavButton(
              icon: Icons.chevron_left_rounded,
              label: 'Prev',
              onPressed: onPrevious,
            ),
            const SizedBox(width: AppSpacing.sm),

            // Center action
            Expanded(child: _buildCenterAction(context)),

            const SizedBox(width: AppSpacing.sm),

            // Next
            _NavButton(
              icon: Icons.chevron_right_rounded,
              label: 'Next',
              onPressed: onNext,
              iconFirst: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAction(BuildContext context) {
    if (!isChecked) {
      return FilledButton(
        onPressed: hasSelectedAnswer ? onCheck : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 46),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: const Text('Check Answer'),
      );
    }

    final color = isCorrect ? AppColors.success : AppColors.error;
    final bgColor = isCorrect
        ? context.appSuccessLightColor
        : context.appErrorLightColor;
    return Container(
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isCorrect ? 'Correct' : 'Incorrect',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconFirst = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool iconFirst;

  @override
  Widget build(BuildContext context) {
    final color = onPressed != null
        ? context.appTextSecondaryColor
        : context.appDisabledColor;
    final iconWidget = Icon(icon, size: 22, color: color);
    final labelWidget = Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
    );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconFirst
              ? [iconWidget, const SizedBox(width: 2), labelWidget]
              : [labelWidget, const SizedBox(width: 2), iconWidget],
        ),
      ),
    );
  }
}
