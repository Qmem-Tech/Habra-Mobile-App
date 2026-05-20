import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

/// Super-admin composer that inserts a row into `public.platform_notifications`.
/// A Postgres trigger / Edge Function fans the row out as FCM pushes to every
/// user matching the audience (all / customers / business_owners).
class AdminNotificationComposerPage extends StatefulWidget {
  const AdminNotificationComposerPage({super.key});

  @override
  State<AdminNotificationComposerPage> createState() =>
      _AdminNotificationComposerPageState();
}

class _AdminNotificationComposerPageState
    extends State<AdminNotificationComposerPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _audience = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final row = await Supabase.instance.client
          .from('platform_notifications')
          .insert({
            'title': _titleController.text.trim(),
            'body': _bodyController.text.trim(),
            'audience': _audience,
          })
          .select('id')
          .single();

      final pushRes = await Supabase.instance.client.functions.invoke(
        'send-push-notification',
        body: {
          'source': 'platform',
          'notification_id': row['id'],
        },
      );

      if (pushRes.status != 200) {
        final err = pushRes.data is Map
            ? (pushRes.data as Map)['error']?.toString()
            : null;
        throw Exception(
          err ??
              'Push delivery failed (HTTP ${pushRes.status}). '
                  'Check Edge Function logs and FCM secrets.',
        );
      }

      final pushData = pushRes.data;
      if (pushData is Map &&
          pushData['reason'] == 'no_tokens' &&
          (pushData['delivered'] as num? ?? 0) == 0) {
        throw Exception(
          'Saved, but no devices have push tokens for this audience. '
          'Open the app while signed in and allow notifications.',
        );
      }

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification sent.')),
      );
      _titleController.clear();
      _bodyController.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      final msg = raw.toLowerCase();
      final friendly = (msg.contains('does not exist') || msg.contains('not found'))
          ? 'platform_notifications table is missing. Run the SQL migration first.'
          : (msg.contains('policy') || msg.contains('permission'))
              ? 'You do not have permission to send platform notifications. '
                  'Confirm your profile role is admin and the RLS policy is in place.'
              : raw;
      messenger.showSnackBar(SnackBar(content: Text(friendly)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Send platform notification'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              const _AudienceLabel(),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All')),
                  ButtonSegment(value: 'customers', label: Text('Customers')),
                  ButtonSegment(
                    value: 'business_owners',
                    label: Text('Business owners'),
                  ),
                ],
                selected: {_audience},
                onSelectionChanged: (s) =>
                    setState(() => _audience = s.first),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                maxLength: 80,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Title is required';
                  if (t.length < 3) return 'Title is too short';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLength: 240,
                maxLines: 4,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Message is required';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Send to ${_audienceLabel(_audience)}',
                icon: Icons.send_rounded,
                isLoading: _sending,
                onPressed: _sending ? null : _send,
              ),
              const SizedBox(height: 12),
              Text(
                'Notifications appear in users\' notification feed immediately. '
                'A push is delivered when the send-push-notification Edge '
                'Function is deployed and your Supabase service account is '
                'configured for FCM.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _audienceLabel(String key) {
    switch (key) {
      case 'customers':
        return 'customers';
      case 'business_owners':
        return 'business owners';
      default:
        return 'everyone';
    }
  }
}

class _AudienceLabel extends StatelessWidget {
  const _AudienceLabel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Audience',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    );
  }
}
