import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../utils/theme.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isLoading = false;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  // Características de la app
  final List<Map<String, dynamic>> _features = [
    {
      'icon': FontAwesomeIcons.bell,
      'title': 'Alarmas Inteligentes',
      'description': 'Notificaciones en pantalla completa que te despiertan',
      'color': AppTheme.primaryColor,
      'gradient': [AppTheme.primaryColor, AppTheme.accentColor],
    },
    {
      'icon': FontAwesomeIcons.calendarCheck,
      'title': 'Agenda Programada',
      'description': 'Control total de mantenimientos y recordatorios',
      'color': const Color(0xFF4CAF50),
      'gradient': [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
    },
    {
      'icon': FontAwesomeIcons.mapMarkerAlt,
      'title': 'Mapas Integrados',
      'description': 'Ubicaciones exactas con direcciones y coordenadas',
      'color': const Color(0xFF2196F3),
      'gradient': [const Color(0xFF2196F3), const Color(0xFF03A9F4)],
    },
    {
      'icon': FontAwesomeIcons.chartLine,
      'title': 'Estadísticas Avanzadas',
      'description': 'Seguimiento de mantenimientos y rendimiento',
      'color': const Color(0xFF9C27B0),
      'gradient': [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
    },
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Iniciar animaciones después de un breve delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _controller.forward();
    });

    // Verificar si es el primer inicio
    _checkFirstLaunch();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    Provider.of<StorageService>(context, listen: false);
    // Aquí podrías agregar lógica para verificar si es la primera vez
  }

  void _navigateToHome() async {
    setState(() {
      _isLoading = true;
    });

    // Animación de salida
    await _controller.reverse();

    // Navegar a home screen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Fondo con gradiente animado
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.grey[900]!, Colors.grey[800]!],
              ),
            ),
          ),

          // Partículas de fondo
          _buildBackgroundParticles(),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount:
                        _features.length + 1, // +1 para la página de bienvenida
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildWelcomePage();
                      } else {
                        return _buildFeaturePage(index - 1);
                      }
                    },
                  ),
                ),

                // Indicadores de página
                _buildPageIndicators(),

                // Botón de acción
                Padding(
                  padding: const EdgeInsets.all(AppTheme.defaultPadding),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                            strokeWidth: 2,
                          )
                        : ElevatedButton(
                            onPressed: _navigateToHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.secondaryColor,
                              elevation: 8,
                              shadowColor: AppTheme.primaryColor.withOpacity(
                                0.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 18,
                              ),
                              minimumSize: const Size(double.infinity, 56),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'INICIAR APLICACIÓN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  FontAwesomeIcons.arrowRight,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icono animado
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.8),
                      AppTheme.accentColor.withOpacity(0.4),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  FontAwesomeIcons.calendarCheck,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Título principal
            const Text(
              'BIENVENIDO',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3.0,
                height: 1.2,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // Nombre del usuario
            const Text(
              'CUTBERTO TERÁN MORALES',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor,
                letterSpacing: 1.5,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Subtítulo
            Text(
              'Sistema de Gestión de Mantenimientos Técnicos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Mensaje de bienvenida
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor, width: 1),
              ),
              child: Column(
                children: [
                  const Icon(
                    FontAwesomeIcons.handsHelping,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Optimiza tu trabajo y nunca olvides un mantenimiento',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[300],
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePage(int index) {
    final feature = _features[index];
    final icon = feature['icon'] as IconData;
    final title = feature['title'] as String;
    final description = feature['description'] as String;
    final color = feature['color'] as Color;
    final gradient = feature['gradient'] as List<Color>;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de característica
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(icon, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 40),

            // Título de característica
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.0,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Descripción
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
                height: 1.5,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Ejemplo o demostración visual
            _buildFeatureExample(index),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureExample(int index) {
    switch (index) {
      case 0: // Alarmas
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.bell, color: AppTheme.accentColor),
                  const SizedBox(width: 8),
                  Icon(FontAwesomeIcons.mobile, color: AppTheme.accentColor),
                  const SizedBox(width: 8),
                  Icon(
                    FontAwesomeIcons.mobileScreen,
                    color: AppTheme.accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Pantalla completa + Sonido + Vibración',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case 1: // Agenda
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniCard('📅', 'Programar'),
                  _buildMiniCard('🔔', 'Recordar'),
                  _buildMiniCard('✅', 'Completar'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Control completo de mantenimientos',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case 2: // Mapas
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.map, color: AppTheme.accentColor),
                  const SizedBox(width: 16),
                  Icon(
                    FontAwesomeIcons.locationArrow,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 16),
                  Icon(FontAwesomeIcons.route, color: AppTheme.accentColor),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Ubicaciones precisas + Navegación',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case 3: // Estadísticas
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.chartBar, color: AppTheme.accentColor),
                  const SizedBox(width: 16),
                  Icon(
                    FontAwesomeIcons.tachometerAlt,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 16),
                  Icon(FontAwesomeIcons.trophy, color: AppTheme.accentColor),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Métricas + Rendimiento + Reportes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      default:
        return Container();
    }
  }

  Widget _buildMiniCard(String emoji, String text) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_features.length + 1, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBackgroundParticles() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(_controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

// Pintor de partículas para fondo animado
class _ParticlePainter extends CustomPainter {
  final double animationValue;

  _ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Dibujar partículas en posiciones aleatorias pero consistentes
    for (int i = 0; i < 20; i++) {
      final x = (size.width * 0.2 + i * size.width * 0.04) % size.width;
      final y = (size.height * 0.3 + i * size.height * 0.05) % size.height;
      final radius = 2 + (i % 3).toDouble();

      // Animación de flotación
      final offsetY = math.sin(animationValue * 2 * math.pi + i * 0.5) * 10;

      canvas.drawCircle(Offset(x, y + offsetY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
