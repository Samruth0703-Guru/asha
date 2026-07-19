import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumCameraView extends StatefulWidget {
  final Function(XFile) onPictureTaken;
  final VoidCallback onCancel;

  const PremiumCameraView({
    super.key,
    required this.onPictureTaken,
    required this.onCancel,
  });

  @override
  State<PremiumCameraView> createState() => _PremiumCameraViewState();
}

class _PremiumCameraViewState extends State<PremiumCameraView> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _permissionDenied = false;
  int _selectedCameraIdx = 0;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _permissionDenied = true;
        });
        return;
      }
      _setCamera(_cameras[_selectedCameraIdx]);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _permissionDenied = true;
      });
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _setCamera(CameraDescription description) async {
    _controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _permissionDenied = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _permissionDenied = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _switchCamera() {
    if (_cameras.length > 1) {
      _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras.length;
      setState(() {
        _isInitializing = true;
      });
      _setCamera(_cameras[_selectedCameraIdx]);
    }
  }

  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (e) {
      debugPrint('Flash not supported: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final XFile picture = await _controller!.takePicture();
      // Turn off flash after picture if it was torch
      if (_isFlashOn) {
        _isFlashOn = false;
        await _controller!.setFlashMode(FlashMode.off);
      }
      widget.onPictureTaken(picture);
    } catch (e) {
      debugPrint('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text('Initializing Camera...', style: GoogleFonts.inter(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (_permissionDenied || _controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 64),
                const SizedBox(height: 24),
                Text(
                  'Camera permission is required for AI Health Scan.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please allow camera access in your browser or device settings to continue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Cancel & Return'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _initCamera,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Retry Camera'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(_controller!),
          ),

          // Top Controls
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                  onPressed: widget.onCancel,
                ),
                if (_cameras.length > 1)
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 32),
                    onPressed: _switchCamera,
                  ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 32),
                  onPressed: _toggleFlash,
                ),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 32),
                  onPressed: widget.onCancel, // Placeholder for gallery fallback logic if needed
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
