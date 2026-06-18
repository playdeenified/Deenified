import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/surah_settings_service.dart';

/// Bottom sheet for tweaking how the Quran reads:
/// font size, font family, and Tajweed coloring.
Future<void> showSurahSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.deepCharcoal,
    isScrollControlled: true,
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
  late SurahFontFamily _fontFamily;
  late bool _tajweed;

  @override
  void initState() {
    super.initState();
    final svc = SurahSettingsService.instance;
    _fontSize = svc.arabicFontSize;
    _fontFamily = svc.arabicFontFamily;
    _tajweed = svc.tajweedEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                        Icons.settings_rounded,
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
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'بِسْمِ',
                      style: SurahSettingsService.instance.arabicTextStyle(
                        color: AppColors.metallicGold,
                        fontSize: _fontSize,
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
                  overlayColor:
                      AppColors.metallicGold.withValues(alpha: 0.18),
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 9),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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

              // Arabic font family
              const Divider(height: 1, color: AppColors.glassBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arabic Font',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pick the script style for the Quran text',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              ...SurahFontFamily.values.map((f) {
                final isSelected = f == _fontFamily;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _fontFamily = f);
                    SurahSettingsService.instance.setArabicFontFamily(f);
                  },
                  child: Container(
                    color: isSelected
                        ? AppColors.metallicGold.withValues(alpha: 0.06)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        // Preview swatch
                        Container(
                          width: 56,
                          alignment: Alignment.center,
                          child: Text(
                            'الٓمٓ',
                            style: SurahSettingsService.instance
                                .copyArabicWith(f, fontSize: 22),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                              ),
                              Text(
                                f.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.metallicGold,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const Divider(height: 1, color: AppColors.glassBorder),

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
                  'Color Arabic letters by recitation rule',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
