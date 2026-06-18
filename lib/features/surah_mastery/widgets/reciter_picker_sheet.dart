import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/quran_api_service.dart';
import '../../../services/quran_audio_service.dart';

/// Bottom sheet that lists every reciter from quran.com and lets the user
/// pick one. Selection is persisted via [QuranAudioService.setSelectedReciterId].
///
/// Returns the picked reciter id (or null if dismissed).
Future<int?> showReciterPickerSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppColors.deepCharcoal,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => const _ReciterPickerSheet(),
  );
}

class _ReciterPickerSheet extends StatefulWidget {
  const _ReciterPickerSheet();

  @override
  State<_ReciterPickerSheet> createState() => _ReciterPickerSheetState();
}

class _ReciterPickerSheetState extends State<_ReciterPickerSheet> {
  late Future<List<Reciter>> _recitersFuture;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _recitersFuture = QuranApiService.instance.getReciters();
    _loadSelected();
  }

  Future<void> _loadSelected() async {
    final id = await QuranAudioService.instance.getSelectedReciterId();
    if (mounted) setState(() => _selectedId = id);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
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
                  const Icon(
                    Icons.headphones_rounded,
                    color: AppColors.metallicGold,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Choose Reciter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.glassBorder),
            Expanded(
              child: FutureBuilder<List<Reciter>>(
                future: _recitersFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.metallicGold,
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'Could not load reciters.\nCheck your internet and try again.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    );
                  }
                  final reciters = snap.data ?? [];
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: reciters.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.glassBorder.withValues(alpha: 0.5),
                      indent: AppSpacing.lg,
                      endIndent: AppSpacing.lg,
                    ),
                    itemBuilder: (context, i) {
                      final r = reciters[i];
                      final isSelected = r.id == _selectedId;
                      return InkWell(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          await QuranAudioService.instance
                              .setSelectedReciterId(r.id);
                          if (context.mounted) {
                            Navigator.of(context).pop(r.id);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.metallicGold
                                          .withValues(alpha: 0.15)
                                      : AppColors.richBlack,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.metallicGold
                                        : AppColors.glassBorder,
                                    width: isSelected ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.metallicGold
                                      : AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.reciterName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: isSelected
                                                ? AppColors.metallicGold
                                                : AppColors.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                    ),
                                    if (r.style != null &&
                                        r.style!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          r.style!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textTertiary,
                                              ),
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
