import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/navigation/main_navigation_wrapper.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/order.dart' show OrderStatus;
import '../../domain/entities/ticket.dart';
import '../bloc/tickets_cubit.dart';
import '../bloc/tickets_state.dart';
import '../widgets/list_ticket_sheet.dart';
import 'ticket_detail_page.dart';

enum _TicketSortOption { newestFirst, oldestFirst }

enum _TicketStatusFilter { all, confirmed, confirming, failed, refunded, cancelled }

class MyTicketsPage extends StatefulWidget {
  final bool initialUpcoming;

  const MyTicketsPage({super.key, this.initialUpcoming = true});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  late bool _isUpcoming;
  _TicketSortOption _sortOption = _TicketSortOption.newestFirst;
  _TicketStatusFilter _statusFilter = _TicketStatusFilter.all;
  final Set<String> _collapsedMonths = <String>{};

  @override
  void initState() {
    super.initState();
    _isUpcoming = widget.initialUpcoming;
  }

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
      child: Builder(
        builder: (blocContext) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Tickets'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Column(
              children: [
                _buildTabBar(blocContext),
                Expanded(
                  child: BlocBuilder<TicketsCubit, TicketsState>(
                    builder: (context, state) {
                      if (state is TicketsLoading) {
                        return const HabraCircularLoader(fullScreen: true);
                      }

                      if (state is TicketsError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 48,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextButton.icon(
                                  onPressed: () {
                                    context
                                        .read<TicketsCubit>()
                                        .loadUserTickets(upcomingOnly: _isUpcoming);
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try again'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state is TicketsEmpty) {
                        return _buildEmptyState();
                      }

                      if (state is TicketsLoaded) {
                        return _buildTicketsList(
                          state.tickets,
                          pendingOrderActionId: state.pendingOrderActionId,
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar(BuildContext blocContext) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(blocContext, 'Upcoming', true),
          ),
          Expanded(
            child: _buildTab(blocContext, 'Past', false),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext blocContext, String label, bool isUpcoming) {
    final isSelected = _isUpcoming == isUpcoming;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isUpcoming = isUpcoming;
        });
        blocContext.read<TicketsCubit>().loadUserTickets(upcomingOnly: isUpcoming);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.backgroundLight.withValues(alpha:0.8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.textPrimary : AppColors.brandPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsList(
    List<Ticket> tickets, {
    String? pendingOrderActionId,
  }) {
    final filtered = _applyStatusFilter(tickets);
    final groupedTickets = _groupTicketsByMonth(filtered);

    return RefreshIndicator(
      color: AppColors.customerHomePrimary,
      onRefresh: () async {
        await context.read<TicketsCubit>().loadUserTickets(upcomingOnly: _isUpcoming);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildListControls(),
          const SizedBox(height: 12),
          if (groupedTickets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Text(
                'No tickets match this filter.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...groupedTickets.entries.expand((entry) {
              final isCollapsed = _collapsedMonths.contains(entry.key);
              return <Widget>[
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      if (isCollapsed) {
                        _collapsedMonths.remove(entry.key);
                      } else {
                        _collapsedMonths.add(entry.key);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${entry.key} (${entry.value.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          isCollapsed ? Icons.expand_more : Icons.expand_less,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isCollapsed) ...entry.value.map(
                  (ticket) => _buildTicketCard(
                    ticket,
                    pendingOrderActionId: pendingOrderActionId,
                  ),
                ),
                const SizedBox(height: 20),
              ];
            }),
        ],
      ),
    );
  }

  static String _orderStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Payment pending';
      case OrderStatus.processing:
        return 'Confirming payment';
      case OrderStatus.completed:
        return '';
      case OrderStatus.failed:
        return 'Payment failed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String _formatTicketAmount(BuildContext context, double amount) {
    final code = AppConfig.stripePaymentCurrency.toUpperCase();
    final locale = Localizations.localeOf(context).toLanguageTag();
    try {
      return NumberFormat.simpleCurrency(
        name: code,
        locale: locale,
      ).format(amount);
    } catch (_) {
      return NumberFormat.currency(
        name: code,
        symbol: '$code ',
        decimalDigits: 2,
      ).format(amount);
    }
  }

  Widget _buildListControls() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<_TicketSortOption>(
            value: _sortOption,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: AppColors.backgroundWhite,
            iconEnabledColor: AppColors.textPrimary,
            decoration: InputDecoration(
              labelText: 'Sort',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: _TicketSortOption.newestFirst,
                child: Text('Newest month first'),
              ),
              DropdownMenuItem(
                value: _TicketSortOption.oldestFirst,
                child: Text('Oldest month first'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _sortOption = value);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<_TicketStatusFilter>(
            value: _statusFilter,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: AppColors.backgroundWhite,
            iconEnabledColor: AppColors.textPrimary,
            decoration: InputDecoration(
              labelText: 'Filter',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const [
              DropdownMenuItem(value: _TicketStatusFilter.all, child: Text('All statuses')),
              DropdownMenuItem(value: _TicketStatusFilter.confirmed, child: Text('Confirmed')),
              DropdownMenuItem(value: _TicketStatusFilter.confirming, child: Text('Confirming')),
              DropdownMenuItem(value: _TicketStatusFilter.failed, child: Text('Failed')),
              DropdownMenuItem(value: _TicketStatusFilter.cancelled, child: Text('Cancelled')),
              DropdownMenuItem(value: _TicketStatusFilter.refunded, child: Text('Refunded')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _statusFilter = value);
            },
          ),
        ),
      ],
    );
  }

  List<Ticket> _applyStatusFilter(List<Ticket> tickets) {
    switch (_statusFilter) {
      case _TicketStatusFilter.all:
        return tickets;
      case _TicketStatusFilter.confirmed:
        return tickets.where((t) => t.orderPaymentStatus == OrderStatus.completed).toList();
      case _TicketStatusFilter.confirming:
        return tickets
            .where((t) =>
                t.orderPaymentStatus == OrderStatus.processing ||
                t.orderPaymentStatus == OrderStatus.pending)
            .toList();
      case _TicketStatusFilter.failed:
        return tickets.where((t) => t.orderPaymentStatus == OrderStatus.failed).toList();
      case _TicketStatusFilter.refunded:
        return tickets.where((t) => t.orderPaymentStatus == OrderStatus.refunded).toList();
      case _TicketStatusFilter.cancelled:
        return tickets.where((t) => t.orderPaymentStatus == OrderStatus.cancelled).toList();
    }
  }

  bool _canRemoveOrder(OrderStatus status) {
    return status == OrderStatus.pending ||
        status == OrderStatus.processing ||
        status == OrderStatus.failed ||
        status == OrderStatus.cancelled;
  }

  Future<void> _removeUnpaidOrder(Ticket ticket) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this ticket?'),
        content: const Text(
          'This removes this failed/confirming order from My Tickets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    final error = await context.read<TicketsCubit>().cancelUnpaidOrder(ticket.orderId);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (error != null && error.trim().isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Ticket removed from My Tickets.')),
    );
  }

  Widget _buildTicketCard(
    Ticket ticket, {
    String? pendingOrderActionId,
  }) {
    final isOrderActionPending = pendingOrderActionId == ticket.orderId;
    final canRemove = !ticket.isPaymentConfirmed &&
        _canRemoveOrder(ticket.orderPaymentStatus) &&
        ticket.orderId.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        return const Icon(Icons.event, size: 32, color: AppColors.textSecondary);
                      },
                    )
                  : Image.network(
                      ticket.event.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.event, size: 32, color: AppColors.textSecondary);
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
                    Icon(Icons.confirmation_number, size: 14, color: AppColors.brandPrimary),
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
                const SizedBox(height: 6),
                Text(
                  ticket.event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!ticket.isPaymentConfirmed) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      avatar: Icon(
                        Icons.schedule,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      label: Text(
                        _orderStatusLabel(ticket.orderPaymentStatus),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                      side: BorderSide.none,
                    ),
                  ),
                ],
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      _formatTicketAmount(context, ticket.price),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ticket.isSyntheticOrderRow ? 'Order total' : 'Per ticket',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ticket.isPaymentConfirmed) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: !ticket.isSyntheticOrderRow
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TicketDetailPage(ticketId: ticket.ticketId),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.backgroundGrey,
                            disabledForegroundColor: AppColors.textTertiary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            ticket.isSyntheticOrderRow ? 'Details soon' : 'View Ticket',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: !ticket.isSyntheticOrderRow
                            ? () {
                                final ctx = context;
                                showModalBottomSheet(
                                  context: ctx,
                                  builder: (_) => ListTicketSheet(
                                    ticketId: ticket.ticketId,
                                    ticketTypeName: ticket.ticketTypeName,
                                    eventTitle: ticket.event.title,
                                  ),
                                ).then((result) {
                                  if (result == true && ctx.mounted) {
                                    ctx
                                        .read<TicketsCubit>()
                                        .loadUserTickets(upcomingOnly: _isUpcoming);
                                  }
                                });
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.brandPrimary),
                          foregroundColor: AppColors.brandPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Sell',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: canRemove && !isOrderActionPending
                          ? () => _removeUnpaidOrder(ticket)
                          : null,
                      icon: isOrderActionPending
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                      label: Text(isOrderActionPending ? 'Removing…' : 'Remove'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: canRemove ? AppColors.error : AppColors.backgroundGrey,
                        ),
                        foregroundColor: canRemove ? AppColors.error : AppColors.textTertiary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
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
              Navigator.pop(context);
              MainNavigationWrapper.navigateToTab(context, 1);
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
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aDate = DateFormat('MMMM yyyy').parse(a);
        final bDate = DateFormat('MMMM yyyy').parse(b);
        if (_sortOption == _TicketSortOption.newestFirst) {
          return bDate.compareTo(aDate);
        }
        return aDate.compareTo(bDate);
      });
    final sorted = <String, List<Ticket>>{};
    for (final key in sortedKeys) {
      final monthTickets = [...grouped[key]!]
        ..sort((a, b) => a.event.startDate.compareTo(b.event.startDate));
      if (_sortOption == _TicketSortOption.newestFirst) {
        monthTickets.sort((a, b) => b.event.startDate.compareTo(a.event.startDate));
      }
      sorted[key] = monthTickets;
    }
    return sorted;
  }
}
