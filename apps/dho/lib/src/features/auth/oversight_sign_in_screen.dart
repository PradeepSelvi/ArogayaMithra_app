import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sign-in for district and state officials (PRD FR-001, FR-002).
class OversightSignInScreen extends ConsumerStatefulWidget {
  const OversightSignInScreen({super.key});

  @override
  ConsumerState<OversightSignInScreen> createState() =>
      _OversightSignInScreenState();
}

class _OversightSignInScreenState
    extends ConsumerState<OversightSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBusy = false;

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
                        Icons.insights_outlined,
                        size: 48,
                        color: AmTokens.primary,
                      ),
                      const SizedBox(height: AmTokens.spaceMd),
                      Text(
                        strings.dashboardTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AmTokens.spaceLg),

                      if (auth.failure != null) ...[
                        AmFailureBanner(failure: auth.failure!),
                        const SizedBox(height: AmTokens.spaceMd),
                      ],

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
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
                        obscureText: true,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(labelText: strings.password),
                        validator: (value) => (value == null || value.isEmpty)
                            ? strings.errorInvalidInput
                            : null,
                      ),
                      const SizedBox(height: AmTokens.spaceLg),
                      FilledButton.icon(
                        onPressed: _isBusy ? null : _submit,
                        icon: const Icon(Icons.login),
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
