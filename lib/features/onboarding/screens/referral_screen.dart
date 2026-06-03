import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

/// Merged referral screen: "Where did you hear about us?" plus a
/// sub-question for the influencer name once a source is picked.
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _influencerController = TextEditingController();

  @override
  void dispose() {
    _influencerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final source = state.referralSource;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - AppSpacing.lg * 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Where did you hear about us?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                _option(
                  label: 'Instagram',
                  icon: Icons.camera_alt_outlined,
                  value: 'instagram',
                  selected: source == 'instagram',
                ),
                _option(
                  label: 'TikTok',
                  icon: Icons.music_note,
                  value: 'tiktok',
                  selected: source == 'tiktok',
                ),
                _option(
                  label: 'Friends or Family',
                  icon: Icons.people_outline,
                  value: 'friends_family',
                  selected: source == 'friends_family',
                ),
                _option(
                  label: 'Other',
                  icon: Icons.more_horiz,
                  value: 'other',
                  selected: source == 'other',
                ),

                // Sub-question — appears once a source is selected.
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: source == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Did an influencer send you? Who?',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextField(
                                controller: _influencerController,
                                textCapitalization:
                                    TextCapitalization.words,
                                onChanged: (v) => ref
                                    .read(onboardingProvider.notifier)
                                    .setReferralInfluencer(v.trim()),
                                decoration: InputDecoration(
                                  hintText: 'Their name or handle (optional)',
                                  prefixIcon:
                                      const Icon(Icons.person_outline),
                                  filled: true,
                                  fillColor: AppColors.deepCharcoal,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    borderSide: const BorderSide(
                                      color: AppColors.glassBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    borderSide: const BorderSide(
                                      color: AppColors.glassBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    borderSide: const BorderSide(
                                      color: AppColors.metallicGold,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: AppSpacing.xl),
                PremiumButton(
                  text: 'CONTINUE',
                  onPressed: source != null
                      ? () => ref.read(onboardingProvider.notifier).nextStep()
                      : () {},
                  isOutlined: source == null,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _option({
    required String label,
    required IconData icon,
    required String value,
    required bool selected,
  }) {
    return ContentCard(
      selected: selected,
      onTap: () =>
          ref.read(onboardingProvider.notifier).setReferralSource(value),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [AppColors.softGold, AppColors.metallicGold],
                    )
                  : null,
              color: selected ? null : AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: selected ? AppColors.heroBlack : AppColors.darkGold,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle, color: AppColors.metallicGold),
        ],
      ),
    );
  }
}
