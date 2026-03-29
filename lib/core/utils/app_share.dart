import 'package:share_plus/share_plus.dart';

/// Share plain text (e.g. job / event / business) using the platform sheet.
Future<void> shareText(String text, {String? subject}) async {
  await Share.share(text, subject: subject);
}
