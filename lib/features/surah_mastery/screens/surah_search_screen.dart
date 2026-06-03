import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/providers.dart';

/// Dedicated search screen for finding a Surah by name (English, Arabic,
/// transliteration, or number). Live-filters as the user types.
class SurahSearchScreen extends ConsumerStatefulWidget {
  const SurahSearchScreen({super.key});

  @override
  ConsumerState<SurahSearchScreen> createState() => _SurahSearchScreenState();
}

class _SurahSearchScreenState extends ConsumerState<SurahSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus on open so the keyboard shows immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> surahs) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return surahs;
    return surahs.where((s) {
      final name = (s['name_english'] ?? s['name'] ?? '').toString().toLowerCase();
      final translit = (s['name_transliteration'] ?? '').toString().toLowerCase();
      final arabic = (s['name_arabic'] ?? '').toString();
      final translation = (s['translation'] ?? s['english_meaning'] ?? '')
          .toString()
          .toLowerCase();
      final number = (s['id'] ?? '').toString();
      return name.contains(q) ||
          translit.contains(q) ||
          arabic.contains(q) ||
          translation.contains(q) ||
          number == q;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahsProvider);

    return Scaffold(
      backgroundColor: AppColors.richBlack,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              focusNode: _focusNode,
              onBack: () => Navigator.of(context).maybePop(),
              onChanged: (value) {
                setState(() => _query = value);
              },
              onClear: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
            Expanded(
              child: surahsAsync.when(
                data: (all) {
                  final results = _filter(all);
                  if (_query.isEmpty) {
                    return _EmptyState(
                      title: 'Search 114 Surahs',
                      subtitle:
                          'Type a name, number, or meaning (e.g. "the cow")',
                    );
                  }
                  if (results.isEmpty) {
                    return _EmptyState(
                      title: 'No matches',
                      subtitle: 'Try a different spelling or a number 1–114',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      120,
                    ),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) =>
                        _ResultCard(data: results[i]),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.metallicGold,
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Couldn\'t load Surahs.\n$e',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.heroBlack,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.deepCharcoal,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Search Surahs...',
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 15,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: onClear,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.heroBlack,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.metallicGold.withValues(alpha: 0.18),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 32,
                color: AppColors.metallicGold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final id = (data['id'] as int?) ?? 0;
    final name = (data['name_english'] as String?) ??
        (data['name'] as String?) ??
        'Surah';
    final meaning = (data['translation'] as String?) ??
        (data['english_meaning'] as String?) ??
        '';
    final arabic = (data['name_arabic'] as String?) ?? '';
    final revelation =
        (data['revelation_place'] as String?)?.toUpperCase() ?? '';
    final verses = data['ayah_count'] ?? data['verse_count'] ?? data['verses'];

    return GestureDetector(
      onTap: () => context.push('/surah/$id', extra: name),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.deepCharcoal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
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
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.star,
                    size: 48,
                    color: AppColors.metallicGold.withValues(alpha: 0.85),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.heroBlack,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.metallicGold, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$id',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.metallicGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (meaning.isNotEmpty) meaning,
                      if (revelation.isNotEmpty)
                        revelation.toLowerCase().contains('mecc')
                            ? 'Meccan'
                            : 'Medinan',
                      if (verses != null) '$verses verses',
                    ].join(' · '),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (arabic.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(
                  arabic,
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    color: AppColors.metallicGold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
