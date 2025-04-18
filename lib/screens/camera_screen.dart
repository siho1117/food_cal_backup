import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../config/theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _isInitialized = false;
  bool _isFlashOn = false;
  bool _isGridOn = false;
  bool _isCapturing = false;
  bool _cameraError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;
    // Check if controller is initialized before handling lifecycle state
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (mounted) {
      setState(() {
        _isInitializing = true;
        _cameraError = false;
        _errorMessage = "";
      });
    }

    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _cameraError = true;
            _errorMessage = "No cameras found on this device";
          });
        }
        return;
      }

      // Dispose any existing controller
      await _controller?.dispose();

      // Create a new camera controller
      final cameraController = CameraController(
        _cameras[0],
        ResolutionPreset.low, // Use low resolution to avoid memory issues
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Store the controller
      _controller = cameraController;

      // Initialize the controller
      try {
        await cameraController.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isInitializing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _cameraError = true;
            _errorMessage = "Could not initialize camera: $e";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _cameraError = true;
          _errorMessage = "Camera access error: $e";
        });
      }
    }
  }

  void _toggleFlash() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _isFlashOn = !_isFlashOn;
    });

    try {
      controller.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Flash not available: $e";
      });
    }
  }

  void _toggleGrid() {
    setState(() {
      _isGridOn = !_isGridOn;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      setState(() {
        _errorMessage = "Only one camera available";
      });
      return;
    }

    try {
      final controller = _controller;
      if (controller == null) return;

      final int currentIndex = _cameras.indexOf(controller.description);
      final int newIndex = (currentIndex + 1) % _cameras.length;

      setState(() {
        _isInitializing = true;
        _isInitialized = false;
      });

      // Dispose the old controller
      await controller.dispose();

      // Create and initialize the new controller
      final newController = CameraController(
        _cameras[newIndex],
        ResolutionPreset.low,
        enableAudio: false,
      );

      _controller = newController;

      try {
        await newController.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isInitializing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _cameraError = true;
            _errorMessage = "Failed to initialize camera: $e";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _cameraError = true;
          _errorMessage = "Error switching camera: $e";
        });
      }
    }
  }

  Future<void> capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      // Simulate flash effect
      await Future.delayed(const Duration(milliseconds: 100));

      // Take the picture
      final XFile? photo = await controller.takePicture();

      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }

      if (photo != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo captured!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _errorMessage = "Error capturing photo: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryBeige,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Text(
                    'FOOD CAL',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            // Error message display if needed
            if (_errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.red),
                      onPressed: _initCamera,
                    ),
                  ],
                ),
              ),

            // Main camera preview area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      // Camera preview or error state
                      if (_isInitialized && _controller != null)
                        // Check controller exists and is initialized
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width:
                                  _controller!.value.previewSize?.width ?? 640,
                              height:
                                  _controller!.value.previewSize?.height ?? 480,
                              child: CameraPreview(_controller!),
                            ),
                          ),
                        )
                      else if (_isInitializing)
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Initializing camera...",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                      else if (_cameraError)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: Colors.white.withOpacity(0.5),
                                size: 80,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Camera error",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ElevatedButton(
                                  onPressed: _initCamera,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                  ),
                                  child: const Text("Try Again"),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white.withOpacity(0.5),
                            size: 80,
                          ),
                        ),

                      // Grid overlay (conditionally shown)
                      if (_isGridOn && _isInitialized) _buildCameraGrid(),

                      // Flash effect overlay when capturing
                      if (_isCapturing)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),

                      // Camera controls on the right side
                      if (_isInitialized)
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCameraButton(
                                icon: Icons.grid_on,
                                onPressed: _toggleGrid,
                                isCircular: true,
                                color: _isGridOn
                                    ? AppTheme.accentColor.withOpacity(0.8)
                                    : Colors.white.withOpacity(0.3),
                                iconSize: 18,
                                size: 40,
                              ),
                              const SizedBox(height: 16),
                              _buildCameraButton(
                                icon: Icons.flip_camera_ios,
                                onPressed: _switchCamera,
                                isCircular: true,
                                color: Colors.white.withOpacity(0.3),
                                iconSize: 18,
                                size: 40,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom controls
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              color: Colors.white,
              child: Column(
                children: [
                  const Text(
                    'Take a photo of your meal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Camera buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      _buildCameraButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onPressed: () {},
                        isCircular: true,
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        iconColor: AppTheme.primaryBlue,
                        iconSize: 24,
                      ),

                      // Capture button
                      _buildCameraButton(
                        icon: Icons.camera,
                        label: 'Capture',
                        onPressed: capturePhoto,
                        isCircular: true,
                        color: AppTheme.accentColor,
                        iconSize: 30,
                        size: 60,
                        border: true,
                      ),

                      // Flash button
                      _buildCameraButton(
                        icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        label: 'Flash',
                        onPressed: _toggleFlash,
                        isCircular: true,
                        color: _isFlashOn
                            ? AppTheme.accentColor.withOpacity(0.8)
                            : AppTheme.primaryBlue.withOpacity(0.1),
                        iconColor:
                            _isFlashOn ? Colors.white : AppTheme.primaryBlue,
                        iconSize: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraGrid() {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(),
    );
  }

  Widget _buildCameraButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isCircular,
    required Color color,
    Color? iconColor,
    double iconSize = 24,
    double size = 50,
    bool border = false,
    String label = '',
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(isCircular ? size : 12),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: !isCircular ? BorderRadius.circular(12) : null,
                border: border
                    ? Border.all(
                        color: Colors.white,
                        width: 3,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),

        // Label (if provided)
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

// Custom Painter for the camera grid
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Vertical lines
    for (int i = 1; i < 3; i++) {
      final x = size.width * (i / 3);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (int i = 1; i < 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
