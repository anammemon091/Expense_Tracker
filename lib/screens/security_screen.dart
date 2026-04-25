import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // Required for WriteBuffer
import 'dashboard.dart';
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
  bool _isNavigating = false; // Prevents multiple navigation triggers
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
    _setupCamera();
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
        imageFormatGroup: ImageFormatGroup.nv21, // Better for Android ML Kit
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
      // If we already found a face and are moving to the next screen, stop everything
      if (_isNavigating) return; 

      try {
        final inputImage = _processCameraImage(image);
        if (inputImage == null) return;

        final List<Face> faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty && mounted && !_isNavigating) {
          _isNavigating = true; 
          
          // Stop the camera stream immediately to free hardware
          await _controller!.stopImageStream();

          setState(() {
            _faceDetected = true;
            _message = "Identity Verified!";
          });

          // Short delay so the user sees the "Success" state
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
      
      // Most Android front cameras need 270deg rotation for ML Kit to see upright
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
    // Ensure stream is stopped if user leaves screen early
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e3c72),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Face ID', 
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
          if (!_faceDetected)
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