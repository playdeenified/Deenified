import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/providers.dart';
import '../../../services/quran_audio_service.dart';
import '../../../services/supabase_service.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  final String storyId;

  const AudioPlayerScreen({super.key, required this.storyId});

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  late final AudioPlayer _player;
  bool _progressLoaded = false;
  String? _audioError;

  // While the user is dragging the scrubber, we show THEIR value instead of
  // the live position stream (which would otherwise fight the drag and snap
  // the thumb back). Null = not dragging.
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    // Make sure surah recitation isn't still playing in the background
    // when the user opens a story — otherwise two recitations layer.
    QuranAudioService.instance.stop();
  }

  String? _loadingForPath; // The path we've kicked off a load for, if any.

  /// Idempotent load. Safe to call from build() because we only ever fire
  /// once per `audioPath` — even if the previous attempt errored. The Retry
  /// button clears [_loadingForPath] so a subsequent call re-fires.
  Future<void> _loadAudio(String audioPath) async {
    if (_loadingForPath == audioPath) return;
    _loadingForPath = audioPath;
    if (_audioError != null && mounted) {
      setState(() => _audioError = null);
    }
    try {
      final url = Supabase.instance.client.storage
          .from('audio-files')
          .getPublicUrl(audioPath);
      await _player.setUrl(url);

      // Resume from saved position
      if (!_progressLoaded) {
        _progressLoaded = true;
        try {
          final progress =
              await SupabaseService.instance.getStoryProgress(widget.storyId);
          if (progress != null) {
            final savedPos = progress['playback_position_seconds'] as int? ?? 0;
            if (savedPos > 0) {
              await _player.seek(Duration(seconds: savedPos));
            }
          }
        } catch (_) {
          // Ignore progress load errors
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _audioError = e.toString();
        });
      }
    }
  }

  void _retryAudio() {
    final path = _loadingForPath;
    if (path == null) return;
    // Force re-attempt by treating the next call as fresh.
    _loadingForPath = null;
    _loadAudio(path);
  }

  String? _getCoverUrl(Map<String, dynamic> story) {
    final coverPath = story['cover_image_url'] as String?;
    if (coverPath == null || coverPath.isEmpty) return null;

    return Supabase.instance.client.storage
        .from('cover-images')
        .getPublicUrl(coverPath);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Save current playback position to story_progress
  Future<void> _saveProgress() async {
    final pos = _player.position.inSeconds;
    final dur = _player.duration?.inSeconds ?? 0;
    final completed = dur > 0 && pos >= dur - 2; // within 2s of end
    await SupabaseService.instance.updateStoryProgress(
      storyId: widget.storyId,
      positionSeconds: pos,
      completed: completed,
    );
  }

  @override
  void dispose() {
    _saveProgress();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(audioStoryProvider(widget.storyId));

    return Scaffold(
      backgroundColor: AppColors.richBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.heroBlack),
          onPressed: () async {
            await _saveProgress();
            _player.stop();
            if (context.mounted) context.pop();
          },
        ),
      ),
      body: storyAsync.when(
        data: (story) {
          if (story == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Story not found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          // Load audio if available
          final audioPath = story['audio_url'] as String?;
          if (audioPath != null && audioPath.isNotEmpty) {
            _loadAudio(audioPath);
          }

          final coverUrl = _getCoverUrl(story);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  const Spacer(),

                  // Cover Art
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: AppColors.deepCharcoal,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.glassBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.metallicGold.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (coverUrl != null)
                            Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.headphones,
                                  size: 80,
                                  color: AppColors.metallicGold,
                                ),
                              ),
                            )
                          else
                            Center(
                              child: Icon(
                                Icons.headphones,
                                size: 80,
                                color: AppColors.metallicGold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Series Name
                  if (story['series_name'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.metallicGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        story['series_name'],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.metallicGold,
                            ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // Title & Description
                  Text(
                    story['title'] ?? 'Untitled',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    story['description'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Audio Controls (stream-based)
                  if (_audioError != null)
                    Column(
                      children: [
                        Text(
                          'Audio unavailable',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _retryAudio,
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.metallicGold,
                          ),
                          label: const Text(
                            'Retry',
                            style: TextStyle(color: AppColors.metallicGold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.metallicGold),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Progress Bar
                    StreamBuilder<Duration?>(
                      stream: _player.durationStream,
                      builder: (context, durationSnap) {
                        final totalDuration =
                            durationSnap.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: _player.positionStream,
                          builder: (context, positionSnap) {
                            final position = positionSnap.data ?? Duration.zero;
                            final progress = totalDuration.inMilliseconds > 0
                                ? position.inMilliseconds /
                                    totalDuration.inMilliseconds
                                : 0.0;

                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: AppColors.metallicGold,
                                    inactiveTrackColor: AppColors.metallicGold
                                        .withValues(alpha: 0.18),
                                    thumbColor: AppColors.metallicGold,
                                    overlayColor: AppColors.metallicGold
                                        .withValues(alpha: 0.2),
                                    trackHeight: 6,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8),
                                  ),
                                  child: Slider(
                                    // Use the drag value while dragging so the
                                    // thumb tracks the finger smoothly.
                                    value: (_dragValue ?? progress)
                                        .clamp(0.0, 1.0),
                                    onChangeStart: (value) {
                                      setState(() => _dragValue = value);
                                    },
                                    onChanged: (value) {
                                      setState(() => _dragValue = value);
                                    },
                                    onChangeEnd: (value) {
                                      HapticFeedback.selectionClick();
                                      final ms = totalDuration.inMilliseconds;
                                      if (ms > 0) {
                                        _player.seek(Duration(
                                          milliseconds: (value * ms).toInt(),
                                        ));
                                      }
                                      setState(() => _dragValue = null);
                                    },
                                  ),
                                ),
                                // Time Labels
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(
                                          _dragValue != null
                                              ? Duration(
                                                  milliseconds: (_dragValue! *
                                                          totalDuration
                                                              .inMilliseconds)
                                                      .toInt(),
                                                )
                                              : position,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.textTertiary,
                                            ),
                                      ),
                                      Text(
                                        _formatDuration(totalDuration),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.textTertiary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Playback Controls
                    StreamBuilder<PlayerState>(
                      stream: _player.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final isPlaying = playerState?.playing ?? false;
                        final processingState = playerState?.processingState ??
                            ProcessingState.idle;
                        final isLoading =
                            processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Backward 10s
                            IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                final newPos = _player.position -
                                    const Duration(seconds: 10);
                                _player.seek(newPos < Duration.zero
                                    ? Duration.zero
                                    : newPos);
                              },
                              icon: const Icon(Icons.replay_10, size: 36),
                              color: AppColors.heroBlack,
                            ),

                            const SizedBox(width: AppSpacing.lg),

                            // Play/Pause
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                if (processingState ==
                                    ProcessingState.completed) {
                                  _player.seek(Duration.zero);
                                  _player.play();
                                } else if (isPlaying) {
                                  _player.pause();
                                } else {
                                  _player.play();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.metallicGold,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.metallicGold
                                          .withValues(alpha: 0.3),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          color: AppColors.heroBlack,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Icon(
                                        isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 40,
                                        color: AppColors.heroBlack,
                                      ),
                              ),
                            ),

                            const SizedBox(width: AppSpacing.lg),

                            // Forward 10s
                            IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                final newPos = _player.position +
                                    const Duration(seconds: 10);
                                final duration =
                                    _player.duration ?? Duration.zero;
                                _player.seek(
                                    newPos > duration ? duration : newPos);
                              },
                              icon: const Icon(Icons.forward_10, size: 36),
                              color: AppColors.heroBlack,
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  const Spacer(),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load story',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  e.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
