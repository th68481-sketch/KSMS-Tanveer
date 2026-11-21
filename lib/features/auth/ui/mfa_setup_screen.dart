import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_providers.dart';
import '../providers/session_controller.dart';

/// Mandatory MFA enrollment for Platform Admins, Tenant Admins and other
/// privileged roles before any dashboard is reachable.
class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  String? _factorId;
  String? _secret;
  String? _uri;
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _enroll() async {
    setState(() => _busy = true);
    try {
      final res = await ref.read(authRepositoryProvider).enrollMfa();
      final totp = res.totp;
      if (totp != null) {
        setState(() {
          _factorId = res.id;
          _secret = totp.secret;
          _uri = totp.uri;
        });
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_factorId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).verifyMfa(_factorId!, _code.text.trim());
      if (mounted) {
        showSnack(context, AppLocalizations.of(context)!.mfa_done);
        await ref.read(sessionProvider.notifier).markMfaConfigured();
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: _secret == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.shield_outlined, size: 40, color: KsmsColors.teal600),
                        const SizedBox(height: 12),
                        Text(l.mfa_title, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(l.mfa_body, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _enroll,
                          child: _busy
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Begin enrollment'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.mfa_secret, style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 6),
                        SelectableText(_secret!, style: Theme.of(context).textTheme.bodyMedium),
                        if (_uri != null) ...[
                          const SizedBox(height: 8),
                          SelectableText(_uri!, style: Theme.of(context).textTheme.bodySmall),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _code,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(labelText: l.mfa_code, counterText: ''),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _busy ? null : _verify,
                          child: _busy
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(l.mfa_verify),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
