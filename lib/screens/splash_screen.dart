import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../widgets/buz_logo.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Orientation will be set in didChangeDependencies when context is available

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestTrackingPermission().then((_) {
        _startLoading();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ResponsiveHelper.setPortraitOrAllOrientations(context);
  }

  Future<void> _requestTrackingPermission() async {
    try {
      final TrackingStatus status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      
      if (status == TrackingStatus.notDetermined) {
        // Wait a brief moment before showing the dialog for better UX
        await Future.delayed(const Duration(milliseconds: 200));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('Error requesting ATT permission: $e');
    }
  }

  void _startLoading() {
    const totalDuration = Duration(seconds: 5);
    const interval = Duration(milliseconds: 50);
    final totalSteps = totalDuration.inMilliseconds / interval.inMilliseconds;
    int currentStep = 0;

    _timer = Timer.periodic(interval, (timer) {
      currentStep++;
      setState(() {
        _progress = currentStep / totalSteps;
      });

      if (currentStep >= totalSteps) {
        _timer?.cancel();
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTab = ResponsiveHelper.isTablet(context);
    final logoSize = isTab ? 200.0 : 150.0;
    final titleSize = isTab ? 48.0 : 36.0;
    final subtitleSize = isTab ? 16.0 : 12.0;
    final progressPadding = isTab ? 120.0 : 64.0;

    // Using current AppTheme.bgDark as the base background color
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return BuzLogo(
                        size: logoSize,
                        borderRadius: 32,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // App Name
              Text(
                'Buzar\nSmart IPTV Player',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PREMIUM VIDEO PLAYER',
                style: GoogleFonts.inter(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 64),
              // Progress Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: progressPadding),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: isTab ? 8 : 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: subtitleSize,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
