import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart';

class CustomerHomePage extends StatelessWidget {
  final User user;

  const CustomerHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Home (${user.name})'),
      ),
      body: const Center(
        child: Text('Customer UI goes here'),
      ),
    );
  }
}
