import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/domain.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_providers.dart';
import '../data/auth_repository.dart';

class RequestAccessScreen extends ConsumerStatefulWidget {
  const RequestAccessScreen({super.key});

  @override
  ConsumerState<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends ConsumerState<RequestAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _staffFormKey = GlobalKey<FormState>();

  // School fields
  final _institution = TextEditingController();
  final _campusName = TextEditingController();
  final _city = TextEditingController();
  final _semis = TextEditingController();

  // Staff fields
  final _schoolQuery = TextEditingController();
  final _role = TextEditingController();

  // Shared
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  TenantType _type = TenantType.private;
  String? _selectedTenantId;
  List<Map<String, dynamic>> _tenantOptions = [];
  List<(String name, List<int> bytes, String mime)> _files = [];
  bool _busy = false;

  static const _staffRoles = [
    'principal', 'vice_principal', 'registrar', 'accountant', 'teacher', 'hr_officer', 'ops_officer',
  ];

  @override
  void dispose() {
    for (final c in [_institution, _campusName, _city, _semis, _schoolQuery, _role, _name, _email, _phone, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _showRefDialog(String requestId, String email) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save or copy your reference code to track approval status:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      requestId,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy Reference',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: requestId));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Reference code copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Email: $email', style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: requestId));
              Navigator.pop(ctx);
              context.go(Routes.statusCheck);
            },
            child: const Text('Copy & Check Status'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(Routes.statusCheck);
            },
            child: const Text('Check Status'),
          ),
        ],
      ),
    );
  }


  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (res == null) return;
    setState(() {
      for (final f in res.files) {
        if (f.bytes != null) {
          _files.add((f.name, f.bytes!, f.name.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg'));
        }
      }
    });
  }

  Future<void> _searchTenants(String q) async {
    if (q.trim().length < 2) return;
    try {
      final rows = await ref.read(authRepositoryProvider).lookupTenants(q.trim());
      setState(() => _tenantOptions = rows);
    } catch (_) {
      setState(() => _tenantOptions = []);
    }
  }

  Future<void> _submitSchool() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final requestId = await repo.submitSchoolRegistration(
        institutionName: _institution.text.trim(),
        institutionType: _type.value,
        campusName: _campusName.text.trim(),
        city: _city.text.trim(),
        semisCode: _semis.text.trim().isEmpty ? null : _semis.text.trim(),
        requesterName: _name.text.trim(),
        requesterEmail: _email.text.trim(),
        requesterPhone: _phone.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (_files.isNotEmpty) {
        await repo.uploadEvidence(
          requestId,
          _files.map((f) => UploadedFile(name: f.$1, bytes: f.$2, contentType: f.$3)).toList(),
        );
      }
      if (mounted) {
        await _showRefDialog(requestId, _email.text.trim());
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitStaff() async {
    if (!_staffFormKey.currentState!.validate()) return;
    if (_selectedTenantId == null) {
      showSnack(context, AppLocalizations.of(context)!.req_selectSchool, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final requestId = await repo.submitStaffAccess(
        tenantId: _selectedTenantId!,
        campusId: '',
        requestedRole: _role.text.trim(),
        requesterName: _name.text.trim(),
        requesterEmail: _email.text.trim(),
        requesterPhone: _phone.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (_files.isNotEmpty) {
        await repo.uploadEvidence(
          requestId,
          _files.map((f) => UploadedFile(name: f.$1, bytes: f.$2, contentType: f.$3)).toList(),
        );
      }
      if (mounted) {
        await _showRefDialog(requestId, _email.text.trim());
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
      appBar: AppBar(title: Text(l.auth_requestAccess), leading: BackButton(onPressed: () => context.go(Routes.welcome))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DefaultTabController(
            length: 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(KsmsSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(tabs: [
                      Tab(text: l.req_schoolTitle),
                      Tab(text: l.req_staffTitle),
                    ]),
                    const SizedBox(height: KsmsSpacing.md),
                    Flexible(
                      child: TabBarView(
                        children: [_schoolForm(l), _staffForm(l)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _schoolForm(AppLocalizations l) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: KsmsSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _institution,
              decoration: InputDecoration(labelText: l.req_institutionName),
              validator: V.required,
            ),
            const SizedBox(height: KsmsSpacing.sm),
            SegmentedButton<TenantType>(
              segments: const [
                ButtonSegment(value: TenantType.private, label: Text('Private')),
                ButtonSegment(value: TenantType.government, label: Text('Government')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: KsmsSpacing.sm),
            TextFormField(
              controller: _campusName,
              decoration: InputDecoration(labelText: l.req_campusName),
              validator: V.required,
            ),
            const SizedBox(height: KsmsSpacing.sm),
            TextFormField(
              controller: _city,
              decoration: InputDecoration(labelText: l.common_city),
              validator: V.required,
            ),
            if (_type == TenantType.government) ...[
              const SizedBox(height: KsmsSpacing.sm),
              TextFormField(
                controller: _semis,
                decoration: InputDecoration(labelText: l.req_semisCode),
              ),
            ],
            const SizedBox(height: KsmsSpacing.md),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l.req_requesterName),
              validator: V.required,
            ),
            const SizedBox(height: KsmsSpacing.sm),
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l.req_requesterEmail),
              keyboardType: TextInputType.emailAddress,
              validator: V.email,
            ),
            const SizedBox(height: KsmsSpacing.sm),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(labelText: l.req_requesterPhone),
              keyboardType: TextInputType.phone,
              validator: V.phone,
            ),
            const SizedBox(height: KsmsSpacing.sm),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.common_notes),
            ),
            const SizedBox(height: KsmsSpacing.md),
            _evidencePicker(l),
            const SizedBox(height: KsmsSpacing.md),
            FilledButton(
              onPressed: _busy ? null : _submitSchool,
              child: _busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.req_submit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _staffForm(AppLocalizations l) {
    return Form(
      key: _staffFormKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: KsmsSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _schoolQuery,
              decoration: InputDecoration(labelText: l.req_selectSchool),
              onChanged: _searchTenants,
            ),
            if (_tenantOptions.isNotEmpty)
              ..._tenantOptions.map((t) => RadioListTile<String>(
                    value: t['id'] as String,
                    groupValue: _selectedTenantId,
                    title: Text((t['name'] as String?) ?? ''),
                    subtitle: Text((t['city'] as String?) ?? ''),
                    onChanged: (v) => setState(() {
                      _selectedTenantId = v;
                    }),
                  )),
            const SizedBox(height: KsmsSpacing.sm),
            DropdownButtonFormField<String>(
              value: _role.text.isEmpty ? null : _role.text,
              decoration: InputDecoration(labelText: l.req_requestedRole),
              items: _staffRoles
                  .map((r) => DropdownMenuItem(value: r, child: Text(F.humanize(r))))
                  .toList(),
              onChanged: (v) => setState(() => _role.text = v ?? ''),
              validator: V.required,
            ),
            const SizedBox(height: KsmsSpacing.md),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l.req_requesterName),
              validator: V.required,
            ),
            const SizedBox(height: KsmsSpacing.sm),
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l.req_requesterEmail),
              keyboardType: TextInputType.emailAddress,
              validator: V.email,
            ),
            const SizedBox(height: KsmsSpacing.sm),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(labelText: l.req_requesterPhone),
              keyboardType: TextInputType.phone,
              validator: V.phone,
            ),
            const SizedBox(height: KsmsSpacing.sm),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.common_notes),
            ),
            const SizedBox(height: KsmsSpacing.md),
            _evidencePicker(l),
            const SizedBox(height: KsmsSpacing.md),
            FilledButton(
              onPressed: _busy ? null : _submitStaff,
              child: _busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.req_submit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _evidencePicker(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l.req_evidence, style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file, size: 18),
              label: Text(l.req_addFiles),
            ),
          ],
        ),
        ..._files.map((f) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(children: [
                const Icon(Icons.insert_drive_file, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(f.$1, overflow: TextOverflow.ellipsis)),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _files.remove(f)),
                ),
              ]),
            )),
      ],
    );
  }
}
