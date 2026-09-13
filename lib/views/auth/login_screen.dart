import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/common.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/session_view_model.dart';
import 'widgets/federated_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AuthViewModel auth = context.read<AuthViewModel>();
    final String? uid = await auth.signInWithEmail(_email.text, _password.text);
    if (uid != null && mounted) {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final AuthViewModel auth = context.watch<AuthViewModel>();
    final bool demo = context.read<SessionViewModel>().services.demoMode;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.lg),
              const Center(child: AppLogo(size: 56, vertical: true)),
              const SizedBox(height: AppSpacing.xl),
              Text(s.login, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                decoration: InputDecoration(
                  labelText: s.email,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const <String>[AutofillHints.password],
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: s.password,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => context.push(Routes.forgotPassword),
                  child: Text(s.forgotPassword),
                ),
              ),
              if (auth.hasError) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10nRaw.raw(auth.errorKey!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              BusyButton(label: s.login, busy: auth.busy, onPressed: _submit),
              const SizedBox(height: AppSpacing.md),
              FederatedButtons(
                onDone: () => context.go(Routes.home),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(s.noAccount, style: Theme.of(context).textTheme.bodySmall),
                  TextButton(
                    onPressed: () => context.go(Routes.role),
                    child: Text(s.signup),
                  ),
                ],
              ),
              if (demo) const _DemoCredentialsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Demo builds ship with seeded accounts; showing them beats hiding them in a
/// README nobody opens while holding the phone.
class _DemoCredentialsCard extends StatelessWidget {
  const _DemoCredentialsCard();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.science_outlined, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Demo mode · v${AppConfig.appVersion}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'customer@demo.ht · worker@demo.ht · admin@demo.ht\n'
                'Password: demo1234 — OTP: 123456',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
}
