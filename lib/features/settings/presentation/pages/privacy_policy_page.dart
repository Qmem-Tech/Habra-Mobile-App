import 'package:flutter/material.dart';

import 'legal_html_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalHtmlPage(
      slug: 'privacy_policy',
      fallbackTitle: 'Privacy Policy',
    );
  }
}
