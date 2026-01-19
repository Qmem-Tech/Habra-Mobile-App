import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/tickets_cubit.dart';
import '../bloc/tickets_state.dart';
import '../bloc/events_cubit.dart';
import '../bloc/events_state.dart';
import 'order_confirmation_page.dart';
import 'payment_failed_page.dart';

class CheckoutPage extends StatefulWidget {
  final String eventId;
  final List<Map<String, dynamic>> tickets;

  const CheckoutPage({super.key, required this.eventId, required this.tickets});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'abebe.kebede@gmail.com');
  final _phoneController = TextEditingController(text: '0911111111');
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _zipController = TextEditingController();
  final _promoController = TextEditingController();
  String _selectedPaymentMethod = 'card';
  bool _saveCard = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _zipController.dispose();
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
              MaterialPageRoute(
                builder: (_) => OrderConfirmationPage(order: state.order),
              ),
            );
          } else if (state is PaymentFailed) {
            Navigator.push(
              context,
              MaterialPageRoute(
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

  Widget _buildContent(BuildContext context, event) {
    final orderTotal = _calculateOrderTotal(event);
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildEventSummary(event),
            _buildContactInfo(),
            _buildPaymentMethod(),
            if (_selectedPaymentMethod == 'card') _buildCardDetails(),
            _buildPromoCode(),
            _buildTotalSummary(orderTotal),
            _buildPayButton(context, orderTotal),
          ],
        ),
      ),
    );
  }

  Widget _buildEventSummary(event) {
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
                  '${widget.tickets.length} x VIP Tickets',
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
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              suffixIcon: Icon(Icons.check_circle, color: AppColors.brandSecondary),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone',
              prefixIcon: const Icon(Icons.phone),
              suffixIcon: Icon(Icons.check_circle, color: AppColors.brandSecondary),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPaymentTab('card', 'Card', Icons.credit_card),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentTab('apple', 'Apple', Icons.apple),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentTab('google', 'Google', Icons.account_balance_wallet),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTab(String method, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.brandPrimary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.brandPrimary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvcController,
                  decoration: const InputDecoration(
                    labelText: 'CVC',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _zipController,
            decoration: const InputDecoration(
              labelText: 'Zip Code',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCode() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _promoController,
              decoration: const InputDecoration(
                labelText: 'Promo Code',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummary(double total) {
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
              Text('\$${_calculateSubtotal(null).toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service Fee'),
              Text('\$${(_calculateSubtotal(null) * 0.05).toStringAsFixed(2)}'),
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
                children: [
                  Checkbox(
                    value: _saveCard,
                    onChanged: (value) => setState(() => _saveCard = value ?? false),
                  ),
                  const Text('Save card for future purchases'),
                ],
              ),
              AppButton(
                text: 'PAY \$${total.toStringAsFixed(2)}',
                backgroundColor: AppColors.brandSecondary,
                isLoading: isLoading,
                icon: Icons.lock,
                onPressed: isLoading
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
                  Icon(Icons.shield, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Secured by Stripe',
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
    final eventsCubit = context.read<EventsCubit>();

    // First create order
    cubit.createOrder(
      eventId: widget.eventId,
      tickets: widget.tickets,
      contactInfo: {
        'email': _emailController.text,
        'phone': _phoneController.text,
      },
    );

    // Then process payment
    cubit.processPayment(
      orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
      paymentMethod: {
        'type': _selectedPaymentMethod,
        'cardNumber': _cardNumberController.text,
        'expiry': _expiryController.text,
        'cvc': _cvcController.text,
        'zipCode': _zipController.text,
      },
      promoCode: _promoController.text.isEmpty ? null : _promoController.text,
    );
  }

  double _calculateSubtotal(dynamic event) {
    // Mock calculation - in real app, calculate from tickets
    return 140.0;
  }

  double _calculateOrderTotal(dynamic event) {
    final subtotal = _calculateSubtotal(event);
    final serviceFee = subtotal * 0.05;
    return subtotal + serviceFee;
  }
}
