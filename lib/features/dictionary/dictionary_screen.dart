import 'package:flutter/material.dart';

import '../../data/database_service.dart';
import '../../data/models.dart';
import 'strong_detail_screen.dart';

class DictionaryScreen extends StatefulWidget {
  final String initialLanguage;
  const DictionaryScreen({super.key, required this.initialLanguage});
  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  late String _language = widget.initialLanguage;
  final _c = TextEditingController();
  List<StrongEntry> _results = [];
  bool _loading = false;
  String? _error;

  @override void initState() { super.initState(); _search(''); }
  @override void dispose() { _c.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await DatabaseService.instance.searchStrong(_language, q);
      setState(() { _results = r; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _changeLang(String l) { setState(() => _language = l); _search(_c.text); }
  String _lbl(String l) => l == 'greek' ? 'Griego' : 'Hebreo';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Diccionario Strong ${_lbl(_language)}')),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        SegmentedButton<String>(segments: const [
          ButtonSegment(value: 'greek', label: Text('Griego'), icon: Icon(Icons.translate)),
          ButtonSegment(value: 'hebrew', label: Text('Hebreo'), icon: Icon(Icons.language)),
        ], selected: {_language}, onSelectionChanged: (s) => _changeLang(s.first)),
        const SizedBox(height: 16),
        TextField(controller: _c, onChanged: _search, decoration: InputDecoration(
          hintText: _language == 'greek' ? 'Buscar código, λόγος, logos…' : 'Buscar código, אלהים, Elohim…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _c.text.isNotEmpty ? IconButton(onPressed: () { _c.clear(); _search(''); }, icon: const Icon(Icons.close)) : null)),
        const SizedBox(height: 16),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator())
            : _error != null ? Center(child: Text(_error!))
            : _results.isEmpty ? Center(child: Text('Sin resultados.\nCorre crawler + build_assets para el dataset completo.',
                textAlign: TextAlign.center, style: t.textTheme.bodyMedium))
            : ListView.separated(itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final it = _results[i];
                  final he = it.language == 'hebrew';
                  return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    title: Row(children: [
                      Expanded(child: Directionality(textDirection: he ? TextDirection.rtl : TextDirection.ltr,
                        child: Text(it.lemma, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleMedium))),
                      const SizedBox(width: 8),
                      Text('#${it.code}', style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    ]),
                    subtitle: Text(it.pronunciation.isEmpty ? it.definition : '${it.pronunciation} — ${it.definition}',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.push(ctx, MaterialPageRoute(
                        builder: (_) => StrongDetailScreen(language: it.language, code: it.code))));
                })),
      ]))),
    );
  }
}
