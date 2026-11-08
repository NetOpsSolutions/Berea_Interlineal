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
  String _statusText = '«Abriendo manuscritos hebreos y griegos...»';
  bool _navigated = false;
  bool _animDone = false;
  bool _dbReady = false;

  static const int _minDurationMs = 3000; // Mínimo 3 segundos garantizados

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _minDurationMs),
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
      if (p < 0.35) {
        status = '«Abriendo manuscritos hebreos y griegos...»';
      } else if (p < 0.70) {
        status = '«Sincronizando léxicos Strong y morfología...»';
      } else {
        status = _dbReady
            ? '«Listo para escudriñar la Palabra.»'
            : '«Preparando base de datos sagrada...»';
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
      _statusText = '«Listo para escudriñar la Palabra.»';
    });
    _tryNavigate();
  }

  void _tryNavigate() {
    if (_animDone && _dbReady) {
      _navigateToHome();
    }
  }

  void _onScreenTap() {
    // Solo permitir avanzar al tocar si ya transcurrieron los 3 segundos de animación
    if (_animDone && _dbReady) {
      _navigateToHome();
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B09),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Solo permitir avanzar al tocar si ya transcurrieron al menos 3 segundos
        onTap: _onScreenTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.25), // Centrado detrás del logotipo
              radius: 1.15,
              colors: [
                Color(0xFF241C16), // Núcleo cálido
                Color(0xFF14110E), // Cuero espresso profundo
                Color(0xFF0D0B09), // Penumbra exterior suave
              ],
              stops: [0.0, 0.65, 1.0],
            ),
          ),
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
                          // LOGO EMBLEMA CON RESPLANDOR CELESTIAL
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
                            child: _buildLogoWithCelestialGlow(),
                          ),
                          const SizedBox(height: 26),

                          // -------------------------------------------------
                          // TÍTULO, PASTILLA DORADA, LEMA Y FUENTES
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
                                // Título Principal
                                Text(
                                  'BEREA INTERLINEAL',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3.5,
                                    color: const Color(0xFFFDFBF7),
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFFD97706)
                                            .withValues(alpha: 0.6),
                                        blurRadius: 14,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Tagline en Pastilla Dorada
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFFBBF24)
                                          .withValues(alpha: 0.7),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Text(
                                    'BIBLIA INTERLINEAL DE ESTUDIO',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.6,
                                      color: Color(0xFFFCD34D),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Lema Bíblico Oficial
                                const Text(
                                  '«...escudriñando cada día las Escrituras» (Hechos 17:11)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.4,
                                    color: Color(0xFFE2C48E),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Fuentes Originales
                                const Text(
                                  'Hebreo BHS • Griego Tischendorf • Reina-Valera 1960\nDiccionarios Strong y Análisis Morfológico',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: Color(0xFFA89884),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),

                          // -------------------------------------------------
                          // BARRA DE CARGA ÁMBAR Y MENSAJE DIDÁCTICO
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
                                          ? null // indeterminado mientras termina BD
                                          : _loadingProgress,
                                      minHeight: 4.5,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.12),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFF59E0B), // Ámbar líquido
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _statusText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                    color: Color(0xFFE2C48E),
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

                // Aviso discreto inferior
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      _animDone && _dbReady
                          ? 'Toca para continuar'
                          : 'Abriendo manuscritos...',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.3,
                        color: const Color(0xFFE2C48E).withValues(alpha: 0.55),
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

  Widget _buildLogoWithCelestialGlow() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo Dorado Cenital (Celestial Glow)
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFBBF24).withValues(alpha: 0.22),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Logotipo Central Berea Interlineal en Contenedor Squircle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.55),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                blurRadius: 26,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(
              'assets/images/berea_interlineal_icon.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF14110E),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    size: 58,
                    color: Color(0xFFFCD34D),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
