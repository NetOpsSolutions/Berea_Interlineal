import 'package:flutter/material.dart';

import '../../data/database_service.dart';
import '../../data/models.dart';
import 'author_detail_screen.dart';

class BiblicalAuthorsScreen extends StatefulWidget {
  final void Function(String bookId, int chapter, int verse)? onOpenVerse;

  const BiblicalAuthorsScreen({
    super.key,
    this.onOpenVerse,
  });

  @override
  State<BiblicalAuthorsScreen> createState() => _BiblicalAuthorsScreenState();
}

class _BiblicalAuthorsScreenState extends State<BiblicalAuthorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BiblicalAuthor> _allAuthors = [];
  List<BiblicalAuthor> _filteredAuthors = [];
  bool _loading = true;
  String _testamentFilter = 'all'; // 'all', 'OT', 'NT'

  @override
  void initState() {
    super.initState();
    _loadAuthors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthors() async {
    final list = await DatabaseService.instance.getAllBiblicalAuthors();
    if (mounted) {
      setState(() {
        _allAuthors = list;
        _filteredAuthors = list;
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredAuthors = _allAuthors.where((a) {
        final matchesQuery = q.isEmpty ||
            a.nameEs.toLowerCase().contains(q) ||
            a.nameOriginal.toLowerCase().contains(q) ||
            a.occupation.toLowerCase().contains(q) ||
            a.era.toLowerCase().contains(q) ||
            (a.strongCode?.toLowerCase().contains(q) ?? false);

        bool matchesTestament = true;
        if (_testamentFilter == 'OT') {
          matchesTestament = a.authorId <= 27; // Moisés hasta Mardoqueo
        } else if (_testamentFilter == 'NT') {
          matchesTestament = a.authorId >= 28; // Mateo hasta Judas
        }

        return matchesQuery && matchesTestament;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF181412) : const Color(0xFFF7F1E1);
    final cardBg = isDark ? const Color(0xFF241D19) : const Color(0xFFEDE4CE);
    final borderColor = isDark ? const Color(0xFF3D3025) : const Color(0xFFDFCFAF);
    final accentGold = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    final titleColor = isDark ? const Color(0xFFFDFBF7) : const Color(0xFF261D17);
    final bodyColor = isDark ? const Color(0xFFE5DDD0) : const Color(0xFF3D3025);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Biografías de Escritores Sagrados'),
        backgroundColor: isDark ? const Color(0xFF14110E) : const Color(0xFFEDE4CE),
      ),
      body: Column(
        children: [
          // Barra de Búsqueda de Autores
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, hebreo, griego o Strong (ej. Pablo, G3972)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filtro por Testamento
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('Todos (35)')),
                ButtonSegment(value: 'OT', label: Text('Antiguo T. (27)')),
                ButtonSegment(value: 'NT', label: Text('Nuevo T. (8)')),
              ],
              selected: {_testamentFilter},
              onSelectionChanged: (val) {
                _testamentFilter = val.first;
                _applyFilter();
              },
            ),
          ),

          const SizedBox(height: 8),

          // Lista de Autores
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAuthors.isEmpty
                    ? Center(
                        child: Text(
                          'No se encontraron escritores que coincidan con la búsqueda.',
                          style: TextStyle(color: bodyColor),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _filteredAuthors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final author = _filteredAuthors[index];
                          return Card(
                            color: cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: borderColor, width: 0.9),
                            ),
                            elevation: 0,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AuthorDetailScreen(
                                      author: author,
                                      onOpenVerse: widget.onOpenVerse,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: accentGold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: accentGold, width: 1.0),
                                      ),
                                      child: Center(
                                        child: Text(
                                          author.nameEs.characters.first,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: accentGold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                author.nameEs,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: titleColor,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                author.nameOriginal,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: author.strongCode?.startsWith('H') == true
                                                      ? 'EzraSIL'
                                                      : 'GentiumPlus',
                                                  color: accentGold,
                                                ),
                                              ),
                                              if (author.strongCode != null) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: accentGold.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    author.strongCode!,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: accentGold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            author.occupation,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? const Color(0xFFA89F91) : const Color(0xFF6B5A4B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            author.era,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: accentGold.withValues(alpha: 0.9),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: isDark ? const Color(0xFF706456) : const Color(0xFFB5A48F),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
