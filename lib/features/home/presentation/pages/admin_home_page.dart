import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart';

class AdminHomePage extends StatelessWidget {
  final User user;

  const AdminHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard (${user.name})'),
      ),
      body: const Center(
        child: Text('Admin UI goes here'),
      ),
    );
  }
}
