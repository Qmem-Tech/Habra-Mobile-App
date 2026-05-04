import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/events_repository.dart';
import '../utils/ticket_export_utils.dart';
import '../widgets/habra_ticket_card.dart';

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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        title: const Text('My ticket'),
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
                HabraTicketCard(ticket: ticket),
                _buildActionButtons(ticket),
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

  Widget _buildActionButtons(Ticket ticket) {
    final physical = !ticket.event.isOnline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.backgroundGrey.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            if (physical)
              ListTile(
                leading: const Icon(Icons.directions, color: AppColors.brandPrimary),
                title: const Text('Directions'),
                subtitle: const Text('Open in Google Maps'),
                onTap: () async {
                  final ok = await TicketExportUtils.openDirections(ticket);
                  if (!context.mounted) return;
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open maps. Check that a venue is set.'),
                      ),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: AppColors.brandPrimary),
              title: const Text('Share QR code'),
              subtitle: const Text('Send the check-in image'),
              onTap: () async {
                try {
                  await TicketExportUtils.shareQrImage(ticket);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not share: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.brandPrimary),
              title: const Text('Save or share PDF'),
              subtitle: const Text('Ticket summary with QR and policy'),
              onTap: () async {
                try {
                  await TicketExportUtils.saveAndSharePdf(ticket);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not create PDF: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventPolicies(Ticket ticket) {
    final policies = ticket.event.policies ?? [];
    if (policies.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.backgroundGrey.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
