import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/user_grid_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch users when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => userProvider.fetchUsers(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProvider.users.isEmpty
          ? const Center(
              child: Text('No users found. Add users via Admin Panel.'),
            )
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: userProvider.users.length,
                itemBuilder: (context, index) {
                  final user = userProvider.users[index];
                  return UserGridItem(
                    user: user,
                    onTap: () {
                      Navigator.pushNamed(context, '/punch', arguments: user);
                    },
                  );
                },
              ),
            ),
    );
  }
}
