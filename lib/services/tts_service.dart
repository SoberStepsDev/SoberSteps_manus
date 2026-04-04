import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import 'crash_service.dart';

class TtsService {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _ttsInitialized = false;

  bool get _hasElevenLabsKey =>
      AppConstants.elevenLabsApiKey.isNotEmpty;

  Future<void> _initTts() async {
    if (_ttsInitialized) return;
    await Future.microtask(() async {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(0.95);
    });
    _ttsInitialized = true;
  }

  /// Call once at app start to warm up TTS engine off the critical path
  static void warmUp() {
    Future.delayed(const Duration(seconds: 3), () => TtsService()._initTts());
  }

  /// PRO — plays ElevenLabs .mp3 from assets
  Future<void> playAsset(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e, s) {
      debugPrint('[TtsService] playAsset error: $e');
      await CrashService.recordError(e, s);
    }
  }

  /// ElevenLabs (Patryk) — for key messages when online + API key set
  Future<bool> _speakViaElevenLabs(String text) async {
    if (!_hasElevenLabsKey || text.isEmpty) return false;
    try {
      final uri = Uri.parse(
        'https://api.elevenlabs.io/v1/text-to-speech/${AppConstants.elevenLabsVoiceId}?output_format=mp3_44100_128',
      );
      final res = await http.post(
        uri,
        headers: {
          'xi-api-key': AppConstants.elevenLabsApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'text': text, 'model_id': 'eleven_multilingual_v2'}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return false;
      await _player.stop();
      await _player.play(BytesSource(Uint8List.fromList(res.bodyBytes), mimeType: 'audio/mpeg'));
      return true;
    } catch (e, s) {
      debugPrint('[TtsService] ElevenLabs fallback: $e');
      await CrashService.recordError(e, s);
      return false;
    }
  }

  /// Key messages: ElevenLabs (Patryk) when available, else device TTS
  Future<void> speak(String text) async {
    if (await _speakViaElevenLabs(text)) return;
    try {
      await _initTts();
      await _tts.stop();
      await _tts.speak(text);
    } catch (e, s) {
      debugPrint('[TtsService] speak error: $e');
      await CrashService.recordError(e, s);
    }
  }

  /// Milestone — PRO plays mp3, FREE uses ElevenLabs then device TTS
  Future<void> speakMilestone({required bool isPremium, required int days, required String freeFallback}) async {
    if (isPremium) {
      await playAsset('audio/milestones/milestone_${days}d.mp3');
    } else {
      await speak(freeFallback);
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}
