import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/design_tokens.dart';
class NoticesBoardScreen extends ConsumerStatefulWidget {
  const NoticesBoardScreen({super.key});
  @override ConsumerState createState() => _NoticesBoardScreenState();
}
class _NoticesBoardScreenState extends ConsumerState {
  var _q = '';
  late final _f = Supabase.instance.client.from('notices').select().limit(50);
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notices & Headlines'), actions: [Padding(padding: const EdgeInsets.only(right: 12), child: FilledButton.icon(onPressed: () => context.push('/school/notices/compose'), icon: const Icon(Icons.add, size: 18), label: const Text('New Headline')))]),
    body: FutureBuilder(future: _f, builder: (context, snap) {
      final all = snap.data is List ? List.of(snap.data as List) : const [];
      final list = _q.isEmpty ? all : all.where((r) => r.toString().toLowerCase().contains(_q)).toList();
      final top = list.isNotEmpty ? Map.of(list.first as Map) : null;
      final headline = top != null ? (top['headline'] ?? top['title'] ?? 'Latest Announcement').toString() : 'Welcome to KSMS Notice Board - Post a new headline'; 
      return ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: KsmsColors.navy800, borderRadius: KsmsRadii.sm), child: Row(children: [const Icon(Icons.campaign, color: KsmsColors.teal400), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('HEADLINE / ANNOUNCEMENT', style: TextStyle(color: KsmsColors.teal400, fontSize: 10.5, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(headline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))]))])),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search notices...'), onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
        const SizedBox(height: 12),
        for (final item in list) Builder(builder: (c) { final n = Map.of(item as Map); return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: const CircleAvatar(child: Icon(Icons.notifications_active_outlined)), title: Text((n['headline'] ?? n['title'] ?? 'Notice').toString(), style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text((n['body'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis))); }),
      ]);
    }),
  );
}
