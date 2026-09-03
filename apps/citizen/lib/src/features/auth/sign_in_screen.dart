import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../language/locale_controller.dart';

/// Mobile-number sign-in for citizens (PRD 5.1, FR-001).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isBusy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final isVerifying = auth.stage == AuthStage.awaitingOtp;
    final locale = ref.watch(localeControllerProvider);
    final isTamil = locale?.languageCode == 'ta';

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.signIn),
        actions: [
          TextButton.icon(
            onPressed: () {
              final next = isTamil ? AmLocales.english : AmLocales.tamil;
              ref.read(localeControllerProvider.notifier).choose(next);
            },
            icon: const Icon(Icons.translate, size: 18),
            label: Text(
              isTamil ? 'English' : 'தமிழ்',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AmTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isVerifying ? strings.enterOtp : strings.phoneNumber,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AmTokens.spaceSm),
              Text(strings.signInHelp, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AmTokens.spaceSm),
              if (!isVerifying)
                AmBanner.info(
                  message: 'Local Test: 9876500002 / OTP: 123456',
                ),
              const SizedBox(height: AmTokens.spaceLg),

              if (auth.failure != null) ...[
                AmFailureBanner(failure: auth.failure!),
                const SizedBox(height: AmTokens.spaceLg),
              ],

              if (!isVerifying)
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: theme.textTheme.headlineSmall,
                  decoration: InputDecoration(
                    labelText: strings.phoneNumber,
                    prefixText: '+91 ',
                  ),
                )
              else ...[
                Text(
                  auth.pendingPhone ?? '',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AmTokens.spaceMd),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  style: theme.textTheme.headlineSmall,
                  decoration: InputDecoration(labelText: strings.enterOtp),
                ),
              ],

              const SizedBox(height: AmTokens.spaceLg),
              AmBigButton(
                label: isVerifying ? strings.verify : strings.sendOtp,
                icon: isVerifying ? Icons.check : Icons.sms_outlined,
                isBusy: _isBusy,
                onPressed: _isBusy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isBusy = true);
    final controller = ref.read(authControllerProvider.notifier);
    final isVerifying =
        ref.read(authControllerProvider).stage == AuthStage.awaitingOtp;

    if (isVerifying) {
      await controller.verifyPhoneCode(_codeController.text);
    } else {
      await controller.requestPhoneCode(_phoneController.text);
    }

    if (mounted) setState(() => _isBusy = false);
  }
}
