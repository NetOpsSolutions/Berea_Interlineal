import 'package:flutter/material.dart';

import '../../data/database_service.dart';
import '../../data/models.dart';
import '../../data/study_service.dart';
import 'strong_detail_screen.dart';

class DictionaryScreen extends StatefulWidget {
  final String initialLanguage;
  final GlobalKey? tourControlsKey;
  final GlobalKey? tourFirstItemKey;
  final GlobalKey? tourSimilaritiesKey;
  final GlobalKey? tourDerivedFamilyKey;
  final VoidCallback? onOpenDrawer;
  final bool showExegesisSections;

  const DictionaryScreen({
    super.key,
    required this.initialLanguage,
    this.tourControlsKey,
    this.tourFirstItemKey,
    this.tourSimilaritiesKey,
    this.tourDerivedFamilyKey,
    this.onOpenDrawer,
    this.showExegesisSections = true,
  });
  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  late String _language = widget.initialLanguage;
  final _c = TextEditingController();
  List<StrongEntry> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await DatabaseService.instance.searchStrong(_language, q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _changeLang(String l) {
    setState(() => _language = l);
    _search(_c.text);
  }

  String _lbl(String l) => l == 'greek' ? 'Griego' : 'Hebreo';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return ListenableBuilder(
      listenable: StudyService.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            leading: widget.onOpenDrawer != null
                ? IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    tooltip: 'Menú persiana de estudio',
                    onPressed: widget.onOpenDrawer,
                  )
                : null,
            title: Text('Diccionario Strong ${_lbl(_language)}'),
            actions: [
              IconButton(
                icon: Icon(
                  t.brightness == Brightness.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: t.brightness == Brightness.dark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFB45309),
                ),
                tooltip: t.brightness == Brightness.dark
                    ? 'Cambiar a modo claro (☀️ Pergamino Diurno)'
                    : 'Cambiar a modo oscuro (🌙 Noche Alejandrina)',
                onPressed: () => StudyService.instance.toggleTheme(),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Column(
                    key: widget.tourControlsKey,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'greek',
                            label: Text('Griego'),
                            icon: Icon(Icons.translate),
                          ),
                          ButtonSegment(
                            value: 'hebrew',
                            label: Text('Hebreo'),
                            icon: Icon(Icons.language),
                          ),
                        ],
                        selected: {_language},
                        onSelectionChanged: (s) => _changeLang(s.first),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _c,
                        onChanged: _search,
                        decoration: InputDecoration(
                          hintText: _language == 'greek'
                              ? 'Buscar código, λόγος, logos…'
                              : 'Buscar código, אלהים, Elohim…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _c.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _c.clear();
                                    _search('');
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_c.text.isEmpty)
                    _ExegesisShowcaseCard(
                      tourStepBibleKey: widget.tourFirstItemKey,
                      tourSimilaritiesKey: widget.tourSimilaritiesKey,
                      tourDerivedFamilyKey: widget.tourDerivedFamilyKey,
                      showExegesisSections: widget.showExegesisSections,
                      onOpenStrong: (lang, code) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StrongDetailScreen(
                              language: lang,
                              code: code,
                              showExegesisSections: widget.showExegesisSections,
                            ),
                          ),
                        );
                      },
                    ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(child: Text(_error!))
                            : _results.isEmpty
                                ? Center(
                                    child: Text(
                                      'Sin resultados.\nCorre crawler + build_assets para el dataset completo.',
                                      textAlign: TextAlign.center,
                                      style: t.textTheme.bodyMedium,
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _results.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (ctx, i) {
                                      final it = _results[i];
                                      final he = it.language == 'hebrew';
                                      return ListTile(
                                        key: (i == 0 && _c.text.isNotEmpty)
                                            ? widget.tourFirstItemKey
                                            : null,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Directionality(
                                                textDirection:
                                                    he ? TextDirection.rtl : TextDirection.ltr,
                                                child: Text(
                                                  it.lemma,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: StudyService.instance.originalScriptStyle(
                                                    isHebrew: he,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: t.colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '#${it.code}',
                                              style: t.textTheme.labelMedium?.copyWith(
                                                color: t.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          it.pronunciation.isEmpty
                                              ? it.definition
                                              : '${it.pronunciation} — ${it.definition}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () => Navigator.push(
                                          ctx,
                                          MaterialPageRoute(
                                            builder: (_) => StrongDetailScreen(
                                              language: it.language,
                                              code: it.code,
                                              showExegesisSections: widget.showExegesisSections,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tarjeta demostrativa del módulo léxico y exegético.
/// Ofrece acceso directo a las derivaciones STEPBible, comparaciones teológicas y árboles de palabras derivadas.
class _ExegesisShowcaseCard extends StatelessWidget {
  final GlobalKey? tourStepBibleKey;
  final GlobalKey? tourSimilaritiesKey;
  final GlobalKey? tourDerivedFamilyKey;
  final bool showExegesisSections;
  final void Function(String language, int code) onOpenStrong;

  const _ExegesisShowcaseCard({
    this.tourStepBibleKey,
    this.tourSimilaritiesKey,
    this.tourDerivedFamilyKey,
    this.showExegesisSections = true,
    required this.onOpenStrong,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D15) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                showExegesisSections
                    ? 'Módulo Exegético • Novedad v1.3.7'
                    : 'Léxico y Derivaciones • STEPBible',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 1. Etimologías y Léxico STEPBible (Tyndale House)
          Container(
            key: tourStepBibleKey,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14202C) : Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBAE6FD),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.translate_rounded, size: 14, color: Color(0xFF0284C7)),
                    const SizedBox(width: 5),
                    Text(
                      '100% Derivaciones y Léxico STEPBible',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildSkyChip(
                      label: 'G3056 logos ➔ de G3004 legō',
                      isDark: isDark,
                      onTap: () => onOpenStrong('greek', 3056),
                    ),
                    _buildSkyChip(
                      label: 'H7225 reshít ➔ de H7218 rosh',
                      isDark: isDark,
                      onTap: () => onOpenStrong('hebrew', 7225),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (showExegesisSections) ...[
            const SizedBox(height: 8),

            // 2. Similitudes y Comparaciones Teológicas
            Container(
              key: tourSimilaritiesKey,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1712) : Colors.white.withAlpha(200),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF523315) : const Color(0xFFFCD34D),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.balance_rounded, size: 14, color: Color(0xFFD97706)),
                      const SizedBox(width: 5),
                      Text(
                        'Similitudes y Comparaciones Teológicas',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildGoldenChip(
                        label: 'H776 érets vs H127 adamáh',
                        isDark: isDark,
                        onTap: () => onOpenStrong('hebrew', 776),
                      ),
                      _buildGoldenChip(
                        label: 'G25 agapáo vs G5368 philéo',
                        isDark: isDark,
                        onTap: () => onOpenStrong('greek', 25),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. Familias de Palabras Derivadas (Árbol Léxico)
            Container(
              key: tourDerivedFamilyKey,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161F1A) : Colors.white.withAlpha(200),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF1B4D3E) : const Color(0xFFA7F3D0),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_tree_rounded, size: 14, color: Color(0xFF059669)),
                      const SizedBox(width: 5),
                      Text(
                        'Árbol Léxico y Familias Derivadas',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildEmeraldChip(
                        label: 'H776 érets ➔ H777 arqá • H778 ará',
                        isDark: isDark,
                        onTap: () => onOpenStrong('hebrew', 776),
                      ),
                      _buildEmeraldChip(
                        label: 'G3056 logos ➔ G3004 legō',
                        isDark: isDark,
                        onTap: () => onOpenStrong('greek', 3056),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkyChip({
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F2338) : const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 12,
              color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0369A1),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0369A1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldenChip({
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF332214) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF92400E) : const Color(0xFFF59E0B),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 12,
              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmeraldChip({
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF142920) : const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF047857) : const Color(0xFF10B981),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 12,
              color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
