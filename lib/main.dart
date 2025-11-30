import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'screens/punch_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/manage_users_screen.dart';
import 'screens/admin/view_logs_screen.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure cameras are available before app starts, though we init them in screens too.
  // We just need to ensure binding is initialized for path_provider etc.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(
          create: (_) => AdminProvider()..checkAutoLogin(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Horus',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/admin_login': (context) => const AdminLoginScreen(),
          '/admin_dashboard': (context) => const AdminDashboardScreen(),
          '/manage_users': (context) => const ManageUsersScreen(),
          '/view_logs': (context) => const ViewLogsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/punch') {
            final user = settings.arguments as User;
            return MaterialPageRoute(
              builder: (context) => PunchScreen(user: user),
            );
          }
          return null;
        },
      ),
    );
  }
}
