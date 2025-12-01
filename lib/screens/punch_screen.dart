import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/notification_helper.dart';

class PunchScreen extends StatefulWidget {
  final User user;

  const PunchScreen({super.key, required this.user});

  @override
  State<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends State<PunchScreen> {
  bool _isPunching = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePictureAndPunch() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50, // Optimize image size
      );

      if (photo == null) return; // User canceled

      setState(() {
        _isPunching = true;
      });

      final apiService = ApiService();
      final result = await apiService.punch(widget.user.username, photo.path);

      if (mounted) {
        NotificationHelper.show(
          context,
          isSuccess: true,
          message: result['message'] ?? 'Punch successful',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.show(
          context,
          isSuccess: false,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isPunching) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text('Processing punch...'),
              ] else ...[
                const Icon(Icons.camera_alt, size: 100, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'Tap the button below to take a selfie and punch in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _takePictureAndPunch,
                    icon: const Icon(Icons.camera),
                    label: const Text('TAKE PICTURE & PUNCH'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
