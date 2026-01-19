import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/full_screen_loader.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/event_detail.dart';
import '../../domain/entities/ticket_type.dart';
import '../../domain/entities/selected_ticket.dart';
import '../bloc/events_cubit.dart';
import '../bloc/events_state.dart';
import '../bloc/tickets_cubit.dart';
import '../bloc/tickets_state.dart';
import 'checkout_page.dart';
import 'package:intl/intl.dart';

class SelectTicketsPage extends StatefulWidget {
  final String eventId;

  const SelectTicketsPage({super.key, required this.eventId});

  @override
  State<SelectTicketsPage> createState() => _SelectTicketsPageState();
}

class _SelectTicketsPageState extends State<SelectTicketsPage> {
  final Map<String, int> _selectedTickets = {};
  double _subtotal = 0.0;
  double _serviceFee = 0.0;
  double _total = 0.0;
  EventDetail? _currentEvent;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<EventsCubit>()..loadEventDetail(widget.eventId)),
        BlocProvider(create: (_) => di.sl<TicketsCubit>()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Tickets'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<EventsCubit, EventsState>(
          builder: (context, state) {
            if (state is EventDetailLoading) {
              return const FullScreenLoader();
            }

            if (state is EventDetailError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            if (state is EventDetailLoaded) {
              _currentEvent = state.event;
              return _buildContent(context, state.event);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EventDetail event) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildEventInfoCard(event),
          _buildTicketsSection(event),
          _buildOrderSummary(),
          _buildContinueButton(context, event),
        ],
      ),
    );
  }

  Widget _buildEventInfoCard(EventDetail event) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
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
                        child: const Icon(Icons.event),
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
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(event.startDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.venue}, ${event.city}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsSection(EventDetail event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tickets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Step 2 of 3',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...event.ticketTypes.map((ticketType) => _buildTicketCard(ticketType, event)),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TicketType ticketType, EventDetail event) {
    final quantity = _selectedTickets[ticketType.id] ?? 0;
    final isAvailable = ticketType.status == TicketStatus.available;
    final isLowStock = ticketType.status == TicketStatus.lowStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Icon(
                _getTicketIcon(ticketType.icon),
                color: _getTicketIconColor(ticketType.status),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticketType.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticketType.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${ticketType.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticketType.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(ticketType.status, ticketType.availableQuantity),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getStatusColor(ticketType.status),
                    ),
                  ),
                ],
              ),
              if (isAvailable || isLowStock)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: quantity > 0
                          ? () {
                              setState(() {
                                if (quantity > 1) {
                                  _selectedTickets[ticketType.id] = quantity - 1;
                                } else {
                                  _selectedTickets.remove(ticketType.id);
                                }
                                if (_currentEvent != null) {
                                  _calculateTotal(_currentEvent!.ticketTypes);
                                }
                              });
                            }
                          : null,
                    ),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.brandPrimary),
                      onPressed: () {
                        setState(() {
                          _selectedTickets[ticketType.id] = (quantity + 1);
                          if (_currentEvent != null) {
                            _calculateTotal(_currentEvent!.ticketTypes);
                          }
                        });
                      },
                    ),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined),
                  label: const Text('Notify Me'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final totalItems = _selectedTickets.values.fold(0, (sum, qty) => sum + qty);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal ($totalItems items)'),
              Text('\$${_subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Service Fee'),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                ],
              ),
              Text('\$${_serviceFee.toStringAsFixed(2)}'),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, EventDetail event) {
    final hasTickets = _selectedTickets.values.any((qty) => qty > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppButton(
                text: 'Continue',
                width: 150,
                onPressed: hasTickets
                    ? () {
                        final tickets = _selectedTickets.entries
                            .map((e) => {
                                  'ticketTypeId': e.key,
                                  'quantity': e.value,
                                })
                            .toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutPage(
                              eventId: event.id,
                              tickets: tickets,
                            ),
                          ),
                        );
                      }
                    : null,
                icon: Icons.arrow_forward,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'By continuing, you agree to the terms and conditions of Habesha Community App.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _calculateTotal(List<TicketType> ticketTypes) {
    _subtotal = 0.0;
    _selectedTickets.forEach((ticketId, quantity) {
      final ticketType = ticketTypes.firstWhere((t) => t.id == ticketId);
      _subtotal += ticketType.price * quantity;
    });
    _serviceFee = _subtotal * 0.05; // 5% service fee
    _total = _subtotal + _serviceFee;
  }

  IconData _getTicketIcon(String? icon) {
    switch (icon) {
      case 'star':
        return Icons.star;
      case 'table':
        return Icons.table_restaurant;
      default:
        return Icons.confirmation_number;
    }
  }

  Color _getTicketIconColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.available:
        return AppColors.brandPrimary;
      case TicketStatus.lowStock:
        return AppColors.warning;
      case TicketStatus.soldOut:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.available:
        return AppColors.success;
      case TicketStatus.lowStock:
        return AppColors.warning;
      case TicketStatus.soldOut:
        return AppColors.error;
    }
  }

  String _getStatusText(TicketStatus status, int? availableQuantity) {
    switch (status) {
      case TicketStatus.available:
        return 'Available';
      case TicketStatus.lowStock:
        return 'Low Stock! Only $availableQuantity left';
      case TicketStatus.soldOut:
        return 'Sold Out';
    }
  }
}
