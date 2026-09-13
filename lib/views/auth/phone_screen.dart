import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../viewmodels/auth_view_model.dart';

/// Phone sign-in and the OTP step that verifies the number.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final AuthViewModel auth = context.watch<AuthViewModel>();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(auth.awaitingCode ? s.otpTitle : s.continueWithPhone),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (auth.awaitingCode) {
              auth.cancelPhoneVerification();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: auth.awaitingCode
              ? _CodeStep(controller: _code, auth: auth)
              : _PhoneStep(controller: _phone, auth: auth),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (auth.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  context.l10nRaw.raw(auth.errorKey!),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            BusyButton(
              label: auth.awaitingCode ? s.verify : s.actionContinue,
              busy: auth.busy,
              onPressed: () async {
                if (!auth.awaitingCode) {
                  await auth.startPhoneVerification(_phone.text);
                  return;
                }
                // Resolve the router before the await: the BuildContext may
                // not be mounted by the time the code is confirmed.
                final GoRouter router = GoRouter.of(context);
                final String? uid = await auth.confirmCode(_code.text);
                if (uid != null) {
                  router.go(Routes.home);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({required this.controller, required this.auth});

  final TextEditingController controller;
  final AuthViewModel auth;

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpacing.lg),
        Text(s.phone, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(s.termsAgree, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: InputDecoration(
            labelText: s.phone,
            prefixText: '+509 ',
            hintText: '3X XX XX XX',
            prefixIcon: const Icon(Icons.smartphone_rounded),
          ),
        ),
      ],
    );
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({required this.controller, required this.auth});

  final TextEditingController controller;
  final AuthViewModel auth;

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpacing.lg),
        Text(s.otpTitle, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          s.otpSubtitle(phone: auth.pendingPhone ?? ''),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, letterSpacing: 12),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(counterText: ''),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: auth.canResend ? auth.resendCode : null,
            child: Text(
              auth.canResend
                  ? s.resendCode
                  : s.resendIn(seconds: auth.resendSeconds),
            ),
          ),
        ),
      ],
    );
  }
}
