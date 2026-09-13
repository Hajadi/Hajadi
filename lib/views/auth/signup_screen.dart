import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/haiti_departments.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/app_user.dart';
import '../../viewmodels/auth_view_model.dart';
import 'widgets/federated_buttons.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  HaitiDepartment _department = HaitiDepartment.ouest;
  String _city = HaitiDepartment.ouest.cities.first;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AuthViewModel auth = context.read<AuthViewModel>();
    final String? uid = await auth.signUpWithEmail(
      fullName: _name.text,
      email: _email.text,
      password: _password.text,
      confirmPassword: _confirm.text,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      departmentId: _department.id,
      city: _city,
    );
    if (uid == null || !mounted) {
      return;
    }
    // A new worker lands on their dashboard, where verification is the first
    // thing asked of them; a customer goes straight to browsing.
    context.go(auth.role == UserRole.worker ? Routes.dashboard : Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final AuthViewModel auth = context.watch<AuthViewModel>();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.signup)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SegmentedButton<UserRole>(
                segments: <ButtonSegment<UserRole>>[
                  ButtonSegment<UserRole>(
                    value: UserRole.customer,
                    label: Text(s.iAmCustomer),
                    icon: const Icon(Icons.search_rounded, size: 18),
                  ),
                  ButtonSegment<UserRole>(
                    value: UserRole.worker,
                    label: Text(s.iAmWorker),
                    icon: const Icon(Icons.handyman_rounded, size: 18),
                  ),
                ],
                selected: <UserRole>{auth.role},
                onSelectionChanged: (Set<UserRole> selection) =>
                    auth.setRole(selection.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: s.fullName,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: s.email,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '${s.phone} (${s.optional})',
                  hintText: '+509 3X XX XX XX',
                  prefixIcon: const Icon(Icons.smartphone_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<HaitiDepartment>(
                initialValue: _department,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s.filterDepartment,
                  prefixIcon: const Icon(Icons.map_outlined),
                ),
                items: <DropdownMenuItem<HaitiDepartment>>[
                  for (final HaitiDepartment department
                      in HaitiDepartment.values)
                    DropdownMenuItem<HaitiDepartment>(
                      value: department,
                      child: Text(department.label(s)),
                    ),
                ],
                onChanged: (HaitiDepartment? value) {
                  if (value != null) {
                    setState(() {
                      _department = value;
                      _city = value.cities.first;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _city,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s.filterCity,
                  prefixIcon: const Icon(Icons.location_city_outlined),
                ),
                items: <DropdownMenuItem<String>>[
                  for (final String city in _department.cities)
                    DropdownMenuItem<String>(value: city, child: Text(city)),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _city = value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _password,
                obscureText: _obscure,
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
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _confirm,
                obscureText: _obscure,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: s.confirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
              ),
              if (auth.hasError) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10nRaw.raw(auth.errorKey!),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(s.termsAgree, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              BusyButton(label: s.signup, busy: auth.busy, onPressed: _submit),
              const SizedBox(height: AppSpacing.md),
              FederatedButtons(onDone: () => context.go(Routes.home)),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(s.alreadyHaveAccount, style: theme.textTheme.bodySmall),
                  TextButton(
                    onPressed: () => context.go(Routes.login),
                    child: Text(s.login),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
