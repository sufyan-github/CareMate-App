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
    final awaitingOtp =
        widget.coordinator.status == AuthStatus.awaitingOtp &&
        widget.coordinator.challenge != null;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: colors.primary,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      awaitingOtp
                          ? 'Check your messages'
                          : 'Your medicines, right on time',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      awaitingOtp
                          ? 'Enter the code sent to ${widget.coordinator.challenge!.deliveryHint}.'
                          : 'Sign in with your Bangladesh mobile number. We will send a one-time verification code.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (awaitingOtp)
                      ..._otpFields(context)
                    else
                      ..._phoneFields(),
                    if (widget.coordinator.errorMessage
                        case final message?) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline, color: colors.error),
                              const SizedBox(width: 10),
                              Expanded(child: Text(message)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
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
                                  ? 'Verify and continue'
                                  : 'Send verification code',
                            ),
                    ),
                    if (awaitingOtp) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: widget.coordinator.isBusy
                            ? null
                            : widget.coordinator.changePhoneNumber,
                        child: const Text('Use a different number'),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'By continuing, you agree to CareMate’s Terms and Privacy Policy. Standard SMS charges may apply.',
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

  List<Widget> _phoneFields() {
    return [
      TextFormField(
        key: const Key('phone-input'),
        controller: _phoneController,
        autofocus: false,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.telephoneNumber],
        decoration: const InputDecoration(
          labelText: 'Mobile number',
          hintText: '01700 123456',
          prefixIcon: Icon(Icons.phone_android),
          helperText: 'Bangladesh numbers only (+880)',
        ),
        onFieldSubmitted: (_) => _requestCode(),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Enter your mobile number'
            : null,
      ),
    ];
  }

  List<Widget> _otpFields(BuildContext context) {
    final challenge = widget.coordinator.challenge!;
    return [
      if (challenge.isDevelopment) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.science_outlined),
              SizedBox(width: 10),
              Expanded(child: Text('Development mode: use code 123456')),
            ],
          ),
        ),
        const SizedBox(height: 18),
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
        decoration: const InputDecoration(
          labelText: '6-digit code',
          hintText: '123456',
          prefixIcon: Icon(Icons.lock_outline),
        ),
        onFieldSubmitted: (_) => _verify(),
        validator: (value) =>
            value?.length == 6 ? null : 'Enter the complete 6-digit code',
      ),
      const SizedBox(height: 10),
      Text(
        challenge.resendAfterSeconds > 0
            ? 'You can request another code after ${challenge.resendAfterSeconds} seconds.'
            : 'Did not receive it? Go back and request another code.',
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
