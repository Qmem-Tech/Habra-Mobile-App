import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/event_filters.dart';
import '../../domain/entities/event_category.dart';

class EventFiltersPage extends StatefulWidget {
  final EventFilters? initialFilters;

  const EventFiltersPage({super.key, this.initialFilters});

  @override
  State<EventFiltersPage> createState() => _EventFiltersPageState();
}

class _EventFiltersPageState extends State<EventFiltersPage> {
  late EventFilters _filters;
  DateTime? _selectedDate;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? const EventFilters();
    _selectedDate = _filters.startDate;
    _minPriceController.text = _filters.minPrice?.toStringAsFixed(0) ?? '';
    _maxPriceController.text = _filters.maxPrice?.toStringAsFixed(0) ?? '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filters = const EventFilters();
                _selectedDate = null;
                _minPriceController.clear();
                _maxPriceController.clear();
              });
            },
            child: Text(
              'Reset',
              style: TextStyle(color: AppColors.brandSecondary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventTypeSection(),
            const SizedBox(height: 24),
            _buildDateRangeSection(),
            const SizedBox(height: 24),
            _buildPriceRangeSection(),
            const SizedBox(height: 32),
            AppButton(
              text: 'Show ${_getEventCount()} Events',
              onPressed: () {
                Navigator.pop(context, _filters);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeSection() {
    final eventTypes = [
      EventCategory.cultural,
      EventCategory.music,
      EventCategory.nightlife,
      EventCategory.food,
      EventCategory.networking,
      EventCategory.community,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: eventTypes.map((type) {
            final isSelected = _filters.eventTypes.contains(type);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _filters = _filters.copyWith(
                      eventTypes: _filters.eventTypes.where((t) => t != type).toList(),
                    );
                  } else {
                    _filters = _filters.copyWith(
                      eventTypes: [..._filters.eventTypes, type],
                    );
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
                  ),
                ),
                child: Text(
                  type.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Date Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _filters = _filters.copyWith(startDate: date);
                  });
                }
              },
              icon: Icon(Icons.calendar_today, size: 16, color: AppColors.brandSecondary),
              label: Text(
                'Choose Dates',
                style: TextStyle(color: AppColors.brandSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDateOption('Today', DateTime.now()),
        const SizedBox(height: 8),
        _buildDateOption('Tomorrow', DateTime.now().add(const Duration(days: 1))),
        const SizedBox(height: 8),
        _buildDateOption('This Weekend', _getThisWeekend()),
      ],
    );
  }

  Widget _buildDateOption(String label, DateTime date) {
    final isSelected = _selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _filters = _filters.copyWith(startDate: date);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.brandPrimary, size: 24)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.backgroundGrey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Range',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final price = double.tryParse(value);
                  _filters = _filters.copyWith(minPrice: price);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final price = double.tryParse(value);
                  _filters = _filters.copyWith(maxPrice: price);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  DateTime _getThisWeekend() {
    final now = DateTime.now();
    final daysUntilSaturday = 6 - now.weekday;
    return now.add(Duration(days: daysUntilSaturday));
  }

  int _getEventCount() {
    // Mock count - in real app, this would be calculated
    return 24;
  }
}
