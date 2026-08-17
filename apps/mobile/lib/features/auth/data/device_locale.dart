import 'dart:ui';

String careMateDeviceLocale() =>
    PlatformDispatcher.instance.locale.languageCode == 'bn' ? 'bn-BD' : 'en-BD';
