import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../viewmodels/auth_view_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final AuthViewModel auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(s.resetPassword)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: s.email,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
              ),
              if (auth.hasError) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10nRaw.raw(auth.errorKey!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              BusyButton(
                label: s.resetPassword,
                busy: auth.busy,
                onPressed: () async {
                  await auth.sendPasswordReset(_email.text);
                  if (!auth.hasError && context.mounted) {
                    showAppSnackBar(context, s.resetEmailSent);
                    context.pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
