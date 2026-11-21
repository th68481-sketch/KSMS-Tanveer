import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_settings.dart';
import '../../../core/constants/domain.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_providers.dart';
import '../providers/session_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final _name = TextEditingController(
      text: (ref.read(sessionProvider).valueOrNull?.profile['full_name'] as String?) ?? '');
  final _phone = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            fullName: _name.text.trim(),
            locale: ref.read(appSettingsProvider).localeCode,
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          );
      await ref.read(sessionProvider.notifier).refreshContext();
      if (mounted) showSnack(context, AppLocalizations.of(context)!.common_save);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final session = ref.watch(sessionProvider).valueOrNull;
    final role = session?.primaryRole;
    final requiresMfa = role != null && mfaRequiredRoles.contains(role.key);
    final mfaEnabled = !requiresMfa || session?.phase == SessionPhase.active;

    return Scaffold(
      appBar: AppBar(title: Text(l.profile_title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.profile_fullName, style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      TextField(controller: _name),
                      const SizedBox(height: 12),
                      Text(l.common_phone, style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: (session?.profile['phone'] as String?) ?? '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(l.profile_locale, style: Theme.of(context).textTheme.labelLarge),
                          const Spacer(),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'en', label: Text('EN')),
                              ButtonSegment(value: 'ur', label: Text('اردو')),
                            ],
                            selected: {ref.watch(appSettingsProvider).localeCode},
                            onSelectionChanged: (s) =>
                                ref.read(appSettingsProvider.notifier).setLocale(s.first),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(l.profile_mfa, style: Theme.of(context).textTheme.labelLarge),
                          const Spacer(),
                          Chip(
                            label: Text(mfaEnabled ? l.profile_mfaOn : l.profile_mfaOff),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _save,
                        child: _busy
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(l.common_save),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
