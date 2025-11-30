import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';

class ViewLogsScreen extends StatefulWidget {
  const ViewLogsScreen({super.key});

  @override
  State<ViewLogsScreen> createState() => _ViewLogsScreenState();
}

class _ViewLogsScreenState extends State<ViewLogsScreen> {
  User? _selectedUser;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  Log? _logs;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  Future<void> _fetchLogs() async {
    if (_selectedUser == null) return;

    setState(() => _isLoading = true);
    final token = Provider.of<AdminProvider>(context, listen: false).token;

    if (token != null) {
      try {
        final logs = await ApiService().getLogs(
          _selectedUser!.username,
          _year,
          _month,
          token,
        );
        setState(() => _logs = logs);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = Provider.of<UserProvider>(context).users;

    return Scaffold(
      appBar: AppBar(title: const Text('View Logs')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<User>(
              value: _selectedUser,
              hint: const Text('Select User'),
              items: users.map((user) {
                return DropdownMenuItem(
                  value: user,
                  child: Text(user.username),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedUser = val),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _year,
                    items: List.generate(5, (i) => DateTime.now().year - i)
                        .map(
                          (y) => DropdownMenuItem(value: y, child: Text('$y')),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _year = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _month,
                    items: List.generate(12, (i) => i + 1)
                        .map(
                          (m) => DropdownMenuItem(value: m, child: Text('$m')),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _month = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedUser == null ? null : _fetchLogs,
              child: const Text('Fetch Logs'),
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _logs == null
                  ? const Center(child: Text('No logs fetched'))
                  : ListView.builder(
                      itemCount: _logs!.logs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_logs!.logs[index]),
                          leading: const Icon(Icons.access_time),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
