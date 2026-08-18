import 'package:caremate/features/simple_mode/domain/dose_announcement_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FlutterTtsDoseAnnouncementService implements DoseAnnouncementService {
  FlutterTtsDoseAnnouncementService({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  final FlutterTts _flutterTts;

  @override
  Future<void> speak(DoseAnnouncement announcement) async {
    final language = await _availableBanglaLanguage();
    if (language == null) throw const DoseAnnouncementUnavailable();
    await _flutterTts.stop();
    await _flutterTts.setLanguage(language);
    await _flutterTts.setSpeechRate(0.42);
    await _flutterTts.setPitch(1);
    await _flutterTts.setVolume(1);
    await _flutterTts.awaitSpeakCompletion(true);
    final result = await _flutterTts.speak(announcement.banglaText);
    if (result != 1) throw const DoseAnnouncementUnavailable();
  }

  Future<String?> _availableBanglaLanguage() async {
    for (final language in const ['bn-BD', 'bn-IN']) {
      final available = await _flutterTts.isLanguageAvailable(language);
      if (available == true || available == 1) return language;
    }
    return null;
  }
}
