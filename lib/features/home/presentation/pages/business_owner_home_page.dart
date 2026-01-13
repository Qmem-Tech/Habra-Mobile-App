import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart';

class BusinessOwnerHomePage extends StatelessWidget {
  final User user;

  const BusinessOwnerHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Business Owner (${user.name})'),
      ),
      body: const Center(
        child: Text('Business owner UI goes here'),
      ),
    );
  }
}
