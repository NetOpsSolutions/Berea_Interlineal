import 'package:flutter/material.dart';

import '../../data/database_service.dart';
import '../../data/models.dart';
import 'book_summary_sheet.dart';

class BookSummariesScreen extends StatefulWidget {
  final void Function(String bookId, int chapter, int verse)? onOpenVerse;

  const BookSummariesScreen({
    super.key,
    this.onOpenVerse,
  });

  @override
  State<BookSummariesScreen> createState() => _BookSummariesScreenState();
}

class _BookSummariesScreenState extends State<BookSummariesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BookSummary> _allSummaries = [];
  List<BookSummary> _filteredSummaries = [];
  bool _loading = true;
  String _testamentFilter = 'all'; // 'all', 'OT', 'NT'
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _loadSummaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSummaries() async {
    final list = await DatabaseService.instance.getAllBookSummaries();
    if (mounted) {
      setState(() {
        _allSummaries = list;
        _filteredSummaries = list;
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredSummaries = _allSummaries.where((s) {
        final matchesQuery = q.isEmpty ||
            s.bookName.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q) ||
            s.authorName.toLowerCase().contains(q) ||
            s.keyVerseRef.toLowerCase().contains(q);

        final matchesTestament = _testamentFilter == 'all' || s.testament == _testamentFilter;
        final matchesCategory = _categoryFilter == null || s.category == _categoryFilter;

        return matchesQuery && matchesTestament && matchesCategory;
      }).toList();
    });
  }

  List<String> get _availableCategories {
    final set = <String>{};
    for (final s in _allSummaries) {
      if (_testamentFilter == 'all' || s.testament == _testamentFilter) {
        set.add(s.category);
      }
    }
    return set.toList();
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
        title: const Text('Resumen de los 66 Libros'),
        backgroundColor: isDark ? const Color(0xFF14110E) : const Color(0xFFEDE4CE),
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Buscar libro por nombre, autor, género o tema...',
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
                ButtonSegment(value: 'all', label: Text('Canon (66)')),
                ButtonSegment(value: 'OT', label: Text('Antiguo T. (39)')),
                ButtonSegment(value: 'NT', label: Text('Nuevo T. (27)')),
              ],
              selected: {_testamentFilter},
              onSelectionChanged: (val) {
                _testamentFilter = val.first;
                _categoryFilter = null;
                _applyFilter();
              },
            ),
          ),

          // Chips horizontales de Géneros/Categorías
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos los géneros'),
                  selected: _categoryFilter == null,
                  onSelected: (selected) {
                    setState(() {
                      _categoryFilter = null;
                      _applyFilter();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ..._availableCategories.map((cat) {
                  final isSelected = _categoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _categoryFilter = selected ? cat : null;
                          _applyFilter();
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Lista de Libros
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSummaries.isEmpty
                    ? Center(
                        child: Text(
                          'No se encontraron libros para el criterio especificado.',
                          style: TextStyle(color: bodyColor),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        itemCount: _filteredSummaries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final summary = _filteredSummaries[index];
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
                                BookSummarySheet.show(
                                  context,
                                  summary: summary,
                                  onOpenVerse: widget.onOpenVerse,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: accentGold.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: accentGold.withValues(alpha: 0.3)),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '#${summary.bookId}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: accentGold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    summary.bookName,
                                                    style: TextStyle(
                                                      fontSize: 16.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: titleColor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: accentGold.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      summary.category,
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: accentGold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Autor: ${summary.authorName} • Fecha: ${summary.dateWritten}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? const Color(0xFFA89F91) : const Color(0xFF6B5A4B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.menu_book_rounded,
                                            size: 20,
                                            color: accentGold,
                                          ),
                                          tooltip: 'Leer libro en el interlineal',
                                          onPressed: () {
                                            if (widget.onOpenVerse != null) {
                                              widget.onOpenVerse!(summary.bookCode, 1, 1);
                                              Navigator.of(context).pop();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      summary.keyThemes,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.35,
                                        color: bodyColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.star_rounded, size: 14, color: accentGold),
                                        const SizedBox(width: 5),
                                        Text(
                                          summary.keyVerseRef,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: accentGold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Toca para ver ficha completa',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF8C7E70) : const Color(0xFF9E8F7C),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
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
