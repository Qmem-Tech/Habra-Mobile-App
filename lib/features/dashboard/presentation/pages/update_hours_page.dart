import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/utils/business_time_format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../bloc/dashboard_cubit.dart';

/// Preset times in 30-min intervals (24h format for storage).
final Map<String, String> _presetTimes = () {
  final map = <String, String>{};
  for (int h = 6; h <= 23; h++) {
    for (int m = 0; m < 60; m += 30) {
      final key =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      final amPm = h < 12 ? 'AM' : 'PM';
      map[key] = '$hour12:${m.toString().padLeft(2, '0')} $amPm';
    }
  }
  map['00:00'] = '12:00 AM';
  return map;
}();

/// Monday = 1 … Sunday = 7 ([DateTime.weekday]).
const List<(int, String)> _weekdays = [
  (1, 'Monday'),
  (2, 'Tuesday'),
  (3, 'Wednesday'),
  (4, 'Thursday'),
  (5, 'Friday'),
  (6, 'Saturday'),
  (7, 'Sunday'),
];

class _DaySchedule {
  _DaySchedule({
    required this.closed,
    required this.open,
    required this.close,
  });

  bool closed;
  String open;
  String close;
}

class UpdateHoursPage extends StatefulWidget {
  const UpdateHoursPage({
    super.key,
    required this.businessId,
    this.appBarTitle = 'Update Hours',
  });

  final String businessId;
  final String appBarTitle;

  @override
  State<UpdateHoursPage> createState() => _UpdateHoursPageState();
}

class _UpdateHoursPageState extends State<UpdateHoursPage> {
  final Map<int, _DaySchedule> _schedules = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingHours();
  }

  Future<void> _loadExistingHours() async {
    final hours =
        await context.read<DashboardCubit>().getBusinessHours(widget.businessId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _applyFromServer(hours);
    });
  }

  void _applyFromServer(Map<String, dynamic>? hours) {
    final defOpen = _normalizeToPreset(
      hours?['opening_time']?.toString() ?? '09:00',
    );
    final defClose = _normalizeToPreset(
      hours?['closing_time']?.toString() ?? '17:00',
    );
    final wh = hours?['weekly_hours'];
    Map<String, dynamic>? wm;
    if (wh is Map<String, dynamic>) {
      wm = wh;
    } else if (wh is Map) {
      wm = Map<String, dynamic>.from(wh);
    }

    for (final (day, _) in _weekdays) {
      final key = '$day';
      final raw = wm?[key] ?? wm?[day.toString()];
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        final closed = m['closed'] == true;
        if (closed) {
          _schedules[day] = _DaySchedule(
            closed: true,
            open: defOpen,
            close: defClose,
          );
        } else {
          _schedules[day] = _DaySchedule(
            closed: false,
            open: _normalizeToPreset(
              m['open']?.toString() ?? defOpen,
            ),
            close: _normalizeToPreset(
              m['close']?.toString() ?? defClose,
            ),
          );
        }
      } else {
        _schedules[day] = _DaySchedule(
          closed: false,
          open: defOpen,
          close: defClose,
        );
      }
    }
  }

  String _normalizeToPreset(String value) {
    final parts = value.split(':');
    if (parts.isEmpty) return '09:00';
    final h = int.tryParse(parts[0]) ?? 9;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return '${h.clamp(0, 23).toString().padLeft(2, '0')}:${m.clamp(0, 59).toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _weeklyHoursPayload() {
    final out = <String, dynamic>{};
    for (final (day, _) in _weekdays) {
      final s = _schedules[day]!;
      if (s.closed) {
        out['$day'] = {'closed': true};
      } else {
        out['$day'] = {
          'closed': false,
          'open': s.open,
          'close': s.close,
        };
      }
    }
    return out;
  }

  /// Legacy [opening_time] / [closing_time]: prefer Monday; else first open day.
  (String, String) _legacyOpeningClosing() {
    final mon = _schedules[1];
    if (mon != null && !mon.closed) {
      return (mon.open, mon.close);
    }
    for (final (day, _) in _weekdays) {
      final s = _schedules[day]!;
      if (!s.closed) {
        return (s.open, s.close);
      }
    }
    return ('09:00', '17:00');
  }

  int _timeToMinutes(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0;
    return h * 60 + m;
  }

  String? _validateSchedules() {
    for (final (day, label) in _weekdays) {
      final s = _schedules[day]!;
      if (s.closed) continue;
      final o = _timeToMinutes(s.open);
      final c = _timeToMinutes(s.close);
      if (c <= o) {
        return '$label: closing time must be after opening time.';
      }
    }
    return null;
  }

  void _copyMondayToWeekdays() {
    final mon = _schedules[1];
    if (mon == null) return;
    setState(() {
      for (int d = 2; d <= 5; d++) {
        _schedules[d] = _DaySchedule(
          closed: mon.closed,
          open: mon.open,
          close: mon.close,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tuesday–Friday updated from Monday')),
    );
  }

  Future<void> _pickTime(int day, bool isOpen) async {
    final s = _schedules[day]!;
    final controller = TextEditingController(text: isOpen ? s.open : s.close);
    final parts = (isOpen ? s.open : s.close).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '9') ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    controller.dispose();
    if (picked != null && mounted) {
      setState(() {
        final t =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isOpen) {
          s.open = t;
        } else {
          s.close = t;
        }
      });
    }
  }

  String _formatTimeLabel(String key) => formatBusinessTimeHmToAmPm(key);

  void _selectPreset(int day, bool isOpen, String key) {
    setState(() {
      final s = _schedules[day]!;
      if (isOpen) {
        s.open = key;
      } else {
        s.close = key;
      }
    });
  }

  Future<void> _save() async {
    final err = _validateSchedules();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final legacy = _legacyOpeningClosing();
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Saving hours...');
    try {
      final success = await ctx.read<DashboardCubit>().updateBusinessHours(
            widget.businessId,
            {
              'opening_time': legacy.$1,
              'closing_time': legacy.$2,
              'weekly_hours': _weeklyHoursPayload(),
            },
          );
      if (!ctx.mounted) return;
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      if (success) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Hours updated')),
        );
        Navigator.pop(ctx, true);
      } else {
        ErrorDisplayHelper.show(
          ctx,
          message: 'We couldn\'t update your hours. Please try again.',
          title: 'Update failed',
        );
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
        title: Text(
          widget.appBarTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppResources.spacingM,
                    AppResources.spacingM,
                    AppResources.spacingM,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hours by day',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mark a day closed or set different open/close times (e.g. shorter Sunday). '
                        'Monday’s times are used as the default listing summary when needed.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _copyMondayToWeekdays,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Monday to Tue–Fri'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppResources.spacingM,
                      vertical: 8,
                    ),
                    itemCount: _weekdays.length,
                    itemBuilder: (context, index) {
                      final (day, label) = _weekdays[index];
                      final s = _schedules[day]!;
                      return _DayHoursCard(
                        dayLabel: label,
                        schedule: s,
                        onClosedChanged: (v) {
                          setState(() => s.closed = v);
                        },
                        onPickOpen: () => _pickTime(day, true),
                        onPickClose: () => _pickTime(day, false),
                        onPresetOpen: (k) => _selectPreset(day, true, k),
                        onPresetClose: (k) => _selectPreset(day, false, k),
                        formatTimeLabel: _formatTimeLabel,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppResources.spacingM),
                  child: AppButton(text: 'Save hours', onPressed: _save),
                ),
              ],
            ),
    );
  }
}

class _DayHoursCard extends StatelessWidget {
  const _DayHoursCard({
    required this.dayLabel,
    required this.schedule,
    required this.onClosedChanged,
    required this.onPickOpen,
    required this.onPickClose,
    required this.onPresetOpen,
    required this.onPresetClose,
    required this.formatTimeLabel,
  });

  final String dayLabel;
  final _DaySchedule schedule;
  final ValueChanged<bool> onClosedChanged;
  final VoidCallback onPickOpen;
  final VoidCallback onPickClose;
  final void Function(String key) onPresetOpen;
  final void Function(String key) onPresetClose;
  final String Function(String key) formatTimeLabel;

  static const _quickPresets = [
    '06:00',
    '08:00',
    '09:00',
    '10:00',
    '12:00',
    '14:00',
    '17:00',
    '18:00',
    '21:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        side: BorderSide(color: AppColors.backgroundGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppResources.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dayLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'Closed',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Switch(
                  value: schedule.closed,
                  onChanged: onClosedChanged,
                  activeThumbColor: AppColors.brandPrimary,
                ),
              ],
            ),
            if (!schedule.closed) ...[
              const SizedBox(height: 12),
              _TimeRow(
                label: 'Opens',
                value: schedule.open,
                display: _presetTimes[schedule.open] ?? formatTimeLabel(schedule.open),
                onTap: onPickOpen,
                presets: _quickPresets,
                selectedKey: schedule.open,
                onPreset: onPresetOpen,
                presetLabel: _presetTimes,
              ),
              const SizedBox(height: 14),
              _TimeRow(
                label: 'Closes',
                value: schedule.close,
                display:
                    _presetTimes[schedule.close] ?? formatTimeLabel(schedule.close),
                onTap: onPickClose,
                presets: _quickPresets,
                selectedKey: schedule.close,
                onPreset: onPresetClose,
                presetLabel: _presetTimes,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.value,
    required this.display,
    required this.onTap,
    required this.presets,
    required this.selectedKey,
    required this.onPreset,
    required this.presetLabel,
  });

  final String label;
  final String value;
  final String display;
  final VoidCallback onTap;
  final List<String> presets;
  final String selectedKey;
  final void Function(String key) onPreset;
  final Map<String, String> presetLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppResources.radiusM),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppResources.radiusM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppResources.radiusM),
                border: Border.all(color: AppColors.backgroundGrey),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 20, color: AppColors.brandPrimary),
                  const SizedBox(width: 10),
                  Text(
                    display,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: presets.map((key) {
            final isSelected = selectedKey == key;
            return GestureDetector(
              onTap: () => onPreset(key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPrimary.withValues(alpha: 0.2)
                      : AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.backgroundGrey,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  presetLabel[key] ?? key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
