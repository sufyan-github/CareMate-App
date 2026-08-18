import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:caremate/features/more/domain/account_settings_gateway.dart';
import 'package:flutter/material.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({
    required this.accessToken,
    required this.gateway,
    super.key,
  });

  final String accessToken;
  final AccountSettingsGateway gateway;

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String? _locale;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final appPreferences = CareMatePreferencesScope.of(context);
    final copy = CareMateStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(copy.pick('Language and display', 'ভাষা ও প্রদর্শন')),
      ),
      body: SafeArea(
        child: _locale == null && _error == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error case final message?) ...[
                    Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _load,
                      child: Text(copy.pick('Try again', 'আবার চেষ্টা করুন')),
                    ),
                  ],
                  if (_locale != null)
                    RadioGroup<String>(
                      groupValue: _locale,
                      onChanged: _saving ? (_) {} : _select,
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
                  if (_saving) const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    key: const Key('large-text-setting'),
                    value: appPreferences.largeText,
                    onChanged: appPreferences.setLargeText,
                    title: Text(copy.pick('Larger text', 'বড় লেখা')),
                    subtitle: Text(
                      copy.pick(
                        'Makes important CareMate text easier to read.',
                        'CareMate-এর গুরুত্বপূর্ণ লেখা সহজে পড়তে সাহায্য করে।',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        copy.pick(
                          'Your language is saved to your CareMate account. Larger text is saved securely on this phone.',
                          'আপনার ভাষা CareMate অ্যাকাউন্টে সংরক্ষিত থাকে। বড় লেখার পছন্দটি এই ফোনে নিরাপদে সংরক্ষিত থাকে।',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final preferences = await widget.gateway.getPreferences(
        widget.accessToken,
      );
      if (!mounted) return;
      setState(() => _locale = preferences.locale);
      await CareMatePreferencesScope.of(context).setLocale(preferences.locale);
    } on AccountSettingsFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }

  Future<void> _select(String? locale) async {
    if (locale == null || locale == _locale) return;
    final previous = _locale;
    setState(() {
      _error = null;
      _locale = locale;
      _saving = true;
    });
    try {
      final preferences = await widget.gateway.updatePreferences(
        accessToken: widget.accessToken,
        locale: locale,
      );
      if (!mounted) return;
      setState(() => _locale = preferences.locale);
      await CareMatePreferencesScope.of(context).setLocale(preferences.locale);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locale == 'bn-BD'
                ? 'বাংলা আপনার CareMate অ্যাকাউন্টে সংরক্ষণ করা হয়েছে।'
                : 'English was saved to your CareMate account.',
          ),
        ),
      );
    } on AccountSettingsFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = failure.message;
          _locale = previous;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
