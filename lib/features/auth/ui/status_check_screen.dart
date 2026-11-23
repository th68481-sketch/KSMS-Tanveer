import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_providers.dart';

/// Public status checker: works without an account using reference + email.
class StatusCheckScreen extends ConsumerStatefulWidget {
  const StatusCheckScreen({super.key});

  @override
  ConsumerState<StatusCheckScreen> createState() => _StatusCheckScreenState();
}

class _StatusCheckScreenState extends ConsumerState<StatusCheckScreen> {
  final _ref = TextEditingController();
  final _email = TextEditingController();
  Map<String, dynamic>? _result;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ref.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await ref
          .read(authRepositoryProvider)
          .checkStatus(_ref.text, _email.text);
      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.req_statusTitle), leading: BackButton(onPressed: () => context.go(Routes.welcome))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KsmsSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _ref,
                  decoration: InputDecoration(
                    labelText: l.req_reference,
                    hintText: 'KSMS-XXXXXXXX',
                  ),
                ),
                const SizedBox(height: KsmsSpacing.sm),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l.req_requesterEmail),
                ),
                const SizedBox(height: KsmsSpacing.md),
                FilledButton(
                  onPressed: _busy ? null : _check,
                  child: _busy
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l.auth_checkStatus),
                ),
                if (_error != null) ...[
                  const SizedBox(height: KsmsSpacing.md),
                  Text(_error!, style: const TextStyle(color: KsmsColors.danger)),
                ],
                if (_result != null) ...[
                  const SizedBox(height: KsmsSpacing.lg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(KsmsSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusChip(status: (_result!['state'] as String?) ?? ''),
                          const SizedBox(height: KsmsSpacing.md),
                          if (_result!['institution_name'] != null)
                            Text(_result!['institution_name'] as String,
                                style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: KsmsSpacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Ref: ${(_result!['reference_code'] ?? _result!['id'] ?? _ref.text.trim())}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  final code = (_result!['reference_code'] ?? _result!['id'] ?? _ref.text.trim()).toString();
                                  Clipboard.setData(ClipboardData(text: code));
                                  showSnack(context, 'Reference copied!');
                                },
                              ),
                            ],
                          ),
                          Text(
                            'Submitted: ${(_result!['submitted_at']?.toString() ?? '').length >= 10 ? _result!['submitted_at'].toString().substring(0, 10) : (_result!['submitted_at']?.toString() ?? '')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_result!['decision_reason'] != null) ...[
                            const SizedBox(height: KsmsSpacing.sm),
                            Text('${l.common_reason}: ${_result!['decision_reason']}',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
