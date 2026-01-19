import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/ticket.dart';
import '../bloc/tickets_cubit.dart';
import '../bloc/tickets_state.dart';
import 'ticket_detail_page.dart';
import 'package:intl/intl.dart';

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  bool _isUpcoming = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = di.sl<TicketsCubit>();
        // Load tickets after cubit is created
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cubit.loadUserTickets(upcomingOnly: _isUpcoming);
        });
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Tickets'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: BlocBuilder<TicketsCubit, TicketsState>(
                builder: (context, state) {
                  if (state is TicketsLoading) {
                    return const HabraCircularLoader(fullScreen: true);
                  }

                  if (state is TicketsError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }

                  if (state is TicketsEmpty) {
                    return _buildEmptyState();
                  }

                  if (state is TicketsLoaded) {
                    return _buildTicketsList(state.tickets);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab('Upcoming', true),
          ),
          Expanded(
            child: _buildTab('Past', false),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isUpcoming) {
    final isSelected = _isUpcoming == isUpcoming;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isUpcoming = isUpcoming;
        });
        context.read<TicketsCubit>().loadUserTickets(upcomingOnly: isUpcoming);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.brandPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsList(List<Ticket> tickets) {
    final groupedTickets = _groupTicketsByMonth(tickets);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTickets.length,
      itemBuilder: (context, index) {
        final entry = groupedTickets.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...entry.value.map((ticket) => _buildTicketCard(ticket)),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ticket.event.imageUrl.startsWith('assets/')
                  ? Image.asset(
                      ticket.event.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.event, size: 32);
                      },
                    )
                  : Image.network(
                      ticket.event.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.event, size: 32);
                      },
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.confirmation_number, size: 16, color: AppColors.brandPrimary),
                    const SizedBox(width: 4),
                    Text(
                      ticket.ticketTypeName,
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
                  ticket.event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d').format(ticket.event.startDate).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a').format(ticket.event.startDate),
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
                        '${ticket.event.venue}, ${ticket.event.city}...',
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketDetailPage(ticketId: ticket.ticketId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('View Ticket${ticket.id.contains('_2') ? ' (2)' : ''}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Directions'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No tickets yet.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Looks like you haven\'t booked anything. Discover upcoming events in your community.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate to events page
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Browse Events'),
          ),
        ],
      ),
    );
  }

  Map<String, List<Ticket>> _groupTicketsByMonth(List<Ticket> tickets) {
    final Map<String, List<Ticket>> grouped = {};
    for (final ticket in tickets) {
      final monthKey = DateFormat('MMMM yyyy').format(ticket.event.startDate);
      grouped.putIfAbsent(monthKey, () => []).add(ticket);
    }
    return grouped;
  }
}
