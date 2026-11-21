import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../../core/router/route_paths.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signIn(_email.text.trim(), _password.text);
    } catch (e) {
      if (mounted) {
        showSnack(context, AppLocalizations.of(context)!.auth_signInFailed, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      showSnack(context, 'Enter your email first');
      return;
    }
    try {
      await ref.read(authRepositoryProvider).resetPassword(_email.text.trim());
      if (mounted) showSnack(context, AppLocalizations.of(context)!.auth_resetSent);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KsmsSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(KsmsSpacing.xl),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: KsmsColors.navy700, borderRadius: KsmsRadii.md),
                            alignment: Alignment.center,
                            child: const Text('K', style: TextStyle(color: KsmsColors.teal400, fontWeight: FontWeight.w800, fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(l.auth_welcomeTitle, style: Theme.of(context).textTheme.headlineSmall)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(l.auth_welcomeSubtitle, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: KsmsSpacing.lg),
                      TextFormField(
                        controller: _email,
                        decoration: InputDecoration(labelText: l.auth_emailLabel),
                        keyboardType: TextInputType.emailAddress,
                        validator: V.email,
                      ),
                      const SizedBox(height: KsmsSpacing.md),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: l.auth_passwordLabel,
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                          ),
                        ),
                        validator: (v) => V.minLength(v, 6),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _forgot,
                          child: Text(l.auth_forgotPassword),
                        ),
                      ),
                      const SizedBox(height: KsmsSpacing.sm),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(l.common_signIn),
                      ),
                      const SizedBox(height: KsmsSpacing.md),
                      OutlinedButton(
                        onPressed: () => context.go(Routes.requestAccess),
                        child: Text(l.auth_requestAccess),
                      ),
                      const SizedBox(height: KsmsSpacing.sm),
                      TextButton(
                        onPressed: () => context.go(Routes.statusCheck),
                        child: Text(l.auth_checkStatus),
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
}
