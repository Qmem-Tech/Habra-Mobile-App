import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart';

class GuestHomePage extends StatelessWidget {
  final User user;

  const GuestHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar:  AppBar(
        title: Text('Guest'),
      ),
      body: Center(
        child: Text('Guest experience UI goes here'),
      ),
    );
  }
}
