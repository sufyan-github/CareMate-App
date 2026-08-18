import 'package:caremate/app/design/caremate_tokens.dart';
import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:caremate/app/widgets/caremate_status_card.dart';
import 'package:caremate/features/auth/application/auth_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthFlowPage extends StatefulWidget {
  const AuthFlowPage({required this.coordinator, super.key});

  final AuthCoordinator coordinator;

  @override
  State<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<AuthFlowPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = CareMateStrings.of(context);
    final awaitingOtp =
        widget.coordinator.status == AuthStatus.awaitingOtp &&
        widget.coordinator.challenge != null;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              CareMateSpacing.xl,
              CareMateSpacing.xxl,
              CareMateSpacing.xl,
              CareMateSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CareMateLayout.maxContentWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      image: true,
                      label: 'CareMate',
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ExcludeSemantics(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                CareMateRadii.large,
                              ),
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: colors.primary,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: CareMateSpacing.xl),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        avatar: const Icon(Icons.shield_outlined, size: 18),
                        label: Text(
                          copy.pick(
                            'Private • Review-first',
                            'গোপনীয় • আগে যাচাই',
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(height: CareMateSpacing.sm),
                    Text(
                      awaitingOtp
                          ? copy.pick(
                              'Check your messages',
                              'আপনার বার্তা দেখুন',
                            )
                          : copy.pick(
                              'Your medicines, right on time',
                              'সঠিক সময়ে আপনার ওষুধ',
                            ),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    const SizedBox(height: CareMateSpacing.sm),
                    Text(
                      awaitingOtp
                          ? copy.pick(
                              'Enter the code sent to ${widget.coordinator.challenge!.deliveryHint}.',
                              '${widget.coordinator.challenge!.deliveryHint} নম্বরে পাঠানো কোড লিখুন।',
                            )
                          : copy.pick(
                              'Sign in with your Bangladesh mobile number. We will send a one-time verification code.',
                              'আপনার বাংলাদেশি মোবাইল নম্বর দিয়ে সাইন ইন করুন। আমরা একবার ব্যবহারযোগ্য যাচাই কোড পাঠাব।',
                            ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: CareMateSpacing.xl),
                    if (awaitingOtp)
                      ..._otpFields(context)
                    else
                      ..._phoneFields(context),
                    if (widget.coordinator.errorMessage
                        case final message?) ...[
                      const SizedBox(height: CareMateSpacing.md),
                      CareMateStatusCard(
                        actionLabel: copy.pick('Try again', 'আবার চেষ্টা করুন'),
                        icon: Icons.error_outline,
                        liveRegion: true,
                        message: message,
                        onAction: awaitingOtp ? _verify : _requestCode,
                        title: copy.pick(
                          'Could not continue',
                          'এগিয়ে যাওয়া যায়নি',
                        ),
                        tone: CareMateStatusTone.error,
                      ),
                    ],
                    const SizedBox(height: CareMateSpacing.xl),
                    FilledButton(
                      onPressed: widget.coordinator.isBusy
                          ? null
                          : awaitingOtp
                          ? _verify
                          : _requestCode,
                      child: widget.coordinator.isBusy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              awaitingOtp
                                  ? copy.pick(
                                      'Verify and continue',
                                      'যাচাই করে এগিয়ে যান',
                                    )
                                  : copy.pick(
                                      'Send verification code',
                                      'যাচাই কোড পাঠান',
                                    ),
                            ),
                    ),
                    if (awaitingOtp) ...[
                      const SizedBox(height: CareMateSpacing.sm),
                      TextButton(
                        onPressed: widget.coordinator.isBusy
                            ? null
                            : widget.coordinator.changePhoneNumber,
                        child: Text(
                          copy.pick(
                            'Use a different number',
                            'অন্য নম্বর ব্যবহার করুন',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: CareMateSpacing.lg),
                    Text(
                      copy.pick(
                        'By continuing, you agree to CareMate’s Terms and Privacy Policy. Standard SMS charges may apply.',
                        'এগিয়ে গেলে আপনি CareMate-এর শর্তাবলি ও গোপনীয়তা নীতিতে সম্মতি দিচ্ছেন। সাধারণ SMS খরচ প্রযোজ্য হতে পারে।',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _phoneFields(BuildContext context) {
    final copy = CareMateStrings.of(context);
    return [
      TextFormField(
        key: const Key('phone-input'),
        controller: _phoneController,
        autofocus: false,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.telephoneNumber],
        decoration: InputDecoration(
          labelText: copy.pick('Mobile number', 'মোবাইল নম্বর'),
          hintText: '01700 123456',
          prefixIcon: const Icon(Icons.phone_android),
          helperText: copy.pick(
            'Bangladesh numbers only (+880)',
            'শুধু বাংলাদেশের নম্বর (+৮৮০)',
          ),
        ),
        onFieldSubmitted: (_) => _requestCode(),
        validator: (value) => value == null || value.trim().isEmpty
            ? copy.pick('Enter your mobile number', 'আপনার মোবাইল নম্বর লিখুন')
            : null,
      ),
    ];
  }

  List<Widget> _otpFields(BuildContext context) {
    final copy = CareMateStrings.of(context);
    final challenge = widget.coordinator.challenge!;
    return [
      if (challenge.isDevelopment) ...[
        CareMateStatusCard(
          icon: Icons.science_outlined,
          message: copy.pick(
            'No SMS was sent. Use code 123456 only for this development build.',
            'কোনো SMS পাঠানো হয়নি। শুধু এই ডেভেলপমেন্ট বিল্ডে 123456 কোড ব্যবহার করুন।',
          ),
          title: copy.pick('Demo sign-in', 'ডেমো সাইন-ইন'),
          tone: CareMateStatusTone.warning,
        ),
        const SizedBox(height: CareMateSpacing.lg),
      ],
      TextFormField(
        key: const Key('otp-input'),
        controller: _otpController,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          labelText: copy.pick('6-digit code', '৬ সংখ্যার কোড'),
          hintText: '123456',
          prefixIcon: const Icon(Icons.lock_outline),
        ),
        onFieldSubmitted: (_) => _verify(),
        validator: (value) => value?.length == 6
            ? null
            : copy.pick(
                'Enter the complete 6-digit code',
                'সম্পূর্ণ ৬ সংখ্যার কোড লিখুন',
              ),
      ),
      const SizedBox(height: CareMateSpacing.xs),
      Text(
        challenge.resendAfterSeconds > 0
            ? copy.pick(
                'You can request another code after ${challenge.resendAfterSeconds} seconds.',
                '${challenge.resendAfterSeconds} সেকেন্ড পরে নতুন কোড চাইতে পারবেন।',
              )
            : copy.pick(
                'Did not receive it? Go back and request another code.',
                'কোড পাননি? ফিরে গিয়ে নতুন কোড চান।',
              ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }

  Future<void> _requestCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.coordinator.requestOtp(_phoneController.text);
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.coordinator.verifyOtp(_otpController.text);
  }
}
