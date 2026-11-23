import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/common.dart';
class NoticesComposeScreen extends ConsumerStatefulWidget {
  const NoticesComposeScreen({super.key});
  @override ConsumerState createState() => _NoticesComposeScreenState();
}
class _NoticesComposeScreenState extends ConsumerState {
  final _h = TextEditingController(), _b = TextEditingController();
  var _p = 'HIGHLIGHT', _busy = false;
  @override void dispose() { _h.dispose(); _b.dispose(); super.dispose(); }
  Future _save() async {
    if (_h.text.trim().isEmpty) { showSnack(context, 'Enter notice headline', error: true); return; }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.from('notices').insert({'title': _h.text.trim(), 'headline': _h.text.trim(), 'body': _b.text.trim().isEmpty ? _h.text.trim() : _b.text.trim(), 'priority': _p});
      if (mounted) { showSnack(context, 'Headline Published'); context.go(Routes.notices); }
    } catch (e) { if (mounted) showSnack(context, e.toString(), error: true); } finally { if (mounted) setState(() => _busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Compose Notice Headline')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: ListView(padding: const EdgeInsets.all(16), children: [Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: _h, decoration: const InputDecoration(labelText: 'Notice Headline')),
      const SizedBox(height: 12),
      TextField(controller: _b, maxLines: 4, decoration: const InputDecoration(labelText: 'Announcement Details')),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: _busy ? null : _save, icon: const Icon(Icons.campaign), label: Text(_busy ? 'Publishing...' : 'Publish Headline')),
    ])))])))
  );
}
