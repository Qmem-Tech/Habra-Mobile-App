import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/event_detail.dart';
import '../../domain/entities/ticket_type.dart';
import '../bloc/events_cubit.dart';
import '../bloc/events_state.dart';
import '../bloc/tickets_cubit.dart';
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
              return const HabraCircularLoader(fullScreen: true);
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
    final availableTypes = event.ticketTypes
        .where((t) =>
            t.status == TicketStatus.available || t.status == TicketStatus.lowStock)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select ticket type',
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
          const SizedBox(height: 12),
          _buildTicketTypeDropdown(event, availableTypes),
          if (availableTypes.isEmpty && event.ticketTypes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'All ticket types are currently sold out.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTicketTypeDropdown(EventDetail event, List<TicketType> availableTypes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TicketType>(
          hint: Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: AppColors.brandPrimary, size: 22),
              const SizedBox(width: 12),
              Text(
                'Choose ticket type (Regular, VIP, etc.)',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.brandPrimary, size: 28),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          elevation: 8,
          items: availableTypes
              .map(
                (t) => DropdownMenuItem<TicketType>(
                  value: t,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _getTicketIcon(t.icon),
                          color: _getTicketIconColor(t.status),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (t.description.isNotEmpty)
                                Text(
                                  t.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (t.status == TicketStatus.lowStock && t.availableQuantity != null)
                                Text(
                                  'Only ${t.availableQuantity} left',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${t.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: availableTypes.isEmpty
              ? null
              : (TicketType? selected) {
                  if (selected == null) return;
                  setState(() {
                    final current = _selectedTickets[selected.id] ?? 0;
                    final maxQty = selected.status == TicketStatus.lowStock &&
                            selected.availableQuantity != null
                        ? selected.availableQuantity!
                        : 10;
                    _selectedTickets[selected.id] = (current + 1).clamp(0, maxQty);
                    if (_currentEvent != null) {
                      _calculateTotal(_currentEvent!.ticketTypes);
                    }
                  });
                },
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final totalItems = _selectedTickets.values.fold(0, (sum, qty) => sum + qty);
    final selectedBreakdown = <({TicketType type, int qty})>[];
    if (_currentEvent != null) {
      for (final e in _selectedTickets.entries) {
        if (e.value <= 0) continue;
        TicketType? tt;
        for (final t in _currentEvent!.ticketTypes) {
          if (t.id == e.key) {
            tt = t;
            break;
          }
        }
        if (tt != null) selectedBreakdown.add((type: tt, qty: e.value));
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (selectedBreakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...selectedBreakdown.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.type.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _buildQuantityChip(b.type),
                    const SizedBox(width: 12),
                    Text(
                      '\$${(b.type.price * b.qty).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal ($totalItems items)', style: TextStyle(color: AppColors.textSecondary)),
              Text('\$${_subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Service Fee', style: TextStyle(color: AppColors.textSecondary)),
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
            color: Colors.black.withValues(alpha:0.05),
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

                        final authState = context.read<AuthCubit>().state;
                        final initialEmail =
                            authState is AuthAuthenticated ? authState.user.email : null;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutPage(
                              eventId: event.id,
                              tickets: tickets,
                              initialEmail: initialEmail,
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

  Widget _buildQuantityChip(TicketType ticketType) {
    final quantity = _selectedTickets[ticketType.id] ?? 0;
    final maxQty = ticketType.status == TicketStatus.lowStock &&
            ticketType.availableQuantity != null
        ? ticketType.availableQuantity!
        : 10;
    final options = List.generate(maxQty + 1, (i) => i);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: quantity,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.brandPrimary, size: 20),
          borderRadius: BorderRadius.circular(8),
          dropdownColor: Colors.white,
          elevation: 4,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          items: options
              .map((q) => DropdownMenuItem<int>(value: q, child: Text('$q')))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              if (v == 0) {
                _selectedTickets.remove(ticketType.id);
              } else {
                _selectedTickets[ticketType.id] = v;
              }
              if (_currentEvent != null) {
                _calculateTotal(_currentEvent!.ticketTypes);
              }
            });
          },
        ),
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

}
