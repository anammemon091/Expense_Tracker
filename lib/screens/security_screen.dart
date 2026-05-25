import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; 
import 'dashboard.dart';
import '../services/app_state_manager.dart'; // Import your global state manager
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isVerifying = false;
  bool _faceDetected = false;
  bool _isNavigating = false; 
  String _message = "Align your face in the circle";

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  @override
  void initState() {
    super.initState();
    // Check global state first before spinning up intensive camera hardware
    _checkBiometricStatus();
  }

  void _checkBiometricStatus() {
    // If biometrics are explicitly toggled off in settings, skip directly to Dashboard
    if (!AppStateManager.biometricNotifier.value) {
      _isNavigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (c) => const Dashboard())
        );
      });
    } else {
      _setupCamera();
    }
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        front, 
        ResolutionPreset.medium, 
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, 
      );
      
      await _controller!.initialize();
      
      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("Camera Setup Error: $e");
    }
  }

  void _startLiveVerification() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isVerifying = true;
      _message = "Scanning... Hold still";
    });

    _controller!.startImageStream((CameraImage image) async {
      if (_isNavigating) return; 

      try {
        final inputImage = _processCameraImage(image);
        if (inputImage == null) return;

        final List<Face> faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty && mounted && !_isNavigating) {
          _isNavigating = true; 
          
          await _controller!.stopImageStream();

          setState(() {
            _faceDetected = true;
            _message = "Identity Verified!";
          });

          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (c) => const Dashboard())
              );
            }
          });
        }
      } catch (e) {
        debugPrint("Detection Error: $e");
      }
    });
  }

  InputImage? _processCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      const imageRotation = InputImageRotation.rotation270deg; 
      
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) 
          ?? InputImageFormat.nv21;

      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint("Image Processing Error: $e");
      return null;
    }
  }

  @override
  void dispose() {
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check theme settings to style canvas backgrounds dynamically
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Dynamic fallback color schema structures
      backgroundColor: isDark ? Colors.black : const Color(0xFF1e3c72),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Face ID Lock', 
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 10),
          Text(_message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: 280, 
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _faceDetected ? Colors.greenAccent : Colors.white, 
                  width: 4
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isInitialized 
                  ? CameraPreview(_controller!) 
                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 50),
          if (!_faceDetected && _isInitialized)
            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _startLiveVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, 
                  foregroundColor: const Color(0xFF1e3c72),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  _isVerifying ? "SCANNING..." : "START VERIFICATION",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}