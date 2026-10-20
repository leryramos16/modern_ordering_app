import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.user});

  final User user;

  Future<void> _logout(BuildContext context) async {
    await authService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(child: Text('Welcome, ${user.name}')),
    );
  }
}
