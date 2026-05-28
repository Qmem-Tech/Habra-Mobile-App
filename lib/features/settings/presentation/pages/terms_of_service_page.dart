import 'package:flutter/material.dart';

import 'legal_html_page.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalHtmlPage(
      slug: 'terms_of_service',
      fallbackTitle: 'Terms of Service',
    );
  }
}
