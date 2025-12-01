import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/notification_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    _urlController.text = configProvider.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _isConnecting = false;

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isConnecting = true);

      final success = await Provider.of<ConfigProvider>(
        context,
        listen: false,
      ).updateBaseUrl(_urlController.text);

      if (mounted) {
        setState(() => _isConnecting = false);
        if (success) {
          NotificationHelper.show(
            context,
            isSuccess: true,
            message: 'Connected and saved successfully',
          );
          Navigator.pop(context);
        } else {
          NotificationHelper.show(
            context,
            isSuccess: false,
            message: 'Server not reachable',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Backend Base URL',
                  hintText: 'http://192.168.1.5:8000',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a URL';
                  }
                  if (!value.startsWith('http')) {
                    return 'URL must start with http:// or https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isConnecting ? null : _saveSettings,
                child: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect and Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
