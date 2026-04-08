import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../../core/services/stripe_payment_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/event_detail.dart';
import '../../domain/entities/ticket_type.dart';
import '../bloc/events_cubit.dart';
import '../bloc/events_state.dart';
import '../bloc/tickets_cubit.dart';
import '../bloc/tickets_state.dart';
import 'order_confirmation_page.dart';
import 'payment_failed_page.dart';

class CheckoutPage extends StatefulWidget {
  final String eventId;
  final List<Map<String, dynamic>> tickets;

  /// Pre-filled from current user when available.
  final String? initialEmail;

  const CheckoutPage({
    super.key,
    required this.eventId,
    required this.tickets,
    this.initialEmail,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  String _phoneNumber = '';
  final _promoController = TextEditingController();
  final StripePaymentService _stripe = di.sl<StripePaymentService>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<EventsCubit>()..loadEventDetail(widget.eventId)),
        BlocProvider(create: (_) => di.sl<TicketsCubit>()),
      ],
      child: BlocListener<TicketsCubit, TicketsState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (_) => OrderConfirmationPage(order: state.order),
              ),
            );
          } else if (state is PaymentFailed) {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PaymentFailedPage(
                  message: state.message,
                  order: state.order,
                ),
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Checkout'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: BlocBuilder<EventsCubit, EventsState>(
            builder: (context, state) {
              if (state is EventDetailLoaded) {
                return _buildContent(context, state.event);
              }
              return const Center(
                child: HabraCircularLoader(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EventDetail event) {
    final orderTotal = _calculateOrderTotal(event);
    final subtotal = _calculateSubtotal(event);
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEventSummary(event),
            _buildContactInfo(),
            _buildPaymentSection(context),
            _buildPromoCode(context),
            _buildTotalSummary(subtotal, orderTotal),
            _buildPayButton(context, orderTotal),
          ],
        ),
      ),
    );
  }

  Widget _buildEventSummary(EventDetail event) {
    final breakdown = _getTicketBreakdown(event);
    final ticketSummary = breakdown.isEmpty
        ? '${widget.tickets.length} ticket(s)'
        : breakdown.map((b) => '${b.quantity} x ${b.name}').join(', ');
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
                  ticketSummary,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${_calculateSubtotal(event).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          IntlPhoneField(
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
            initialCountryCode: 'US',
            onChanged: (phone) => setState(() => _phoneNumber = phone.completeNumber),
            validator: (value) {
              if (value == null || value.number.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    final stripeOn = _stripe.isConfigured;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.backgroundGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, size: 22, color: AppColors.brandPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        stripeOn
                            ? 'You’ll complete payment in Stripe’s secure sheet. Card, Apple Pay, Google Pay, and other methods your account supports may appear there.'
                            : 'Online payment is not configured for this build. Add STRIPE_PUBLISHABLE_KEY and your payment backend to enable checkout.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
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

  Widget _buildPromoCode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _promoController,
              decoration: const InputDecoration(
                labelText: 'Promo code (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Promo codes are not available yet.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummary(double subtotal, double total) {
    final serviceFee = subtotal * 0.05;
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
              const Text('Subtotal'),
              Text('\$${subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service fee'),
              Text('\$${serviceFee.toStringAsFixed(2)}'),
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
                '\$${total.toStringAsFixed(2)}',
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

  Widget _buildPayButton(BuildContext context, double total) {
    return BlocBuilder<TicketsCubit, TicketsState>(
      builder: (context, state) {
        final isLoading = state is PaymentProcessing || state is OrderLoading;
        final canPay = _stripe.isConfigured;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_stripe.isConfigured)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Payments are unavailable until Stripe is configured.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              AppButton(
                text: 'Pay \$${total.toStringAsFixed(2)}',
                backgroundColor: AppColors.brandSecondary,
                isLoading: isLoading,
                icon: Icons.lock_outline,
                onPressed: isLoading || !canPay
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _processPayment(context);
                        }
                      },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _stripe.isConfigured ? 'Secured by Stripe' : 'Habra checkout',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _processPayment(BuildContext context) {
    final cubit = context.read<TicketsCubit>();
    cubit.performCheckout(
      eventId: widget.eventId,
      tickets: widget.tickets,
      contactInfo: {
        'email': _emailController.text,
        'phone': _phoneNumber,
      },
      paymentMethod: const {
        'type': 'stripe_payment_sheet',
      },
      promoCode: _promoController.text.isEmpty ? null : _promoController.text,
    );
  }

  double _calculateSubtotal(EventDetail? event) {
    if (event == null) return 0.0;
    double subtotal = 0.0;
    for (final t in widget.tickets) {
      final ticketTypeId = t['ticketTypeId'] as String?;
      final quantity = (t['quantity'] as num?)?.toInt() ?? 0;
      if (ticketTypeId == null || quantity <= 0) continue;
      TicketType? ticketType;
      for (final tt in event.ticketTypes) {
        if (tt.id == ticketTypeId) {
          ticketType = tt;
          break;
        }
      }
      if (ticketType != null) {
        subtotal += ticketType.price * quantity;
      }
    }
    return subtotal;
  }

  double _calculateOrderTotal(EventDetail? event) {
    final subtotal = _calculateSubtotal(event);
    final serviceFee = subtotal * 0.05;
    return subtotal + serviceFee;
  }

  /// Returns list of (ticketTypeName, quantity, price) for display.
  List<({String name, int quantity, double price})> _getTicketBreakdown(EventDetail event) {
    final result = <({String name, int quantity, double price})>[];
    for (final t in widget.tickets) {
      final ticketTypeId = t['ticketTypeId'] as String?;
      final quantity = (t['quantity'] as num?)?.toInt() ?? 0;
      if (ticketTypeId == null || quantity <= 0) continue;
      TicketType? ticketType;
      for (final tt in event.ticketTypes) {
        if (tt.id == ticketTypeId) {
          ticketType = tt;
          break;
        }
      }
      if (ticketType != null) {
        result.add((name: ticketType.name, quantity: quantity, price: ticketType.price));
      }
    }
    return result;
  }
}
