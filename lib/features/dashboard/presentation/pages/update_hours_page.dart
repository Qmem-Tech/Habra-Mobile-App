import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../bloc/dashboard_cubit.dart';

class UpdateHoursPage extends StatefulWidget {
  const UpdateHoursPage({super.key, required this.businessId});

  final String businessId;

  @override
  State<UpdateHoursPage> createState() => _UpdateHoursPageState();
}

class _UpdateHoursPageState extends State<UpdateHoursPage> {
  final _openingController = TextEditingController(text: '09:00');
  final _closingController = TextEditingController(text: '17:00');

  @override
  void dispose() {
    _openingController.dispose();
    _closingController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final parts = controller.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.firstOrNull ?? '9') ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _save() async {
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Saving hours...');
    final success = await ctx.read<DashboardCubit>().updateBusinessHours(
      widget.businessId,
      {
        'opening_time': _openingController.text.trim(),
        'closing_time': _closingController.text.trim(),
      },
    );
    if (!ctx.mounted) return;
    LoaderHelper.hide(ctx);
    if (success) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Hours updated')));
      Navigator.pop(ctx, true);
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Failed to update hours')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Update Hours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppResources.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set your opening and closing times', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            _buildTimeRow('Opening Time', _openingController),
            const SizedBox(height: 16),
            _buildTimeRow('Closing Time', _closingController),
            const Spacer(),
            AppButton(text: 'Save Hours', onPressed: _save),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () => _pickTime(controller),
      child: AbsorbPointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.backgroundWhite,
                suffixIcon: const Icon(Icons.access_time, color: AppColors.brandPrimary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppResources.radiusM), borderSide: BorderSide(color: AppColors.backgroundGrey)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppResources.radiusM), borderSide: BorderSide(color: AppColors.backgroundGrey)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
