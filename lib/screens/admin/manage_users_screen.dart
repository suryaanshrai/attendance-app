import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../utils/notification_helper.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  Future<void> _deleteUser(String username) async {
    final token = Provider.of<AdminProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      final message = await ApiService().deleteUser(username, token);
      if (mounted) {
        NotificationHelper.show(context, isSuccess: true, message: message);
        Provider.of<UserProvider>(context, listen: false).fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.show(
          context,
          isSuccess: false,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddUserScreen()),
          ).then((_) => userProvider.fetchUsers());
        },
        child: const Icon(Icons.add),
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: userProvider.users.length,
              itemBuilder: (context, index) {
                final user = userProvider.users[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user.username),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete User?'),
                        content: Text(
                          'Are you sure you want to delete ${user.username}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _deleteUser(user.username);
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _usernameController = TextEditingController();
  File? _imageFile;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.show(
          context,
          isSuccess: false,
          message: 'Error taking picture: $e',
        );
      }
    }
  }

  Future<void> _saveUser() async {
    if (_usernameController.text.isEmpty || _imageFile == null) {
      NotificationHelper.show(
        context,
        isSuccess: false,
        message: 'Please enter username and take a picture',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = Provider.of<AdminProvider>(context, listen: false).token;
      if (token != null) {
        final message = await ApiService().addUser(
          _usernameController.text,
          _imageFile!.path,
          token,
        );
        if (mounted) {
          NotificationHelper.show(context, isSuccess: true, message: message);
          Navigator.pop(context);
        }
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFile!,
                  height: 300,
                  width: 300,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('No Image Captured'),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.camera),
                  label: Text(_imageFile == null ? 'Take Picture' : 'Retake'),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveUser,
                  icon: const Icon(Icons.save),
                  label: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save User'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
