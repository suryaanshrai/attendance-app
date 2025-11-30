import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PunchScreen extends StatefulWidget {
  final User user;

  const PunchScreen({super.key, required this.user});

  @override
  State<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends State<PunchScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isPunching = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(firstCamera, ResolutionPreset.medium);

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndPunch() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isPunching = true;
      _message = null;
    });

    try {
      await _initializeControllerFuture;

      final path = join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );

      final image = await _controller!.takePicture();
      await image.saveTo(path);

      final apiService = ApiService();
      final result = await apiService.punch(widget.user.username, image.path);

      setState(() {
        _message = result['message'];
        _isSuccess = true;
      });

      // Auto-close after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
        _isSuccess = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPunching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Punch In: ${widget.user.username}')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller!);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          if (_message != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: _isSuccess ? Colors.green.shade100 : Colors.red.shade100,
              width: double.infinity,
              child: Text(
                _message!,
                style: TextStyle(
                  color: _isSuccess
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isPunching ? null : _takePictureAndPunch,
                icon: const Icon(Icons.camera_alt),
                label: _isPunching
                    ? const CircularProgressIndicator()
                    : const Text('PUNCH ATTENDANCE'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
