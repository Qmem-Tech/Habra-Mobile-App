import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../bloc/dashboard_cubit.dart';

/// Preset times in 30-min intervals (24h format for storage).
/// Keys: "06:00", "06:30", ... "23:30". Values: "6:00 AM", "6:30 AM", ...
final Map<String, String> _presetTimes = () {
  final map = <String, String>{};
  for (int h = 6; h <= 23; h++) {
    for (int m = 0; m < 60; m += 30) {
      final key = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      final amPm = h < 12 ? 'AM' : 'PM';
      map[key] = '$hour12:${m.toString().padLeft(2, '0')} $amPm';
    }
  }
  map['00:00'] = '12:00 AM';
  return map;
}();

class UpdateHoursPage extends StatefulWidget {
  const UpdateHoursPage({super.key, required this.businessId});

  final String businessId;

  @override
  State<UpdateHoursPage> createState() => _UpdateHoursPageState();
}

class _UpdateHoursPageState extends State<UpdateHoursPage> {
  final _openingController = TextEditingController(text: '09:00');
  final _closingController = TextEditingController(text: '17:00');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingHours();
  }

  Future<void> _loadExistingHours() async {
    final hours = await context.read<DashboardCubit>().getBusinessHours(widget.businessId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (hours != null) {
        final opening = hours['opening_time'];
        final closing = hours['closing_time'];
        if (opening != null && opening.isNotEmpty) {
          _openingController.text = _normalizeToPreset(opening);
        }
        if (closing != null && closing.isNotEmpty) {
          _closingController.text = _normalizeToPreset(closing);
        }
      }
    });
  }

  /// Normalize "09:00:00" or "9:00" to "HH:MM" format.
  String _normalizeToPreset(String value) {
    final parts = value.split(':');
    if (parts.isEmpty) return '09:00';
    final h = int.tryParse(parts[0]) ?? 9;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return '${h.clamp(0, 23).toString().padLeft(2, '0')}:${m.clamp(0, 59).toString().padLeft(2, '0')}';
  }

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

  String _formatTime(String key) {
    final parts = key.split(':');
    if (parts.length < 2) return key;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final amPm = h < 12 ? 'AM' : 'PM';
    return '$hour12:$m $amPm';
  }

  void _selectPresetTime(TextEditingController controller, String key) {
    controller.text = key;
    setState(() {});
  }

  Future<void> _save() async {
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Saving hours...');
    try {
      final success = await ctx.read<DashboardCubit>().updateBusinessHours(
            widget.businessId,
            {
              'opening_time': _openingController.text.trim(),
              'closing_time': _closingController.text.trim(),
            },
          );
      if (!ctx.mounted) return;
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      if (success) {
        ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Hours updated')));
        Navigator.pop(ctx, true);
      } else {
        ErrorDisplayHelper.show(ctx, message: 'We couldn\'t update your hours. Please try again.', title: 'Update failed');
      }
    } catch (e) {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
        if (ctx.mounted) {
          ErrorDisplayHelper.show(ctx, error: e, title: 'Update failed');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Update Hours',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
          : Padding(
              padding: const EdgeInsets.all(AppResources.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set your opening and closing times',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTimeSection('Opening Time', _openingController),
                  const SizedBox(height: 20),
                  _buildTimeSection('Closing Time', _closingController),
                  const Spacer(),
                  AppButton(text: 'Save Hours', onPressed: _save),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeSection(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickTime(controller),
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.backgroundWhite,
                suffixIcon: const Icon(
                  Icons.access_time,
                  color: AppColors.brandPrimary,
                ),
                hintText: 'Tap to pick time',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                  borderSide: BorderSide(color: AppColors.backgroundGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                  borderSide: BorderSide(color: AppColors.backgroundGrey),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Or select from presets:',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '06:00',
            '08:00',
            '09:00',
            '10:00',
            '12:00',
            '17:00',
            '18:00',
            '21:00',
          ].map((key) {
            final isSelected = controller.text == key;
            return GestureDetector(
              onTap: () => _selectPresetTime(controller, key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPrimary.withValues(alpha: 0.2)
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.backgroundGrey,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  _presetTimes[key] ?? _formatTime(key),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
