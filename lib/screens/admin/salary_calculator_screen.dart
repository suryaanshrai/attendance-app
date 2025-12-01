import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../utils/notification_helper.dart';
import 'view_logs_screen.dart';

class SalaryCalculatorScreen extends StatefulWidget {
  const SalaryCalculatorScreen({super.key});

  @override
  State<SalaryCalculatorScreen> createState() => _SalaryCalculatorScreenState();
}

class _SalaryCalculatorScreenState extends State<SalaryCalculatorScreen> {
  User? _selectedUser;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  final _salaryController = TextEditingController();
  double? _calculatedSalary;
  int? _absentDays;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _calculateSalary() async {
    if (_selectedUser == null || _salaryController.text.isEmpty) {
      NotificationHelper.show(
        context,
        isSuccess: false,
        message: 'Please select user and enter monthly salary',
      );
      return;
    }

    final monthlySalary = double.tryParse(_salaryController.text);
    if (monthlySalary == null) {
      NotificationHelper.show(
        context,
        isSuccess: false,
        message: 'Invalid salary amount',
      );
      return;
    }

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

        // Calculate Absent Days
        // Logic: Total days in month - Days with logs
        // Note: This is a simplified logic as per requirement "Everyday is a working day"
        final daysInMonth = DateUtils.getDaysInMonth(_year, _month);

        // Count unique days with logs
        final uniqueDaysWithLogs = logs.logs.map((logStr) {
          final dt = DateTime.parse(logStr);
          return DateTime(dt.year, dt.month, dt.day);
        }).toSet();

        final presentDays = uniqueDaysWithLogs.length;
        final absent = daysInMonth - presentDays;

        final dailyPay = monthlySalary / daysInMonth;
        final deduction = absent * dailyPay;
        final finalSalary = monthlySalary - deduction;

        setState(() {
          _absentDays = absent;
          _calculatedSalary = finalSalary > 0 ? finalSalary : 0;
        });
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

  void _navigateToLogs() {
    if (_selectedUser == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewLogsScreen(
          initialUser: _selectedUser,
          initialYear: _year,
          initialMonth: _month,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Salary Calculator')),
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
            const SizedBox(height: 16),

            // Year and Month Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Year'),
                    value: _year,
                    items: List.generate(5, (index) {
                      final y = DateTime.now().year - index;
                      return DropdownMenuItem(value: y, child: Text('$y'));
                    }),
                    onChanged: (val) => setState(() => _year = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Month'),
                    value: _month,
                    items: List.generate(12, (index) {
                      final m = index + 1;
                      return DropdownMenuItem(value: m, child: Text('$m'));
                    }),
                    onChanged: (val) => setState(() => _month = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Salary Input
            TextField(
              controller: _salaryController,
              decoration: const InputDecoration(
                labelText: 'Monthly Salary',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Calculate Button
            ElevatedButton(
              onPressed: _isLoading ? null : _calculateSalary,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Calculate Salary',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(height: 32),

            // Results
            if (_calculatedSalary != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Absent Days: $_absentDays',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Calculated Salary: ₹${_calculatedSalary!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _navigateToLogs,
                icon: const Icon(Icons.list_alt),
                label: const Text('View Logs'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
