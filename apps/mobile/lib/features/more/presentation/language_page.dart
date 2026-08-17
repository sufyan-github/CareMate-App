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
    return Scaffold(
      appBar: AppBar(title: const Text('Choose language')),
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
                      child: const Text('Try again'),
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
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Your choice is saved to your CareMate account and follows you across devices. Bangla translation is being completed screen by screen; reviewed English remains visible where Bangla copy is not yet available.',
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
      if (mounted) setState(() => _locale = preferences.locale);
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
