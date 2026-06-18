import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/surah_settings_service.dart';

/// Bottom sheet for tweaking how the Quran reads: font size + Tajweed.
Future<void> showSurahSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.deepCharcoal,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => const _SurahSettingsSheet(),
  );
}

class _SurahSettingsSheet extends StatefulWidget {
  const _SurahSettingsSheet();

  @override
  State<_SurahSettingsSheet> createState() => _SurahSettingsSheetState();
}

class _SurahSettingsSheetState extends State<_SurahSettingsSheet> {
  late double _fontSize;
  late bool _tajweed;

  @override
  void initState() {
    super.initState();
    _fontSize = SurahSettingsService.instance.arabicFontSize;
    _tajweed = SurahSettingsService.instance.tajweedEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.metallicGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.metallicGold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Reader Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.glassBorder),

          // Arabic font size
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arabic Font Size',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_fontSize.round()} pt',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
                // Live preview of a short Arabic phrase at the chosen size
                Text(
                  'بِسْمِ',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: _fontSize,
                    color: AppColors.metallicGold,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.metallicGold,
              inactiveTrackColor:
                  AppColors.metallicGold.withValues(alpha: 0.18),
              thumbColor: AppColors.metallicGold,
              overlayColor: AppColors.metallicGold.withValues(alpha: 0.18),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Slider(
                min: SurahSettingsService.minFontSize,
                max: SurahSettingsService.maxFontSize,
                divisions:
                    (SurahSettingsService.maxFontSize -
                            SurahSettingsService.minFontSize)
                        .round(),
                value: _fontSize,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _fontSize = v);
                  SurahSettingsService.instance.setArabicFontSize(v);
                },
              ),
            ),
          ),

          // Tajweed toggle
          SwitchListTile.adaptive(
            value: _tajweed,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _tajweed = v);
              SurahSettingsService.instance.setTajweedEnabled(v);
            },
            activeThumbColor: AppColors.metallicGold,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            title: Text(
              'Tajweed Coloring',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Color Arabic letters by recitation rule (Madd, Ghunnah, Qalqalah, etc.)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Tip: tap any Arabic word to hear it spoken.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
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
