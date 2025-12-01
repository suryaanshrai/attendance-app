import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../utils/notification_helper.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  User? _selectedUser;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUserNames();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitPunch() async {
    if (_selectedUser == null) {
      NotificationHelper.show(
        context,
        isSuccess: false,
        message: 'Please select a user',
      );
      return;
    }

    setState(() => _isLoading = true);
    final token = Provider.of<AdminProvider>(context, listen: false).token;

    if (token != null) {
      try {
        final dateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final message = await ApiService().adminPunch(
          _selectedUser!.username,
          token,
          dateTime,
        );

        if (mounted) {
          NotificationHelper.show(context, isSuccess: true, message: message);
          // Optional: Reset form or navigate back?
          // Let's keep it on screen to allow multiple entries easily.
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
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manual Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Dropdown
            DropdownButtonFormField<User>(
              decoration: const InputDecoration(labelText: 'Select User'),
              value: _selectedUser,
              items: userProvider.users.map((user) {
                return DropdownMenuItem(
                  value: user,
                  child: Text(user.username),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedUser = val),
            ),
            const SizedBox(height: 24),

            // Date Picker
            ListTile(
              title: const Text('Date'),
              subtitle: Text(
                "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Time Picker
            ListTile(
              title: const Text('Time'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitPunch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add Log', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
