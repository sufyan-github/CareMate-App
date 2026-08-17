import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:caremate/app/widgets/caremate_status_card.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:flutter/material.dart';

class InviteCaregiverPage extends StatefulWidget {
  const InviteCaregiverPage({
    required this.accessToken,
    required this.gateway,
    required this.profileId,
    super.key,
  });

  final String accessToken;
  final CareAccessGateway gateway;
  final String profileId;

  @override
  State<InviteCaregiverPage> createState() => _InviteCaregiverPageState();
}

class _InviteCaregiverPageState extends State<InviteCaregiverPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _canViewPlan = true;
  bool _canReceiveMissedDoseAlerts = true;
  bool _canViewDoseOutcomes = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = CareMateStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(copy.pick('Invite caregiver', 'সহায়তাকারীকে আমন্ত্রণ')),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              CareMateStatusCard(
                icon: Icons.lock_person_outlined,
                message: copy.pick(
                  'Access starts only after acceptance. In this demo build, the invitation appears after this number signs in; no SMS is sent.',
                  'গ্রহণ করার পরেই অনুমতি চালু হবে। এই ডেমো বিল্ডে নম্বরটি দিয়ে সাইন ইন করলে আমন্ত্রণ দেখা যাবে; কোনো SMS পাঠানো হবে না।',
                ),
                title: copy.pick('Consent first', 'আগে সম্মতি'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('caregiver-phone-input'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: copy.pick(
                    'Caregiver mobile number',
                    'সহায়তাকারীর মোবাইল নম্বর',
                  ),
                  prefixText: '+88 ',
                ),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  return RegExp(r'^01[3-9]\d{8}$').hasMatch(digits)
                      ? null
                      : copy.pick(
                          'Enter a valid Bangladesh mobile number',
                          'সঠিক বাংলাদেশি মোবাইল নম্বর লিখুন',
                        );
                },
              ),
              const SizedBox(height: 22),
              Text(
                copy.pick('Permissions', 'অনুমতিসমূহ'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _canViewPlan,
                onChanged: (value) => setState(() {
                  _canViewPlan = value ?? false;
                  if (!_canViewPlan) _canViewDoseOutcomes = false;
                }),
                title: Text(
                  copy.pick(
                    'View confirmed medication plan',
                    'নিশ্চিত করা ওষুধের পরিকল্পনা দেখুন',
                  ),
                ),
                subtitle: Text(
                  copy.pick(
                    'Does not allow changing medicines',
                    'ওষুধ পরিবর্তনের অনুমতি দেয় না',
                  ),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _canViewDoseOutcomes,
                onChanged: !_canViewPlan
                    ? null
                    : (value) =>
                          setState(() => _canViewDoseOutcomes = value ?? false),
                title: Text(
                  copy.pick(
                    'View reported dose outcomes',
                    'রিপোর্ট করা ডোজের ফল দেখুন',
                  ),
                ),
                subtitle: Text(
                  copy.pick(
                    'Shows confirmed, skipped, and missed app records',
                    'নিশ্চিত, বাদ দেওয়া ও মিস হওয়া অ্যাপ রেকর্ড দেখায়',
                  ),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _canReceiveMissedDoseAlerts,
                onChanged: (value) => setState(
                  () => _canReceiveMissedDoseAlerts = value ?? false,
                ),
                title: Text(
                  copy.pick(
                    'Receive missed-dose alerts',
                    'মিস হওয়া ডোজের সতর্কতা পান',
                  ),
                ),
                subtitle: Text(
                  copy.pick(
                    'Available after reminders are enabled',
                    'রিমাইন্ডার চালু হলে পাওয়া যাবে',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('send-caregiver-invitation-button'),
                onPressed: _isSaving ? null : _submit,
                child: Text(
                  _isSaving
                      ? copy.pick(
                          'Creating invitation…',
                          'আমন্ত্রণ তৈরি হচ্ছে…',
                        )
                      : copy.pick('Review invitation', 'আমন্ত্রণ যাচাই করুন'),
                ),
              ),
              if (_error case final message?) ...[
                const SizedBox(height: 12),
                CareMateStatusCard(
                  liveRegion: true,
                  message: message,
                  title: copy.pick(
                    'Could not create invitation',
                    'আমন্ত্রণ তৈরি হয়নি',
                  ),
                  tone: CareMateStatusTone.error,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_canViewPlan && !_canReceiveMissedDoseAlerts) {
      final copy = CareMateStrings.of(context);
      setState(
        () => _error = copy.pick(
          'Choose at least one caregiver permission.',
          'সহায়তাকারীর জন্য অন্তত একটি অনুমতি বেছে নিন।',
        ),
      );
      return;
    }
    if (!await _confirmInvitation()) return;
    setState(() {
      _error = null;
      _isSaving = true;
    });
    try {
      await widget.gateway.createInvitation(
        accessToken: widget.accessToken,
        phoneNumber: _phone.text,
        profileId: widget.profileId,
        permissions: CarePermissions(
          canReceiveMissedDoseAlerts: _canReceiveMissedDoseAlerts,
          canViewMedicationPlan: _canViewPlan,
          canViewDoseOutcomes: _canViewDoseOutcomes,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on CareAccessFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmInvitation() async {
    final copy = CareMateStrings.of(context);
    final permissions = <String>[
      if (_canViewPlan)
        copy.pick('View medication plan', 'ওষুধের পরিকল্পনা দেখা'),
      if (_canViewDoseOutcomes)
        copy.pick('View dose outcomes', 'ডোজের ফল দেখা'),
      if (_canReceiveMissedDoseAlerts)
        copy.pick('Receive missed-dose alerts', 'মিস ডোজের সতর্কতা পাওয়া'),
    ];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          copy.pick('Create this invitation?', 'এই আমন্ত্রণ তৈরি করবেন?'),
        ),
        content: Text(
          copy.pick(
            'Invited number: +88 ${_phone.text.trim()}\n\nShared permissions:\n• ${permissions.join('\n• ')}\n\nNo access starts until the recipient accepts.',
            'আমন্ত্রিত নম্বর: +88 ${_phone.text.trim()}\n\nযে অনুমতিগুলো শেয়ার হবে:\n• ${permissions.join('\n• ')}\n\nগ্রহণ না করা পর্যন্ত কোনো অনুমতি চালু হবে না।',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(copy.pick('Go back', 'ফিরে যান')),
          ),
          FilledButton(
            key: const Key('confirm-caregiver-invitation-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(copy.pick('Create invitation', 'আমন্ত্রণ তৈরি করুন')),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
