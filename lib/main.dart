import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/exercise_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/custom_bottom_nav.dart';
import 'widgets/custom_app_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FOOD CAL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      // Define routes for navigation
      routes: {
        '/home': (context) => const MainApp(),
        '/settings': (context) => const SettingsScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/exercise': (context) => const ExerciseScreen(),
        '/camera': (context) => const CameraScreen(),
      },
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Camera controller reference to call camera capture
  final GlobalKey<CameraScreenState> _cameraScreenKey =
      GlobalKey<CameraScreenState>();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Initialize screens with the camera screen key
    _screens = [
      const HomeScreen(),
      const ProgressScreen(),
      CameraScreen(key: _cameraScreenKey),
      const ExerciseScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Reset animation when tab changes
    _animationController.reset();
    _animationController.forward();

    setState(() {
      _currentIndex = index;
    });
  }

  void _onCameraCapture() {
    // Call the capture method on the camera screen
    _cameraScreenKey.currentState?.capturePhoto();
  }

  void _navigateToSettings() {
    setState(() {
      _currentIndex = 4; // Index for settings screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _currentIndex == 2
          ? null // No app bar for camera screen
          : CustomAppBar(
              onSettingsTap: _navigateToSettings,
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _screens[_currentIndex],
      ),
      extendBody: true, // Important for curved navigation bar
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        onCameraCapture: _onCameraCapture,
      ),
    );
  }
}
