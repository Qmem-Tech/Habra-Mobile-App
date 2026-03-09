import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../home/domain/entities/business_presence.dart';
import '../bloc/dashboard_cubit.dart';

class EditBusinessPage extends StatefulWidget {
  const EditBusinessPage({super.key, required this.business});

  final BusinessPresence business;

  @override
  State<EditBusinessPage> createState() => _EditBusinessPageState();
}

class _EditBusinessPageState extends State<EditBusinessPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business.name);
    _descriptionController = TextEditingController(text: widget.business.category);
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _streetController = TextEditingController(text: widget.business.locationName ?? '');
    _cityController = TextEditingController(text: widget.business.city ?? '');
    _stateController = TextEditingController(text: widget.business.state ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name is required')),
      );
      return;
    }
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Saving...');
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      'website': _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
      'address_street': _streetController.text.trim().isNotEmpty ? _streetController.text.trim() : null,
      'address_city': _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      'address_state': _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
    };
    data.removeWhere((_, v) => v == null);
    final success = await ctx.read<DashboardCubit>().updateBusiness(widget.business.id, data);
    if (!ctx.mounted) return;
    LoaderHelper.hide(ctx);
    if (success) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Business updated')),
      );
      Navigator.pop(ctx, true);
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Failed to update business')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Edit Business', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppResources.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Basic Info'),
            const SizedBox(height: 12),
            _buildField('Business Name', _nameController),
            const SizedBox(height: 12),
            _buildField('Description', _descriptionController, maxLines: 3),
            const SizedBox(height: 24),
            _sectionTitle('Contact'),
            const SizedBox(height: 12),
            _buildField('Phone', _phoneController),
            const SizedBox(height: 12),
            _buildField('Email', _emailController),
            const SizedBox(height: 12),
            _buildField('Website', _websiteController),
            const SizedBox(height: 24),
            _sectionTitle('Address'),
            const SizedBox(height: 12),
            _buildField('Street', _streetController),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildField('City', _cityController)),
              const SizedBox(width: 12),
              Expanded(child: _buildField('State', _stateController)),
            ]),
            const SizedBox(height: 32),
            AppButton(text: 'Save Changes', onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary));

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundWhite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppResources.radiusM), borderSide: BorderSide(color: AppColors.backgroundGrey)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppResources.radiusM), borderSide: BorderSide(color: AppColors.backgroundGrey)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
