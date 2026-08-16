import 'package:flutter/material.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _locale = 'en-BD';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose language')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            RadioGroup<String>(
              groupValue: _locale,
              onChanged: _select,
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: 'en-BD',
                    title: Text('English'),
                    subtitle: Text('Bangladesh'),
                  ),
                  RadioListTile<String>(
                    value: 'bn-BD',
                    title: Text('বাংলা'),
                    subtitle: Text('বাংলাদেশ'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Bangla translation is being completed screen by screen. English remains visible where a reviewed Bangla translation is not available.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _select(String? locale) {
    if (locale == null) return;
    setState(() => _locale = locale);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locale == 'bn-BD'
              ? 'বাংলা নির্বাচিত হয়েছে এই ডিভাইসের জন্য।'
              : 'English selected for this device.',
        ),
      ),
    );
  }
}
