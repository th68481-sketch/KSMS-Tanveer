import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/common.dart';
class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});
  @override State createState() => _TenantsScreenState();
}
class _TenantsScreenState extends State {
  var _q = '';
  late final _f = Supabase.instance.client.from('tenants').select().limit(100);
  String _tenure(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso);
    if (d == null) return 'N/A';
    final days = DateTime.now().difference(d).inDays;
    final months = (days / 30).floor();
    return '$months mos ($days days)';
  }
  void _openDetails(Map t) {
    final joined = (t['created_at'] ?? '').toString();
    final jDate = joined.length >= 10 ? joined.substring(0, 10) : joined;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.domain, color: KsmsColors.teal600), const SizedBox(width: 8), Expanded(child: Text((t['name'] ?? 'School').toString(), style: Theme.of(ctx).textTheme.titleLarge)), StatusChip(status: (t['status'] ?? 'ACTIVE').toString(), dense: true)]),
      const Divider(height: 20),
      ListTile(dense: true, leading: const Icon(Icons.category_outlined), title: const Text('Type & City'), subtitle: Text('${t['type'] ?? 'PRIVATE'} . ${t['city'] ?? 'Karachi'}')),
      ListTile(dense: true, leading: const Icon(Icons.event_available), title: const Text('Owner / School Joining Date'), subtitle: Text(jDate.isEmpty ? 'Recorded on onboarding' : jDate)),
      ListTile(dense: true, leading: const Icon(Icons.timelapse), title: const Text('Active Tenure'), subtitle: Text(_tenure(joined))),
      ListTile(dense: true, leading: const Icon(Icons.folder_shared_outlined, color: KsmsColors.teal600), title: const Text('Attached Documents (15 GB Hybrid Drive)'), subtitle: Text((t['drive_folder_url'] ?? 'Verification docs linked via Onboarding & Google Drive 15 GB Bucket').toString())),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))),
    ])));
  }
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text('Registered Schools & Owners', style: Theme.of(context).textTheme.headlineSmall)), const Chip(label: Text('Super Admin View'))]),
    const SizedBox(height: 10),
    TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search school, city, SEMIS...', isDense: true), onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
    const SizedBox(height: 12),
    Expanded(child: FutureBuilder(future: _f, builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      final all = snap.data is List ? List.of(snap.data as List) : const [];
      final list = _q.isEmpty ? all : all.where((e) => e.toString().toLowerCase().contains(_q)).toList();
      if (list.isEmpty) return const Card(child: Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No schools found. Approve a school request to see details here.'))));
      return ListView.separated(itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (c, i) {
        final t = Map.of(list[i] as Map);
        final joined = (t['created_at'] ?? '').toString();
        final jDate = joined.length >= 10 ? joined.substring(0, 10) : 'N/A';
        return Card(child: ListTile(onTap: () => _openDetails(t), leading: const CircleAvatar(child: Icon(Icons.domain)), title: Text((t['name'] ?? 'School').toString(), style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('${t['city'] ?? ''} . Joined: $jDate (${_tenure(joined)})'), trailing: StatusChip(status: (t['status'] ?? 'ACTIVE').toString(), dense: true)));
      });
    })),
  ]));
}
