import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';
import '../widgets/custom_app_bar.dart';
import 'food_recognition_results_screen.dart';
import 'settings_screen.dart'; // Import settings screen directly

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
  bool _isCapturing = false;
  bool _cameraError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        ResolutionPreset.medium, // Use medium for better quality
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

  // Save the original image to the device's photo gallery
  Future<void> _saveImageToGallery(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(imageBytes),
          quality: 100,
          name: "FoodCal_${DateTime.now().millisecondsSinceEpoch}");

      print('Image saved to gallery: $result');
    } catch (e) {
      print('Error saving image to gallery: $e');
      // Non-critical error, continue with the app flow
    }
  }

  // Create a minimal compressed version specifically for food recognition
  Future<File> _compressImageForRecognition(File imageFile) async {
    try {
      // Create a temporary file path to store the compressed image
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/recognition_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Compress and resize the image to a minimum viable size for recognition
      // Food recognition typically works well with 640x640 or even smaller
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 70, // Lower quality to minimize size
        minWidth: 640, // Smaller width, sufficient for recognition
        minHeight: 640, // Smaller height, sufficient for recognition
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        print('Image compression failed, using original image');
        return imageFile;
      }

      final originalSize = imageFile.lengthSync();
      final compressedSize = File(result.path).lengthSync();
      final compressionRatio = (1 - (compressedSize / originalSize)) * 100;

      print(
          'Image compressed: ${originalSize} bytes -> ${compressedSize} bytes (${compressionRatio.toStringAsFixed(2)}% reduction)');
      return File(result.path);
    } catch (e) {
      print('Error compressing image: $e');
      // If compression fails, return the original image
      return imageFile;
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
        // Save original image to gallery
        await _saveImageToGallery(File(photo.path));

        // Create a highly compressed version for food recognition
        final File compressedImage =
            await _compressImageForRecognition(File(photo.path));

        // Show meal type selection dialog
        final mealType = await _showMealTypeSelector();

        if (mealType != null && mounted) {
          // Navigate to food recognition results screen with the compressed image
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FoodRecognitionResultsScreen(
                imageFile: compressedImage,
                mealType: mealType,
              ),
            ),
          );

          // If food was added successfully, show a confirmation
          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Food added to your log'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
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

  Future<String?> _showMealTypeSelector() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Meal Type'),
          children: <Widget>[
            _buildMealTypeOption(context, 'Breakfast', Icons.breakfast_dining),
            _buildMealTypeOption(context, 'Lunch', Icons.lunch_dining),
            _buildMealTypeOption(context, 'Dinner', Icons.dinner_dining),
            _buildMealTypeOption(context, 'Snack', Icons.fastfood),
          ],
        );
      },
    );
  }

  Widget _buildMealTypeOption(
      BuildContext context, String title, IconData icon) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context, title.toLowerCase());
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to settings with back button
  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(
          showBackButton: true, // Show back button
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryBeige,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Camera',
        style: TextStyle(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Settings button
        IconButton(
          icon: const Icon(
            Icons.settings,
            color: AppTheme.primaryBlue,
          ),
          onPressed: _navigateToSettings, // Use our new navigation method
        ),
      ],
    );
  }

  Widget _buildBody() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate rectangle size
    final containerWidth = screenWidth * 0.9;
    final containerHeight = containerWidth * 0.75; // 4:3 aspect ratio

    return SafeArea(
      child: Center(
        // Center everything vertically
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            // Main camera preview area as a centered rectangle
            Center(
              child: Container(
                width: containerWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.hardEdge, // Important for clean edges
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera preview or error state
                    if (_isInitialized && _controller != null)
                      // Camera preview that fills the rectangle container
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.previewSize!.height,
                          height: _controller!.value.previewSize!.width,
                          child: Center(
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
                              Icons.photo_size_select_actual,
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
                          Icons.photo_size_select_actual,
                          color: Colors.white.withOpacity(0.5),
                          size: 80,
                        ),
                      ),

                    // Flash effect overlay when capturing
                    if (_isCapturing)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),

                    // Just keep the flash toggle in the top-right corner
                    if (_isInitialized)
                      Positioned(
                        right: 16,
                        top: 16,
                        child: _buildCameraButton(
                          icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          onPressed: _toggleFlash,
                          isCircular: true,
                          color: _isFlashOn
                              ? AppTheme.accentColor.withOpacity(0.8)
                              : Colors.white.withOpacity(0.3),
                          iconColor: Colors.white,
                          iconSize: 18,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Instructions text with more padding
            Padding(
              padding:
                  const EdgeInsets.only(top: 32.0, left: 16.0, right: 16.0),
              child: Text(
                'Take a photo of your meal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Add space at the bottom to avoid the capture button
            SizedBox(height: screenHeight * 0.1),
          ],
        ),
      ),
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(isCircular ? size / 2 : 12),
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
    );
  }
}
