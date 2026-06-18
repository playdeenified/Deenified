import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quran_api_service.dart';

/// Singleton audio service for Quran surah recitation.
///
/// Wraps an [AudioPlayer] with a queue of per-verse MP3s pulled from
/// quran.com. Exposes streams the UI can listen to for
/// "current verse" highlighting and persists the user's reciter choice.
class QuranAudioService {
  QuranAudioService._();
  static final instance = QuranAudioService._();

  static const _kReciterKey = 'quran_audio_reciter_id';

  /// Mishary Rashid al-`Afasy — the de facto default on Quran.com / Quran app.
  static const int defaultReciterId = 7;

  final AudioPlayer player = AudioPlayer();

  int? _currentSurahId;
  int? get currentSurahId => _currentSurahId;

  int _loadedForReciterId = -1;
  bool _queueLoaded = false;

  List<VerseAudio> _verses = [];
  List<VerseAudio> get verses => _verses;

  StreamSubscription<int?>? _stopAfterSub;
  StreamSubscription<PlayerState>? _repeatSub;
  int _repeatCount = 0;
  int _repeatTarget = 0;

  Future<int> getSelectedReciterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kReciterKey) ?? defaultReciterId;
  }

  Future<void> setSelectedReciterId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReciterKey, id);
    await stop();
    _queueLoaded = false;
    _verses = [];
    _loadedForReciterId = -1;
  }

  /// Load the full surah as a concatenated queue (one audio source per ayah).
  /// Cheap if already loaded for the same surah+reciter.
  Future<void> _ensureQueueLoaded(int surahId) async {
    final reciterId = await getSelectedReciterId();
    if (_queueLoaded &&
        _currentSurahId == surahId &&
        _loadedForReciterId == reciterId) {
      return;
    }
    _verses = await QuranApiService.instance.getVerseAudios(reciterId, surahId);
    _currentSurahId = surahId;
    _loadedForReciterId = reciterId;
    final sources = _verses
        .map<AudioSource>((v) => AudioSource.uri(Uri.parse(v.audioUrl)))
        .toList();
    await player.setAudioSources(sources);
    _queueLoaded = true;
  }

  /// Load just the verse list (without setting up the queue) — used by
  /// [repeatVerse] which sets a single-source URL instead.
  Future<void> _ensureVerseList(int surahId) async {
    final reciterId = await getSelectedReciterId();
    if (_currentSurahId == surahId &&
        _loadedForReciterId == reciterId &&
        _verses.isNotEmpty) {
      return;
    }
    _verses = await QuranApiService.instance.getVerseAudios(reciterId, surahId);
    _currentSurahId = surahId;
    _loadedForReciterId = reciterId;
  }

  /// Play the entire surah from verse 1.
  Future<void> playSurah(int surahId) async {
    await _cancelExtras();
    await _ensureQueueLoaded(surahId);
    await player.setLoopMode(LoopMode.off);
    await player.seek(Duration.zero, index: 0);
    await player.play();
  }

  /// Play from a specific verse and continue through the rest of the surah.
  Future<void> playFromVerse(int surahId, int verseIndex) async {
    await _cancelExtras();
    await _ensureQueueLoaded(surahId);
    await player.setLoopMode(LoopMode.off);
    await player.seek(Duration.zero, index: verseIndex);
    await player.play();
  }

  /// Play exactly one verse, then stop.
  Future<void> playOneVerse(int surahId, int verseIndex) async {
    await _cancelExtras();
    await _ensureQueueLoaded(surahId);
    await player.setLoopMode(LoopMode.off);
    await player.seek(Duration.zero, index: verseIndex);
    _stopAfterSub = player.currentIndexStream.listen((idx) {
      if (idx != null && idx != verseIndex) {
        player.pause();
        _stopAfterSub?.cancel();
        _stopAfterSub = null;
      }
    });
    await player.play();
  }

  /// Repeat a single verse [times] times. Pass -1 for infinite repeat.
  Future<void> repeatVerse(int surahId, int verseIndex, int times) async {
    await _cancelExtras();
    await _ensureVerseList(surahId);
    if (verseIndex < 0 || verseIndex >= _verses.length) return;

    final url = _verses[verseIndex].audioUrl;
    await player.setUrl(url);
    // We've switched to a single-source player; mark the queue as stale.
    _queueLoaded = false;

    if (times < 0) {
      await player.setLoopMode(LoopMode.one);
    } else {
      await player.setLoopMode(LoopMode.off);
      _repeatCount = 1;
      _repeatTarget = times;
      _repeatSub = player.playerStateStream.listen((state) async {
        if (state.processingState == ProcessingState.completed) {
          if (_repeatCount < _repeatTarget) {
            _repeatCount++;
            await player.seek(Duration.zero);
            await player.play();
          } else {
            await _cancelExtras();
          }
        }
      });
    }
    await player.play();
  }

  /// Resolve a current playback `index` back to a verse number for UI.
  int? verseNumberForIndex(int index) {
    if (index < 0 || index >= _verses.length) return null;
    return _verses[index].verseNumber;
  }

  Future<void> pause() => player.pause();
  Future<void> resume() => player.play();

  Future<void> stop() async {
    await _cancelExtras();
    await player.stop();
  }

  Future<void> _cancelExtras() async {
    await _stopAfterSub?.cancel();
    _stopAfterSub = null;
    await _repeatSub?.cancel();
    _repeatSub = null;
    if (player.loopMode != LoopMode.off) {
      await player.setLoopMode(LoopMode.off);
    }
  }

  void dispose() {
    _stopAfterSub?.cancel();
    _repeatSub?.cancel();
    player.dispose();
  }
}
