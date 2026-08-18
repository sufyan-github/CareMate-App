class DoseAnnouncement {
  const DoseAnnouncement({
    required this.mealRelation,
    required this.medicationName,
    required this.plannedLocalDateTime,
    required this.quantityLabel,
  });

  final String mealRelation;
  final String medicationName;
  final String plannedLocalDateTime;
  final String quantityLabel;

  String get banglaText {
    final clock = plannedLocalDateTime.substring(
      plannedLocalDateTime.length - 5,
    );
    final parts = clock.split(':').map(int.parse).toList(growable: false);
    final hour = parts.first;
    final minute = parts.last;
    final period = switch (hour) {
      < 11 => 'সকাল',
      < 15 => 'দুপুর',
      < 19 => 'সন্ধ্যা',
      _ => 'রাত',
    };
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final minuteText = minute == 0 ? '' : ' ${_banglaNumber(minute)} মিনিট';
    return '$period ${_banglaNumber(displayHour)}টা$minuteText — '
        '$medicationName, ${_quantityInBangla(quantityLabel)}, '
        '${_mealInBangla(mealRelation)}।';
  }

  static String _quantityInBangla(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return value;
    final number = _banglaNumberString(parts.first);
    final unit = parts.skip(1).join(' ').toLowerCase();
    final translatedUnit = switch (unit) {
      'tablet' || 'tablets' => 'ট্যাবলেট',
      'capsule' || 'capsules' => 'ক্যাপসুল',
      'ml' => 'মিলিলিটার',
      'drop' || 'drops' => 'ফোঁটা',
      'puff' || 'puffs' => 'পাফ',
      _ => unit,
    };
    return '$number $translatedUnit'.trim();
  }

  static String _mealInBangla(String value) => switch (value.toUpperCase()) {
    'BEFORE' => 'খাবারের আগে',
    'WITH' => 'খাবারের সাথে',
    'AFTER' => 'খাবারের পরে',
    'EMPTY_STOMACH' => 'খালি পেটে',
    _ => 'নির্দেশনা অনুযায়ী',
  };

  static String _banglaNumber(int value) => _banglaNumberString('$value');

  static String _banglaNumberString(String value) => value.replaceAllMapped(
    RegExp(r'\d'),
    (match) => '০১২৩৪৫৬৭৮৯'[int.parse(match.group(0)!)],
  );
}

class DoseAnnouncementUnavailable implements Exception {
  const DoseAnnouncementUnavailable();
}

abstract interface class DoseAnnouncementService {
  Future<void> speak(DoseAnnouncement announcement);
}
