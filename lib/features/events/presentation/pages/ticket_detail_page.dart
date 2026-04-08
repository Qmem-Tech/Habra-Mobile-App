import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/events_repository.dart';

class TicketDetailPage extends StatefulWidget {
  final String ticketId;

  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  bool _policiesExpanded = true;
  late final EventsRepository _eventsRepository;
  late Future<Ticket?> _ticketFuture;

  @override
  void initState() {
    super.initState();
    _eventsRepository = di.sl<EventsRepository>();
    _ticketFuture = _loadTicket();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ticket Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Ticket?>(
        future: _ticketFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const HabraCircularLoader(fullScreen: true);
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.hasError
                          ? 'Could not load this ticket right now.'
                          : 'Ticket not found.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _ticketFuture = _loadTicket();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to My Tickets'),
                    ),
                  ],
                ),
              ),
            );
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
    );
  }

  Future<Ticket?> _loadTicket() async {
    final result = await _eventsRepository.getTicketDetail(widget.ticketId);
    return result.fold((_) => null, (ticket) => ticket);
  }

  Widget _buildEventSummary(Ticket ticket) {
    final event = ticket.event;
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
            child: event.imageUrl.startsWith('assets/')
                ? Image.asset(
                    event.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: AppColors.backgroundGrey,
                        child: const Icon(Icons.event, color: AppColors.textSecondary),
                      );
                    },
                  )
                : Image.network(
                    event.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: AppColors.backgroundGrey,
                        child: const Icon(Icons.event, color: AppColors.textSecondary),
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
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('EEE, MMM d • h:mm a').format(event.startDate),
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
                        '${event.venue}, ${event.address}',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          const Text(
            'Ticket 1 of 2',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode(Ticket ticket) {
    final qrData = ticket.qrCode?.isNotEmpty == true ? ticket.qrCode! : ticket.ticketId;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 280,
            backgroundColor: Colors.white,
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

  Widget _buildEventDetails(Ticket ticket) {
    final event = ticket.event;
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
                  DateFormat('MMM d, yyyy').format(event.startDate),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  'Time',
                  Icons.access_time,
                  DateFormat('h:mm a').format(event.startDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailItem(
            'Location',
            Icons.location_on,
            '${event.venue}, ${event.address}',
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
              Icon(icon, size: 16, color: AppColors.brandSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.brandSecondary,
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
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Add to Wallet',
              Icons.account_balance_wallet,
              AppColors.brandPrimary,
              Colors.white,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Directions',
              Icons.directions,
              AppColors.brandSecondary,
              AppColors.textPrimary,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Save PDF',
              Icons.download,
              AppColors.brandSecondary,
              AppColors.textPrimary,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Share',
              Icons.share,
              AppColors.brandSecondary,
              AppColors.textPrimary,
              isPrimary: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color bgColor,
    Color textColor, {
    bool isPrimary = false,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isPrimary ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventPolicies(Ticket ticket) {
    final policies = ticket.event.policies ?? [];
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
          InkWell(
            onTap: () {
              setState(() {
                _policiesExpanded = !_policiesExpanded;
              });
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Event Policies',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  _policiesExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          if (_policiesExpanded) ...[
            const SizedBox(height: 16),
            ...policies.map((policy) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
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
        ],
      ),
    );
  }
}
