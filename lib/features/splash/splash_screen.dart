import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/database_service.dart';
import '../../shell/home_shell.dart';

class SplashScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const SplashScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _progressFade;

  double _loadingProgress = 0.0;
  String _statusText = 'Iniciando textos sagrados...';
  bool _navigated = false;
  bool _animDone = false;
  bool _dbReady = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Animación del logo: escala suave + fade
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // Animación del texto: leve deslizamiento hacia arriba + fade
    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.65, curve: Curves.easeIn),
      ),
    );

    // Animación de la barra de progreso
    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _controller.addListener(() {
      final p = _controller.value;
      String status;
      if (p < 0.3) {
        status = 'Cargando manuscritos interlineales...';
      } else if (p < 0.65) {
        status = 'Inicializando Strong griego y hebreo...';
      } else if (p < 0.95) {
        status = 'Preparando concordancia y notas...';
      } else {
        status = _dbReady ? '¡Todo listo!' : 'Preparando base de datos...';
      }
      if (status != _statusText || (p - _loadingProgress).abs() > 0.02) {
        setState(() {
          _loadingProgress = p;
          _statusText = status;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animDone = true;
        _tryNavigate();
      }
    });

    _controller.forward();

    // Esperar la base de datos en paralelo
    _waitForDatabase();
  }

  Future<void> _waitForDatabase() async {
    await DatabaseService.instance.initialize();
    if (!mounted) return;
    setState(() {
      _dbReady = true;
      _statusText = '¡Todo listo!';
    });
    _tryNavigate();
  }

  void _tryNavigate() {
    if (_animDone && _dbReady) {
      Future.delayed(const Duration(milliseconds: 300), _navigateToHome);
    }
  }

  void _navigateToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _controller.stop();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => HomeShell(
          themeMode: widget.themeMode,
          onToggleTheme: widget.onToggleTheme,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Fondo degradado elegante: tonos azul profundo / medianoche
    final bgGradient = isDark
        ? const RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              Color(0xFF1A2639),
              Color(0xFF0F172A),
              Color(0xFF090D16),
            ],
          )
        : const RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFEEF2F6),
              Color(0xFFE2E8F0),
            ],
          );

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Permitir omitir tocando la pantalla para máxima rapidez
        onTap: _dbReady ? _navigateToHome : null,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: bgGradient),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // -------------------------------------------------
                          // LOGO EMBLEMA CON ANIMACIÓN DE ESCALA Y BRILLO
                          // -------------------------------------------------
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _logoFade,
                                child: ScaleTransition(
                                  scale: _logoScale,
                                  child: child,
                                ),
                              );
                            },
                            child: _buildLogoEmblem(isDark),
                          ),
                          const SizedBox(height: 28),

                          // -------------------------------------------------
                          // TÍTULO Y SUBTÍTULOS ANIMADOS
                          // -------------------------------------------------
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _textFade,
                                child: SlideTransition(
                                  position: _textSlide,
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Text(
                                  'LOGOS K LOGOS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3.5,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    shadows: isDark
                                        ? [
                                            Shadow(
                                              color: const Color(0xFF60A5FA)
                                                  .withAlpha(100),
                                              blurRadius: 18,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Tagline: Biblia Interlineal de Estudio
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFFF59E0B).withAlpha(35)
                                        : const Color(0xFFD97706).withAlpha(25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                        ? const Color(0xFFFBBF24).withAlpha(130)
                                        : const Color(0xFFD97706).withAlpha(90),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    'BIBLIA INTERLINEAL DE ESTUDIO',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: isDark
                                          ? const Color(0xFFFCD34D)
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Fuentes e idiomas
                                Text(
                                  'Griego • Hebreo • Reina-Valera 1960',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Diccionarios Strong y Análisis Morfológico',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 38),

                          // -------------------------------------------------
                          // BARRA DE CARGA Y ESTADO
                          // -------------------------------------------------
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _progressFade,
                                child: child,
                              );
                            },
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 230,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: _animDone && !_dbReady
                                          ? null // indeterminado mientras carga BD
                                          : _loadingProgress,
                                      minHeight: 5,
                                      backgroundColor: isDark
                                          ? Colors.white.withAlpha(25)
                                          : Colors.black.withAlpha(20),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        isDark
                                            ? const Color(0xFF60A5FA)
                                            : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Botón discreto inferior para saltar si lo desea
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      _dbReady ? 'Toca para continuar' : 'Preparando base de datos...',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white.withAlpha(80)
                            : Colors.black.withAlpha(80),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoEmblem(bool isDark) {
    return Container(
      width: 124,
      height: 124,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E3A8A),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFF3B82F6),
                  const Color(0xFF1D4ED8),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF3B82F6).withAlpha(100)
                : const Color(0xFF2563EB).withAlpha(80),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFFF59E0B).withAlpha(60),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 0),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF59E0B).withAlpha(160),
          width: 2.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Letras griegas y hebreas decorativas sutiles
          Positioned(
            left: 18,
            top: 24,
            child: Text(
              'ב',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFCD34D).withAlpha(160),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 24,
            child: Text(
              'Ω',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFCD34D).withAlpha(160),
              ),
            ),
          ),

          // Ícono central del libro sagrado abierto
          const Icon(
            Icons.auto_stories_rounded,
            size: 58,
            color: Colors.white,
          ),

          // Cinta de marcador dorada
          Positioned(
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Α • Ω',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
