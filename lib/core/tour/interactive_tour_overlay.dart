import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tipo de micro-animación demostrativa incluida dentro de la tarjeta guía
enum TourDemoKind {
  chapterUnfold,
  topBarControls,
  typewriterSearch,
  typewriterDictionary,
  studyCollections,
  readingPreferences,
  otaNotification,
  replayGuide,
}

/// Definición de cada paso del recorrido interactivo guiado
class TourStepConfig {
  final String badge;
  final bool isNewFeature;
  final IconData icon;
  final String title;
  final String description;
  final String pointerLabel;
  final TourDemoKind demoKind;
  final int tabIndex;
  final GlobalKey? Function() targetKeyResolver;
  final Future<void> Function()? onPrepareStep;

  const TourStepConfig({
    required this.badge,
    this.isNewFeature = false,
    required this.icon,
    required this.title,
    required this.description,
    required this.pointerLabel,
    required this.demoKind,
    required this.tabIndex,
    required this.targetKeyResolver,
    this.onPrepareStep,
  });
}

/// Superposición animada tipo Spotlight / Coach-Mark que guía al usuario
/// a través de las pantallas reales de Berea Interlineal.
class InteractiveTourOverlay extends StatefulWidget {
  final String versionLabel;
  final List<TourStepConfig> steps;
  final ValueChanged<int> onSwitchTab;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  const InteractiveTourOverlay({
    super.key,
    required this.versionLabel,
    required this.steps,
    required this.onSwitchTab,
    required this.onFinish,
    required this.onSkip,
  });

  @override
  State<InteractiveTourOverlay> createState() => _InteractiveTourOverlayState();
}

class _InteractiveTourOverlayState extends State<InteractiveTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Rect? _targetRect;
  bool _preparing = false;
  late final AnimationController _pulseController;

  TourStepConfig get _step => widget.steps[_currentIndex];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activateStep(0);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _activateStep(int index) async {
    if (!mounted || index < 0 || index >= widget.steps.length) return;
    setState(() {
      _currentIndex = index;
      _preparing = true;
    });

    final step = widget.steps[index];
    widget.onSwitchTab(step.tabIndex);

    // Esperar un frame para que IndexedStack muestre la pestaña destino
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    if (step.onPrepareStep != null) {
      try {
        await step.onPrepareStep!();
      } catch (_) {}
    }
    if (!mounted) return;

    // Dar margen a animaciones de expansión o scroll antes de medir el widget
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    _measureCurrentTarget();
    setState(() => _preparing = false);
  }

  void _measureCurrentTarget() {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final key = _step.targetKeyResolver();
    final ctx = key?.currentContext;

    Rect? measured;
    if (ctx != null) {
      final renderObj = ctx.findRenderObject();
      if (renderObj is RenderBox && renderObj.hasSize && renderObj.attached) {
        final topLeft = renderObj.localToGlobal(Offset.zero);
        final rawRect = topLeft & renderObj.size;

        // Añadir un margen respirable alrededor del control destacado
        final inflated = rawRect.inflate(6);
        final maxSpotlightHeight = screenSize.height * 0.37;

        final clampedLeft = inflated.left.clamp(8.0, screenSize.width - 40.0);
        final clampedRight = inflated.right.clamp(clampedLeft + 32.0, screenSize.width - 8.0);
        final clampedTop = inflated.top.clamp(topPad + 4.0, screenSize.height - 100.0);
        final clampedHeight = math.min(inflated.height, maxSpotlightHeight);

        measured = Rect.fromLTWH(
          clampedLeft,
          clampedTop,
          clampedRight - clampedLeft,
          math.max(40.0, clampedHeight),
        );
      }
    }

    setState(() {
      _targetRect = measured;
    });
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    if (_currentIndex < widget.steps.length - 1) {
      _activateStep(_currentIndex + 1);
    } else {
      widget.onFinish();
    }
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    if (_currentIndex > 0) {
      _activateStep(_currentIndex - 1);
    }
  }

  void _skipTour() {
    HapticFeedback.lightImpact();
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final safeTop = media.padding.top;
    final safeBottom = media.padding.bottom;

    final fallbackRect = Rect.fromCenter(
      center: Offset(size.width / 2, safeTop + 120),
      width: size.width - 32,
      height: 76,
    );
    final effectiveTarget = _targetRect ?? fallbackRect;
    final placeCardBelow = effectiveTarget.center.dy < size.height * 0.50;

    return Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<Rect?>(
        tween: RectTween(begin: effectiveTarget, end: effectiveTarget),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, animatedRect, _) {
          final rect = animatedRect ?? effectiveTarget;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Máscara oscura con ventana recortada (Spotlight) y halo pulsante
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Bloquea toques accidentales fuera de la guía
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _SpotlightScrimPainter(
                        spotlightRect: _targetRect != null ? rect : null,
                        pulseValue: _pulseController.value,
                        highlightGold: _step.isNewFeature,
                      ),
                    );
                  },
                ),
              ),

              // 2. Indicador flotante animado ("Pulsa aquí") apuntando al elemento real
              if (_targetRect != null && !_preparing)
                _buildAnimatedPointerPill(size, safeTop, safeBottom, rect, placeCardBelow),

              // 3. Tarjeta guía interactiva (posicionada automáticamente arriba o abajo sin solapar)
              _buildPositionedCoachCard(size, safeTop, safeBottom, rect, placeCardBelow),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedPointerPill(
    Size size,
    double safeTop,
    double safeBottom,
    Rect rect,
    bool placeCardBelow,
  ) {
    final clampedCenterX = rect.center.dx.clamp(95.0, size.width - 95.0);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final bounce = (_pulseController.value - 0.5) * 7.0;
        final topPos = placeCardBelow
            ? (rect.bottom + 8 + bounce).clamp(safeTop + 8.0, size.height - safeBottom - 260.0)
            : (rect.top - 42 + bounce).clamp(safeTop + 8.0, size.height - safeBottom - 60.0);

        final pillColor = _step.isNewFeature
            ? const Color(0xFFF59E0B)
            : const Color(0xFF0284C7);

        return Positioned(
          top: topPos,
          left: clampedCenterX - 95,
          width: 190,
          child: IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (placeCardBelow)
                  Icon(Icons.arrow_drop_up_rounded, color: pillColor, size: 22),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    _step.pointerLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (!placeCardBelow)
                  Icon(Icons.arrow_drop_down_rounded, color: pillColor, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPositionedCoachCard(
    Size size,
    double safeTop,
    double safeBottom,
    Rect rect,
    bool placeCardBelow,
  ) {
    final isLast = _currentIndex == widget.steps.length - 1;
    final availableBelow = size.height - (rect.bottom + 50) - safeBottom - 12;
    final availableAbove = (rect.top - 50) - safeTop - 12;

    double? top;
    double? bottom;
    double maxCardHeight;

    if (placeCardBelow) {
      bottom = safeBottom + 14;
      maxCardHeight = math.max(210.0, math.min(340.0, availableBelow));
    } else {
      top = safeTop + 14;
      maxCardHeight = math.max(210.0, math.min(340.0, availableAbove));
    }

    return Positioned(
      left: 14,
      right: 14,
      top: top,
      bottom: bottom,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxCardHeight),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _step.isNewFeature
                  ? const Color(0xFFF59E0B).withAlpha(190)
                  : const Color(0xFF38BDF8).withAlpha(170),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAA000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera: Paso + Etiqueta Novedad + Botón Omitir
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: _step.isNewFeature
                            ? const Color(0xFF78350F)
                            : const Color(0xFF0C4A6E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _step.isNewFeature
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF38BDF8),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _step.isNewFeature
                                ? Icons.auto_awesome_rounded
                                : _step.icon,
                            size: 13,
                            color: _step.isNewFeature
                                ? const Color(0xFFFDE047)
                                : const Color(0xFF7DD3FC),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _step.badge,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: _step.isNewFeature
                                  ? const Color(0xFFFEF08A)
                                  : const Color(0xFFE0F2FE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentIndex + 1} / ${widget.steps.length}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _skipTour,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFCBD5E1),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Omitir',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Contenido desplazable seguro ante pantallas pequeñas o letras grandes
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _step.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _step.description,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 13,
                            height: 1.38,
                          ),
                        ),
                        const SizedBox(height: 9),
                        _TourAnimatedMicroDemo(
                          key: ValueKey('tour_demo_$_currentIndex'),
                          kind: _step.demoKind,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Barra inferior: Puntos de progreso + Anterior / Siguiente
                Row(
                  children: [
                    // Indicadores de paso
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(widget.steps.length, (i) {
                        final active = i == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.only(right: 4),
                          width: active ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? (_step.isNewFeature
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFF38BDF8))
                                : const Color(0xFF475569),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    if (_currentIndex > 0) ...[
                      OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF475569)),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Atrás', style: TextStyle(fontSize: 12.5)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilledButton.icon(
                      onPressed: _nextStep,
                      style: FilledButton.styleFrom(
                        backgroundColor: isLast
                            ? const Color(0xFF10B981)
                            : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                        size: 16,
                      ),
                      iconAlignment: IconAlignment.end,
                      label: Text(
                        isLast ? '¡Empezar!' : 'Siguiente',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pintor del velo oscuro con recorte redondeado (Spotlight) y anillo luminoso animado
class _SpotlightScrimPainter extends CustomPainter {
  final Rect? spotlightRect;
  final double pulseValue;
  final bool highlightGold;

  _SpotlightScrimPainter({
    required this.spotlightRect,
    required this.pulseValue,
    required this.highlightGold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullPath = Path()..addRect(Offset.zero & size);
    final scrimPaint = Paint()..color = const Color(0xBF020617);

    if (spotlightRect == null) {
      canvas.drawPath(fullPath, scrimPaint);
      return;
    }

    final rrect = RRect.fromRectAndRadius(spotlightRect!, const Radius.circular(16));
    final holePath = Path()..addRRect(rrect);
    final maskPath = Path.combine(PathOperation.difference, fullPath, holePath);
    canvas.drawPath(maskPath, scrimPaint);

    final accent = highlightGold ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8);

    // Halo exterior pulsante
    final glowRect = spotlightRect!.inflate(3.0 + (pulseValue * 5.0));
    final glowPaint = Paint()
      ..color = accent.withAlpha((110 * (1.0 - pulseValue * 0.4)).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glowRect, const Radius.circular(18)),
      glowPaint,
    );

    // Borde nítido alrededor del control destacado
    final borderPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightScrimPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.highlightGold != highlightGold;
  }
}

/// Micro-demostración visual animada dentro de cada tarjeta de la guía
class _TourAnimatedMicroDemo extends StatefulWidget {
  final TourDemoKind kind;

  const _TourAnimatedMicroDemo({super.key, required this.kind});

  @override
  State<_TourAnimatedMicroDemo> createState() => _TourAnimatedMicroDemoState();
}

class _TourAnimatedMicroDemoState extends State<_TourAnimatedMicroDemo> {
  Timer? _timer;
  int _tick = 0;

  static const List<String> _searchSamples = [
    'En el principio',
    'G3056',
    'H430',
    'Jn 1:1',
  ];

  static const List<String> _dictSamples = [
    'λόγος • G3056 (Verbo / Palabra)',
    'אֱלֹהִים • H430 (Dios / Elohim)',
    'ἀγάπη • G26 (Amor divino)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.kind == TourDemoKind.typewriterSearch ||
        widget.kind == TourDemoKind.typewriterDictionary) {
      _timer = Timer.periodic(const Duration(milliseconds: 95), (_) {
        if (mounted) setState(() => _tick++);
      });
    } else {
      _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        if (mounted) setState(() => _tick++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _currentTypewriterText(List<String> samples) {
    final phraseIdx = (_tick ~/ 24) % samples.length;
    final phrase = samples[phraseIdx];
    final charPos = _tick % 24;
    final visibleLen = math.min(phrase.length, charPos + 1);
    final cursor = (_tick % 6 < 3) ? '▋' : ' ';
    return '${phrase.substring(0, visibleLen)}$cursor';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (widget.kind) {
      case TourDemoKind.chapterUnfold:
        final highlightIdx = _tick % 3;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _miniChip(Icons.touch_app_rounded, '1. Toca versículo', highlightIdx == 0),
            const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF94A3B8)),
            _miniChip(Icons.translate_rounded, 'Hebreo / Griego + Strong', highlightIdx == 1),
            _miniChip(Icons.swipe_rounded, 'Swipe = Sig. Capítulo', highlightIdx == 2),
          ],
        );

      case TourDemoKind.topBarControls:
        final active = _tick % 3;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _miniChip(Icons.menu_book_rounded, 'Cap. / Versículo', active == 0),
            _miniChip(Icons.auto_stories_rounded, 'Lectura Fluida', active == 1),
            _miniChip(Icons.text_fields_rounded, 'Fuentes Ezra / Cardo', active == 2),
          ],
        );

      case TourDemoKind.typewriterSearch:
        return Row(
          children: [
            const Icon(Icons.search_rounded, size: 16, color: Color(0xFF38BDF8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentTypewriterText(_searchSamples),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 12.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );

      case TourDemoKind.typewriterDictionary:
        return Row(
          children: [
            const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFFFBBF24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentTypewriterText(_dictSamples),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );

      case TourDemoKind.studyCollections:
        final step = _tick % 3;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _miniChip(Icons.bookmark_added_rounded, 'Marcadores', step == 0),
            _miniChip(Icons.palette_rounded, '5 Colores Teológicos', step == 1),
            _miniChip(Icons.edit_note_rounded, 'Notas en SQLite', step == 2),
          ],
        );

      case TourDemoKind.readingPreferences:
        final step = _tick % 3;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _miniChip(Icons.brightness_6_rounded, 'Claro / Oscuro', step == 0),
            _miniChip(Icons.chrome_reader_mode_rounded, 'Cap. Completo / Fluida', step == 1),
            _miniChip(Icons.format_size_rounded, 'Letra 85% – 145%', step == 2),
          ],
        );

      case TourDemoKind.otaNotification:
        return const Row(
          children: [
            Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Notificación Android → Notas de versión → Confirmar descarga',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );

      case TourDemoKind.replayGuide:
        return const Row(
          children: [
            Icon(Icons.explore_rounded, size: 16, color: Color(0xFF34D399)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ajustes → Ver guía de uso (disponible cuando quieras)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFD1FAE5),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _miniChip(IconData icon, String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? const Color(0xFF7DD3FC) : const Color(0xFF334155),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: active ? Colors.white : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFFCBD5E1),
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
