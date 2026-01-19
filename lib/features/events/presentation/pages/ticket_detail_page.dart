import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/full_screen_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/tickets_cubit.dart';
import '../bloc/tickets_state.dart';
import 'package:intl/intl.dart';

class TicketDetailPage extends StatelessWidget {
  final String ticketId;

  const TicketDetailPage({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<TicketsCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Ticket's Detail"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder(
          future: _loadTicket(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const FullScreenLoader();
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text('Error loading ticket: ${snapshot.error}'));
            }

            final ticket = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildEventSummary(ticket),
                  _buildTicketNavigation(),
                  _buildQRCode(ticket),
                  _buildEventDetails(ticket),
                  _buildActionButtons(),
                  _buildEventPolicies(ticket),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<dynamic> _loadTicket(BuildContext context) async {
    // Mock ticket loading - in real app, use cubit
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'ticketId': ticketId,
      'event': {
        'title': 'Habesha Cultural Night 2024',
        'imageUrl': 'assets/images/events/cultural_night.png',
        'startDate': DateTime.now().add(const Duration(days: 30)),
        'venue': 'Addis Hall',
        'address': '123 Main St, Silver Spring, MD',
      },
      'policies': [
        '21+ Event. ID Required for entry.',
        'No Refunds or Exchanges.',
        'Doors close strictly at 10 PM.',
      ],
    };
  }

  Widget _buildEventSummary(dynamic ticket) {
    final event = ticket['event'];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (event['imageUrl'] as String).startsWith('assets/')
                ? Image.asset(
                    event['imageUrl'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: AppColors.backgroundGrey,
                        child: const Icon(Icons.event),
                      );
                    },
                  )
                : Image.network(
                    event['imageUrl'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: AppColors.backgroundGrey,
                        child: const Icon(Icons.event),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('EEE, MMM d • h:mm a').format(event['startDate']),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${event['venue']}, ${event['address']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {},
          ),
          const Text(
            'Ticket 1 of 2',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode(dynamic ticket) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Center(
              child: Text(
                'QR\nCODE\n${ticket['ticketId'] ?? 'HB-89204'}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan at entrance',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails(dynamic ticket) {
    final event = ticket['event'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Date',
                  Icons.calendar_today,
                  DateFormat('MMM d, yyyy').format(event['startDate']),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  'Time',
                  Icons.access_time,
                  DateFormat('h:mm a').format(event['startDate']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailItem(
            'Location',
            Icons.location_on,
            '${event['venue']}, ${event['address']}',
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, IconData icon, String value, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.brandPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Add to Wallet',
              Icons.account_balance_wallet,
              AppColors.brandPrimary,
              Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Directions',
              Icons.directions,
              AppColors.brandSecondary,
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color bgColor, Color textColor) {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.all(16),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }

  Widget _buildEventPolicies(dynamic ticket) {
    final policies = ticket['policies'] as List<dynamic>? ?? [];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandSecondary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info, color: AppColors.brandSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Event Policies',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.expand_more, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          ...policies.map((policy) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        policy.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
