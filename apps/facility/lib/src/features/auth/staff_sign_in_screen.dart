import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Staff sign-in against an administrator-provisioned account (PRD FR-001).
///
/// There is no self-registration here. A facility role carries the power to
/// accept referrals and publish readiness, so accounts are created and scoped by
/// an administrator (PRD 4, FR-002).
class StaffSignInScreen extends ConsumerStatefulWidget {
  const StaffSignInScreen({super.key});

  @override
  ConsumerState<StaffSignInScreen> createState() => _StaffSignInScreenState();
}

class _StaffSignInScreenState extends ConsumerState<StaffSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBusy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AmTokens.spaceLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AmTokens.spaceLg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.local_hospital_outlined,
                        size: 48,
                        color: AmTokens.primary,
                      ),
                      const SizedBox(height: AmTokens.spaceMd),
                      Text(
                        strings.appName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        strings.staffSignIn,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AmTokens.spaceLg),

                      if (auth.failure != null) ...[
                        AmFailureBanner(failure: auth.failure!),
                        const SizedBox(height: AmTokens.spaceMd),
                      ],

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        decoration:
                            InputDecoration(labelText: strings.emailAddress),
                        validator: (value) =>
                            (value == null || !value.contains('@'))
                                ? strings.errorInvalidInput
                                : null,
                      ),
                      const SizedBox(height: AmTokens.spaceMd),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: strings.password,
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? strings.errorInvalidInput
                            : null,
                      ),
                      const SizedBox(height: AmTokens.spaceLg),
                      FilledButton.icon(
                        onPressed: _isBusy ? null : _submit,
                        icon: _isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(strings.signIn),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isBusy = true);
    await ref.read(authControllerProvider.notifier).signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (mounted) setState(() => _isBusy = false);
  }
}
