import 'package:flutter/material.dart';
import '../../data/study_service.dart';

class BereaDrawer extends StatelessWidget {
  final VoidCallback onOpenBookSummaries;
  final VoidCallback onOpenAuthors;
  final VoidCallback onOpenSearch;
  final void Function(String colorKey) onSelectTheologicalHighlight;
  final VoidCallback onOpenSettings;
  final VoidCallback onStartTour;
  final GlobalKey? tourTheologicalKey;

  const BereaDrawer({
    super.key,
    required this.onOpenBookSummaries,
    required this.onOpenAuthors,
    required this.onOpenSearch,
    required this.onSelectTheologicalHighlight,
    required this.onOpenSettings,
    required this.onStartTour,
    this.tourTheologicalKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF1B1613) : const Color(0xFFF7F1E1);
    final borderColor =
        isDark ? const Color(0xFF3D3025) : const Color(0xFFDFCFAF);
    final sectionTitleColor =
        isDark ? const Color(0xFFD4A373) : const Color(0xFF8C531B);

    return Drawer(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 1.0),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(0)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabecera solemne estilo Pergamino Alejandrino
            _buildHeader(context, isDark),

            const SizedBox(height: 8),

            // SECCIÓN 1: Fondo Histórico y Enciclopedia
            _buildSectionHeader('FONDO HISTÓRICO Y ENCICLOPEDIA', sectionTitleColor),
            _buildDrawerTile(
              context,
              icon: Icons.history_edu_rounded,
              iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
              title: 'Resumen de los 66 Libros',
              subtitle: 'Autor, fecha, contexto, temas y aplicación',
              onTap: () {
                Navigator.of(context).pop();
                onOpenBookSummaries();
              },
            ),
            _buildDrawerTile(
              context,
              icon: Icons.person_search_rounded,
              iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              title: 'Biografías de Escritores',
              subtitle: 'Vida, llamamiento y legado en hebreo y griego',
              onTap: () {
                Navigator.of(context).pop();
                onOpenAuthors();
              },
            ),

            const Divider(indent: 16, endIndent: 16, height: 24),

            // SECCIÓN 2: Investigación
            _buildSectionHeader('INVESTIGACIÓN', sectionTitleColor),
            _buildDrawerTile(
              context,
              icon: Icons.search_rounded,
              iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
              title: 'Búsqueda Global',
              subtitle: 'Biblia, léxico Strong y concordancia unificada',
              onTap: () {
                Navigator.of(context).pop();
                onOpenSearch();
              },
            ),

            const Divider(indent: 16, endIndent: 16, height: 24),

            // SECCIÓN 3: Resaltados Teológicos (Acceso Rápido a Mi Estudio)
            Container(
              key: tourTheologicalKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'RESALTADOS TEOLÓGICOS (MI ESTUDIO)',
                    sectionTitleColor,
                  ),
                  _buildHighlightTile(
                    context,
                    color: const Color(0xFFF59E0B),
                    label: 'Promesas de Dios',
                    keyName: 'promesas',
                  ),
                  _buildHighlightTile(
                    context,
                    color: const Color(0xFF10B981),
                    label: 'Mandamientos y Exhortaciones',
                    keyName: 'mandamientos',
                  ),
                  _buildHighlightTile(
                    context,
                    color: const Color(0xFF3B82F6),
                    label: 'Atributos de Dios',
                    keyName: 'atributos',
                  ),
                  _buildHighlightTile(
                    context,
                    color: const Color(0xFFEF4444),
                    label: 'Advertencias Soberanas',
                    keyName: 'advertencias',
                  ),
                  _buildHighlightTile(
                    context,
                    color: const Color(0xFF8B5CF6),
                    label: 'Profecía Bíblica',
                    keyName: 'profecia',
                  ),
                ],
              ),
            ),

            const Divider(indent: 16, endIndent: 16, height: 24),

            // SECCIÓN 4: Sistema y Ayuda
            _buildSectionHeader('SISTEMA Y AYUDA', sectionTitleColor),
            _buildDrawerTile(
              context,
              icon: Icons.settings_rounded,
              iconColor: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
              title: 'Ajustes del Sistema',
              subtitle: 'Modos de lectura, tipografías y respaldos',
              onTap: () {
                Navigator.of(context).pop();
                onOpenSettings();
              },
            ),
            _buildDrawerTile(
              context,
              icon: Icons.explore_rounded,
              iconColor: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
              title: 'Guía de Uso v1.4.0',
              subtitle: 'Recorrido interactivo guiado por la aplicación',
              onTap: () {
                Navigator.of(context).pop();
                onStartTour();
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14110E) : const Color(0xFFEDE4CE),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF33271E) : const Color(0xFFDCCDB3),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFBBF24), width: 1.2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    'assets/images/berea_interlineal_icon.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BEREA INTERLINEAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isDark
                            ? const Color(0xFFFDFBF7)
                            : const Color(0xFF261D17),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Versión 1.4.0 • Edición Estudio',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFB45309),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                ),
                tooltip: isDark
                    ? 'Cambiar a modo claro (☀️ Pergamino Diurno)'
                    : 'Cambiar a modo oscuro (🌙 Noche Alejandrina)',
                onPressed: () => StudyService.instance.toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '«...escudriñando cada día las Escrituras» (Hechos 17:11)',
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? const Color(0xFFE2C48E)
                  : const Color(0xFF6B5A4B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDark ? const Color(0xFFEDE4CE) : const Color(0xFF2B2118),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.5,
          color: isDark ? const Color(0xFFA89F91) : const Color(0xFF6B5A4B),
        ),
      ),
      dense: true,
      onTap: onTap,
    );
  }

  Widget _buildHighlightTile(
    BuildContext context, {
    required Color color,
    required String label,
    required String keyName,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      leading: Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFFEDE4CE) : const Color(0xFF2B2118),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: isDark ? const Color(0xFF706456) : const Color(0xFFB5A48F),
      ),
      onTap: () {
        Navigator.of(context).pop();
        onSelectTheologicalHighlight(keyName);
      },
    );
  }
}
