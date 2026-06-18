import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model for a single Quran verse from the API
class QuranVerse {
  final int verseNumber;
  final String verseKey;
  final String textUthmani;
  final String? textUthmaniTajweed;
  final String? translationText;
  final List<QuranWord> words;

  QuranVerse({
    required this.verseNumber,
    required this.verseKey,
    required this.textUthmani,
    this.textUthmaniTajweed,
    this.translationText,
    required this.words,
  });

  factory QuranVerse.fromJson(Map<String, dynamic> json) {
    final wordsList = (json['words'] as List? ?? [])
        .where((w) => w['char_type_name'] == 'word')
        .map((w) => QuranWord.fromJson(w))
        .toList();

    // Extract translation text if available
    String? translation;
    final translations = json['translations'] as List?;
    if (translations != null && translations.isNotEmpty) {
      translation = translations[0]['text'] as String?;
    }

    return QuranVerse(
      verseNumber: json['verse_number'] ?? 0,
      verseKey: json['verse_key'] ?? '',
      textUthmani: json['text_uthmani'] ?? '',
      textUthmaniTajweed: json['text_uthmani_tajweed'] as String?,
      translationText: translation,
      words: wordsList,
    );
  }
}

/// Model for a single word within a verse
class QuranWord {
  final int position;
  final String? arabicText;
  final String? arabicTajweed;
  final String? audioUrl;
  final String? translationText;
  final String? transliterationText;

  QuranWord({
    required this.position,
    this.arabicText,
    this.arabicTajweed,
    this.audioUrl,
    this.translationText,
    this.transliterationText,
  });

  factory QuranWord.fromJson(Map<String, dynamic> json) {
    final raw = (json['audio_url'] as String? ?? '').trim();
    final audio = raw.isEmpty
        ? null
        : (raw.startsWith('http')
            ? raw
            : 'https://audio.qurancdn.com/$raw');
    return QuranWord(
      position: json['position'] ?? 0,
      arabicText: json['text_uthmani'] as String?,
      arabicTajweed: json['text_uthmani_tajweed'] as String?,
      audioUrl: audio,
      translationText: json['translation']?['text'],
      transliterationText: json['transliteration']?['text'],
    );
  }
}

/// Model for a Quran reciter (from /resources/recitations)
class Reciter {
  final int id;
  final String reciterName;
  final String? style;
  final String? translatedName;

  Reciter({
    required this.id,
    required this.reciterName,
    this.style,
    this.translatedName,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    final translated = json['translated_name'];
    return Reciter(
      id: json['id'] ?? 0,
      reciterName: json['reciter_name'] ?? json['name'] ?? 'Unknown',
      style: json['style'] as String?,
      translatedName: translated is Map<String, dynamic>
          ? translated['name'] as String?
          : null,
    );
  }
}

/// One verse's audio file for a given reciter
/// (from /recitations/{reciter_id}/by_chapter/{chapter_id})
class VerseAudio {
  final String verseKey;
  final int verseNumber;
  final String audioUrl;

  VerseAudio({
    required this.verseKey,
    required this.verseNumber,
    required this.audioUrl,
  });

  factory VerseAudio.fromJson(Map<String, dynamic> json) {
    final key = json['verse_key'] as String? ?? '';
    final parts = key.split(':');
    final verseNum = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    final raw = (json['url'] as String? ?? '').trim();
    final url = raw.startsWith('http')
        ? raw
        : 'https://verses.quran.com/$raw';
    return VerseAudio(
      verseKey: key,
      verseNumber: verseNum,
      audioUrl: url,
    );
  }
}

/// Service for fetching Quran data from api.quran.com
class QuranApiService {
  QuranApiService._();
  static final instance = QuranApiService._();

  static const _baseUrl = 'https://api.quran.com/api/v4';

  /// Sahih International translation
  static const _translationId = 131;

  List<Reciter>? _recitersCache;

  /// Fetch all verses for a given chapter/surah
  /// Returns parsed [QuranVerse] list
  Future<List<QuranVerse>> getVersesByChapter(int surahId) async {
    final url = Uri.parse(
      '$_baseUrl/verses/by_chapter/$surahId'
      '?language=en'
      '&words=true'
      '&translations=$_translationId'
      '&fields=text_uthmani,text_uthmani_tajweed'
      '&word_fields=text_uthmani,text_uthmani_tajweed,audio_url'
      '&per_page=286', // Max verses in a surah (Al-Baqarah = 286)
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load Surah $surahId: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final verses =
        (data['verses'] as List).map((v) => QuranVerse.fromJson(v)).toList();

    return verses;
  }

  /// Fetch list of available reciters. Cached in memory after first call.
  Future<List<Reciter>> getReciters() async {
    if (_recitersCache != null) return _recitersCache!;
    final url = Uri.parse('$_baseUrl/resources/recitations?language=en');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load reciters: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (data['recitations'] as List)
        .map((r) => Reciter.fromJson(r))
        .toList();
    _recitersCache = list;
    return list;
  }

  /// Fetch per-verse audio URLs for a given reciter + surah
  Future<List<VerseAudio>> getVerseAudios(int reciterId, int surahId) async {
    final url = Uri.parse(
      '$_baseUrl/recitations/$reciterId/by_chapter/$surahId',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load audio for $reciterId/$surahId: ${response.statusCode}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final files = (data['audio_files'] as List? ?? [])
        .map((a) => VerseAudio.fromJson(a))
        .toList();
    return files;
  }
}
