import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../data/datasources/ticket_resale_datasource.dart';

/// Bottom sheet to list a ticket for resale.
class ListTicketSheet extends StatefulWidget {
  const ListTicketSheet({
    super.key,
    required this.ticketId,
    required this.ticketTypeName,
    required this.eventTitle,
  });

  final String ticketId;
  final String ticketTypeName;
  final String eventTitle;

  @override
  State<ListTicketSheet> createState() => _ListTicketSheetState();
}

class _ListTicketSheetState extends State<ListTicketSheet> {
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _listForSale() async {
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await di.sl<TicketResaleDatasource>().listTicketForSale(
        ticketId: widget.ticketId,
        askingPrice: price,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket listed for sale!')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sell Ticket',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.eventTitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              widget.ticketTypeName,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Asking price (\$)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'List for Sale',
              onPressed: _isLoading ? null : _listForSale,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
