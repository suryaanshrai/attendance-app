import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text(
              'Attendance System',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Divider(),
          if (adminProvider.isAdminLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin_dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Admin Logout'),
              onTap: () {
                adminProvider.logout();
                Navigator.pop(context);
              },
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Login'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin_login');
              },
            ),
        ],
      ),
    );
  }
}
