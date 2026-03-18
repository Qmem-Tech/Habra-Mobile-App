import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../../domain/entities/create_event_data.dart';
import '../../domain/entities/event_category.dart';
import '../bloc/create_event_cubit.dart';
import '../bloc/create_event_state.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueAddressController = TextEditingController();

  DateTime? _startAt;
  DateTime? _endAt;
  EventCategory _category = EventCategory.community;
  File? _imageFile;
  String? _imageUrl;

  final List<_TicketTypeRow> _ticketTypes = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueNameController.dispose();
    _venueAddressController.dispose();
    for (final row in _ticketTypes) {
      row.nameController.dispose();
      row.priceController.dispose();
      row.quantityController.dispose();
    }
    super.dispose();
  }

  String? _getSelectedBusinessId() {
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded &&
        homeState.selectedPresence != null &&
        homeState.selectedPresence!.id != 'all') {
      return homeState.selectedPresence!.id;
    }
    return null;
  }

  Future<void> _pickImage() async {
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file != null && mounted) {
      setState(() => _imageFile = file);
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startAt == null || _endAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end date/time')),
      );
      return;
    }
    if (_endAt!.isBefore(_startAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }
    if (_ticketTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one ticket type')),
      );
      return;
    }

    for (final row in _ticketTypes) {
      if (row.nameController.text.trim().isEmpty ||
          row.priceController.text.trim().isEmpty ||
          row.quantityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill in all ticket type fields')),
        );
        return;
      }
    }

    final ctx = context;
    LoaderHelper.show(ctx, message: 'Creating event...');

    String? imageUrl = _imageUrl;
    if (_imageFile != null) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
        imageUrl = await di.sl<StorageService>().uploadImage(
          SupabaseBuckets.events,
          userId,
          _imageFile!,
        );
      } catch (e) {
        if (!ctx.mounted) return;
        await LoaderHelper.hide(ctx);
        if (ctx.mounted) {
          ErrorDisplayHelper.show(ctx, error: e, title: 'Image upload failed');
        }
        return;
      }
    }

    final data = CreateEventData(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      venueName: _venueNameController.text.trim(),
      venueAddress: _venueAddressController.text.trim(),
      startAt: _startAt!,
      endAt: _endAt!,
      imageUrl: imageUrl,
      category: _category,
      businessId: _getSelectedBusinessId(),
      ticketTypes: _ticketTypes
          .map((r) => CreateEventTicketType(
                name: r.nameController.text.trim(),
                price: double.tryParse(r.priceController.text.trim()) ?? 0,
                quantityAvailable: int.tryParse(r.quantityController.text.trim()) ?? 0,
              ))
          .toList(),
    );

    if (!ctx.mounted) return;
    ctx.read<CreateEventCubit>().createEvent(data);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateEventCubit, CreateEventState>(
        listener: (context, state) {
          if (state is CreateEventSuccess) {
            LoaderHelper.hide(context).then((_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event created successfully!')),
              );
              Navigator.pop(context, true);
            });
          } else if (state is CreateEventError) {
            LoaderHelper.hide(context).then((_) {
              if (context.mounted) {
                ErrorDisplayHelper.show(context, message: state.message, title: 'Could not create event');
              }
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.backgroundWhite,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Create Event',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Event Details'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    'Event Title',
                    controller: _titleController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Description',
                    controller: _descriptionController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Venue Name',
                    controller: _venueNameController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Venue Address',
                    controller: _venueAddressController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Date & Time'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          'Start',
                          _startAt,
                          (d) => setState(() => _startAt = d),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          'End',
                          _endAt,
                          (d) => setState(() => _endAt = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Category'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EventCategory.values
                        .where((c) => c != EventCategory.all)
                        .map((c) {
                      final selected = _category == c;
                      return FilterChip(
                        label: Text(c.displayName),
                        selected: selected,
                        onSelected: (_) => setState(() => _category = c),
                        selectedColor: AppColors.brandPrimary.withValues(alpha: 0.3),
                      );
                    })
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Event Image'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                        border: Border.all(color: AppColors.backgroundGrey),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppResources.radiusM),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: AppColors.brandPrimary),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add image',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('Ticket Types'),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _ticketTypes.add(_TicketTypeRow());
                          });
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._ticketTypes.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TicketTypeCard(
                        row: e.value,
                        onRemove: () => setState(() => _ticketTypes.removeAt(e.key)),
                      ),
                    );
                  }),
                  if (_ticketTypes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                        border: Border.all(color: AppColors.backgroundGrey),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.confirmation_number_outlined, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'No ticket types. Tap "Add" to add one.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Create Event',
                    onPressed: _createEvent,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
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
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(color: AppColors.backgroundGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(color: AppColors.backgroundGrey),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? value, ValueChanged<DateTime> onSelect) {
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
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final ctx = context;
            final picked = await showDatePicker(
              context: ctx,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              if (!ctx.mounted) return;
              final time = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
              );
              if (time != null) {
                onSelect(DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              border: Border.all(color: AppColors.backgroundGrey),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? DateFormat('MMM d, y • HH:mm').format(value)
                      : 'Select',
                  style: TextStyle(
                    color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TicketTypeRow {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
}

class _TicketTypeCard extends StatelessWidget {
  const _TicketTypeCard({
    required this.row,
    required this.onRemove,
  });

  final _TicketTypeRow row;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: row.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: row.priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price \$',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: row.quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
