import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../feedback/presentation/pages/admin_feedback_page.dart';

class AdminHomePage extends StatelessWidget {
  final User user;

  const AdminHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin (${user.name})'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('User feedback'),
            subtitle: const Text('Review and update submissions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminFeedbackPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
