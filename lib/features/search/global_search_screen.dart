import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/database_service.dart';
import '../../data/models.dart';
import '../dictionary/strong_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  final void Function(String bookId, int chapter, int verse)? onOpenVerse;

  const GlobalSearchScreen({super.key, this.onOpenVerse});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  GlobalSearchResult? _result;
  String _filter = 'all'; // 'all', 'bible', 'greek', 'hebrew'

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _loading = false;
        _result = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);

    try {
      final res = await DatabaseService.instance.globalSearch(q);
      if (mounted) {
        setState(() {
          _result = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _quickSearch(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    _executeSearch(term);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda Global'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de búsqueda unificada
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _controller,
                onChanged: _onQueryChanged,
                onSubmitted: _executeSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar en Biblia + Strong (ej: Jn 1:1, amor, G25)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            _onQueryChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Filtros de categoría
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _filterChip(
                    label: 'Todos',
                    value: 'all',
                    count: _result?.totalCount,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Biblia',
                    value: 'bible',
                    count: _result != null
                        ? (_result!.verses.length +
                            (_result!.directReference != null ? 1 : 0))
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Griego Strong',
                    value: 'greek',
                    count: _result?.greekEntries.length,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Hebreo Strong',
                    value: 'hebrew',
                    count: _result?.hebrewEntries.length,
                  ),
                ],
              ),
            ),

            const Divider(height: 16),

            // Contenido
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _result == null
                      ? _buildEmptySuggestions(theme)
                      : _buildResultsList(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
    int? count,
  }) {
    final isSelected = _filter == value;
    final text = count != null ? '$label ($count)' : label;

    return FilterChip(
      selected: isSelected,
      label: Text(text),
      onSelected: (_) {
        setState(() => _filter = value);
      },
    );
  }

  Widget _buildEmptySuggestions(ThemeData theme) {
    final suggestions = [
      'Jn 1:1',
      'Génesis 1:1',
      'G25',
      'H7225',
      'amor',
      'principio',
      'fe',
      'gracia',
      'logos',
      'luz',
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(
          Icons.manage_search,
          size: 64,
          color: theme.colorScheme.primary.withAlpha(128),
        ),
        const SizedBox(height: 12),
        Text(
          'Busca simultáneamente en las Sagradas Escrituras y en los diccionarios Strong griego y hebreo.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Sugerencias de búsqueda rápida:',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) {
            return ActionChip(
              avatar: const Icon(Icons.arrow_outward, size: 16),
              label: Text(s),
              onPressed: () => _quickSearch(s),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsList(ThemeData theme) {
    final r = _result!;
    if (r.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 56, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'No se encontraron resultados para "${r.query}".',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Prueba con otra palabra clave, código Strong o referencia como "Jn 3:16".',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final showDirect = (_filter == 'all' || _filter == 'bible') &&
        r.directReference != null;
    final showVerses = (_filter == 'all' || _filter == 'bible') &&
        r.verses.isNotEmpty;
    final showGreek = (_filter == 'all' || _filter == 'greek') &&
        r.greekEntries.isNotEmpty;
    final showHebrew = (_filter == 'all' || _filter == 'hebrew') &&
        r.hebrewEntries.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Referencia directa
        if (showDirect) ...[
          _buildDirectReferenceCard(r.directReference!, theme),
          const SizedBox(height: 16),
        ],

        // Versículos bíblicos
        if (showVerses) ...[
          _buildSectionHeader(
            icon: Icons.menu_book,
            title: 'Versículos bíblicos',
            count: r.verses.length,
            theme: theme,
          ),
          const SizedBox(height: 8),
          ...r.verses.map((v) => _buildVerseTile(v, theme)),
          const SizedBox(height: 16),
        ],

        // Diccionario Strong Griego
        if (showGreek) ...[
          _buildSectionHeader(
            icon: Icons.translate,
            title: 'Diccionario Strong Griego',
            count: r.greekEntries.length,
            theme: theme,
          ),
          const SizedBox(height: 8),
          ...r.greekEntries.map((e) => _buildStrongTile(e, theme)),
          const SizedBox(height: 16),
        ],

        // Diccionario Strong Hebreo
        if (showHebrew) ...[
          _buildSectionHeader(
            icon: Icons.language,
            title: 'Diccionario Strong Hebreo',
            count: r.hebrewEntries.length,
            theme: theme,
          ),
          const SizedBox(height: 8),
          ...r.hebrewEntries.map((e) => _buildStrongTile(e, theme)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildDirectReferenceCard(VerseSearchResult v, ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Referencia Directa: ${v.reference}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => _openVerse(v),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Abrir'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              v.translation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildVerseTile(VerseSearchResult v, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          v.reference,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            v.translation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openVerse(v),
      ),
    );
  }

  Widget _buildStrongTile(StrongEntry e, ThemeData theme) {
    final isHebrew = e.language == 'hebrew';
    final prefix = isHebrew ? 'H' : 'G';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#$prefix${e.code}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Directionality(
                textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
                child: Text(
                  e.lemma,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (e.pronunciation.isNotEmpty)
              Text(
                '(${e.pronunciation})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            e.definition.isNotEmpty ? e.definition : e.rvDefinition,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StrongDetailScreen(
                language: e.language,
                code: e.code,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openVerse(VerseSearchResult v) {
    if (widget.onOpenVerse != null) {
      widget.onOpenVerse!(v.bookId, v.chapter, v.verse);
    }
  }
}
