import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Field worker sign-in (PRD 5.2).
///
/// The session persists, so a worker signs in once and keeps working through
/// patchy connectivity rather than being logged out in a village with no signal
/// (PRD 15).
class WorkerSignInScreen extends ConsumerStatefulWidget {
  const WorkerSignInScreen({super.key});

  @override
  ConsumerState<WorkerSignInScreen> createState() => _WorkerSignInScreenState();
}

class _WorkerSignInScreenState extends ConsumerState<WorkerSignInScreen> {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AmTokens.spaceLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AmTokens.spaceXl),
                const Icon(
                  Icons.volunteer_activism_outlined,
                  size: 64,
                  color: AmTokens.primary,
                ),
                const SizedBox(height: AmTokens.spaceMd),
                Text(
                  strings.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                Text(
                  strings.staffSignIn,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AmTokens.spaceXl),

                if (auth.failure != null) ...[
                  AmFailureBanner(failure: auth.failure!),
                  const SizedBox(height: AmTokens.spaceMd),
                ],

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: strings.emailAddress),
                  validator: (value) => (value == null || !value.contains('@'))
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
                AmBigButton(
                  label: strings.signIn,
                  icon: Icons.login,
                  isBusy: _isBusy,
                  onPressed: _isBusy ? null : _submit,
                ),
              ],
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
