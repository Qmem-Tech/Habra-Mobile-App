import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final availableTypes = event.ticketTypes
        .where((t) =>
            t.status == TicketStatus.available || t.status == TicketStatus.lowStock)
        .toList();
    final soldOutTypes =
        event.ticketTypes.where((t) => t.status == TicketStatus.soldOut).toList();
    final allTypes = [...availableTypes, ...soldOutTypes];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: Column(
              children: [
                _buildEventInfoCard(event),
                const SizedBox(height: 16),
                _buildTicketsSection(allTypes),
                const SizedBox(height: 16),
                _buildOrderSummary(),
              ],
            ),
          ),
        ),
        _buildContinueButton(context, event),
      ],
    );
  }

  Widget _buildEventInfoCard(EventDetail event) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: event.imageUrl.startsWith('assets/')
                ? Image.asset(
                    event.imageUrl,
                    width: 56,
                    height: 56,
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
                    width: 56,
                    height: 56,
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
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat('EEE, MMM d • h:mm a').format(event.startDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${event.venue}, ${event.city}',
                        style: TextStyle(
                          fontSize: 13,
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

  Widget _buildTicketsSection(List<TicketType> ticketTypes) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tickets',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
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
          ...ticketTypes.map(_buildTicketCard),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (selectedBreakdown.isNotEmpty) const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal($totalItems items)', style: TextStyle(color: AppColors.textSecondary)),
              Text('\$${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
              Text('\$${_serviceFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
            children: [
              Expanded(
                child: Column(
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
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  text: 'Continue',
                  onPressed: hasTickets
                      ? () {
                          final tickets = _selectedTickets.entries
                              .map((e) => {
                                    'ticketTypeId': e.key,
                                    'quantity': e.value,
                                  })
                              .toList();

                          final authState = context.read<AuthCubit>().state;
                          final initialEmail = authState is AuthAuthenticated
                              ? authState.user.email
                              : null;

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

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  int _maxQtyFor(TicketType ticketType) {
    if (ticketType.status == TicketStatus.lowStock &&
        ticketType.availableQuantity != null) {
      return ticketType.availableQuantity!.clamp(0, 10);
    }
    return 10;
  }

  void _updateQuantity(TicketType ticketType, int nextQty) {
    final maxQty = _maxQtyFor(ticketType);
    final qty = nextQty.clamp(0, maxQty);
    setState(() {
      if (qty == 0) {
        _selectedTickets.remove(ticketType.id);
      } else {
        _selectedTickets[ticketType.id] = qty;
      }
      if (_currentEvent != null) {
        _calculateTotal(_currentEvent!.ticketTypes);
      }
    });
  }

  Widget _buildQuantityStepper(TicketType ticketType, {required bool enabled}) {
    final qty = _selectedTickets[ticketType.id] ?? 0;
    final maxQty = _maxQtyFor(ticketType);
    final canMinus = enabled && qty > 0;
    final canPlus = enabled && qty < maxQty;

    return Row(
      children: [
        _stepperButton(
          icon: Icons.remove,
          enabled: canMinus,
          onTap: () => _updateQuantity(ticketType, qty - 1),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _stepperButton(
          icon: Icons.add,
          enabled: canPlus,
          onTap: () => _updateQuantity(ticketType, qty + 1),
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? AppColors.brandPrimary : AppColors.backgroundLight,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? Colors.white : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(TicketType ticketType) {
    final isSoldOut = ticketType.status == TicketStatus.soldOut;
    final isLowStock = ticketType.status == TicketStatus.lowStock;

    final statusText = isSoldOut
        ? 'Sold Out'
        : isLowStock
            ? 'Low Stock! Only ${ticketType.availableQuantity ?? 0} left'
            : 'Available';
    final statusColor = isSoldOut
        ? AppColors.error
        : isLowStock
            ? AppColors.warning
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTicketIcon(ticketType.icon),
                  color: _getTicketIconColor(ticketType.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticketType.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '\$${ticketType.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticketType.description.isEmpty
                          ? 'Ticket access'
                          : ticketType.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStatusDot(statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 13,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                isSoldOut ? 'Unavailable' : 'View details',
                style: TextStyle(
                  fontSize: 18,
                  color: isSoldOut ? AppColors.textTertiary : AppColors.brandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isSoldOut)
                OutlinedButton.icon(
                  onPressed: () => _joinWaitlist(ticketType),
                  icon: const Icon(Icons.notifications_none, size: 16),
                  label: const Text('Notify Me'),
                )
              else
                _buildQuantityStepper(ticketType, enabled: true),
            ],
          ),
        ],
      ),
    );
  }

  /// Adds the current user to the waitlist for [ticketType] on this event so
  /// they get notified when seats free up. Idempotent on (user, event, ticket).
  Future<void> _joinWaitlist(TicketType ticketType) async {
    final messenger = ScaffoldMessenger.of(context);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in to get notified.')),
      );
      return;
    }
    try {
      await Supabase.instance.client.from('event_ticket_waitlist').upsert({
        'user_id': userId,
        'event_id': widget.eventId,
        'ticket_type_id': ticketType.id,
      }, onConflict: 'user_id,event_id,ticket_type_id');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'You\'re on the waitlist — we\'ll notify you if ${ticketType.name} reopens.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Graceful no-op when the table/migration isn\'t deployed yet — keep the
      // user-facing message honest rather than showing a raw Postgrest error.
      final msg = e.toString().toLowerCase();
      final fallback = (msg.contains('does not exist') || msg.contains('not found'))
          ? 'Waitlist is not available yet. Try again later.'
          : 'Could not join waitlist: $e';
      messenger.showSnackBar(SnackBar(content: Text(fallback)));
    }
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
