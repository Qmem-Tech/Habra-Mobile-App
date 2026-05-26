import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';

/// Result of editing hours during business registration.
///
/// **API:** Registration uses a single `opening_time` / `closing_time` pair (HH:mm).
/// Owners can set per-day hours later under Dashboard → Update Hours (`weekly_hours` JSON).
/// Per-day closed flags are UI-only; the API does not store a weekly schedule.
/// All non-closed days are assumed to use [openingTime] and [closingTime].
class RegistrationHoursResult {
  const RegistrationHoursResult({
    required this.openingTime,
    required this.closingTime,
    required this.dayClosed,
  });

  /// ISO weekday order: index 0 = Monday … 6 = Sunday.
  final List<bool> dayClosed;
  final String openingTime;
  final String closingTime;

  static const List<String> weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static RegistrationHoursResult defaultSchedule() {
    return RegistrationHoursResult(
      openingTime: '09:00',
      closingTime: '17:00',
      dayClosed: [false, false, false, false, false, true, true],
    );
  }

  String summaryLine(int index) {
    if (index < 0 || index >= 7) return '';
    if (dayClosed[index]) {
      return '${weekdayNames[index]}: Closed';
    }
    return '${weekdayNames[index]}: ${formatTimeHm(openingTime)} – ${formatTimeHm(closingTime)}';
  }

  /// Hours label for an open day (e.g. `9:00 AM – 5:00 PM`).
  String get openDaysHoursLabel =>
      '${formatTimeHm(openingTime)} – ${formatTimeHm(closingTime)}';

  String hoursLabelForDay(int index) {
    if (index < 0 || index >= 7) return '';
    return dayClosed[index] ? 'Closed' : openDaysHoursLabel;
  }

  static String formatTimeHm(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return hhmm;
    var h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final am = h < 12;
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} ${am ? 'AM' : 'PM'}';
  }
}

/// Bottom sheet to edit registration hours (weekly closed days + shared open/close).
Future<RegistrationHoursResult?> showBusinessRegistrationHoursSheet(
  BuildContext context, {
  RegistrationHoursResult? initial,
}) {
  return showModalBottomSheet<RegistrationHoursResult>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.backgroundWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.92;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: _RegistrationHoursSheetBody(initial: initial),
      );
    },
  );
}

class _RegistrationHoursSheetBody extends StatefulWidget {
  const _RegistrationHoursSheetBody({this.initial});

  final RegistrationHoursResult? initial;

  @override
  State<_RegistrationHoursSheetBody> createState() =>
      _RegistrationHoursSheetBodyState();
}

class _RegistrationHoursSheetBodyState extends State<_RegistrationHoursSheetBody> {
  late List<bool> _dayClosed;
  late String _open;
  late String _close;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? RegistrationHoursResult.defaultSchedule();
    _dayClosed = List<bool>.from(i.dayClosed);
    _open = i.openingTime;
    _close = i.closingTime;
  }

  Future<void> _pickTime({required bool isOpen}) async {
    final cur = isOpen ? _open : _close;
    final parts = cur.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final rootNav = Navigator.of(context, rootNavigator: true);
    final picked = await showTimePicker(
      context: rootNav.context,
      initialTime: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        final s =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isOpen) {
          _open = s;
        } else {
          _close = s;
        }
      });
    }
  }

  void _save() {
    if (!_dayClosed.contains(false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one open day, or adjust closed days.'),
        ),
      );
      return;
    }
    final openM = _toMinutes(_open);
    final closeM = _toMinutes(_close);
    if (openM >= closeM) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Closing time must be after opening time.'),
        ),
      );
      return;
    }
    Navigator.of(context, rootNavigator: true).pop(
      RegistrationHoursResult(
        openingTime: _open,
        closingTime: _close,
        dayClosed: List<bool>.from(_dayClosed),
      ),
    );
  }

  int _toMinutes(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0;
    return h * 60 + m;
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppResources.spacingL,
        right: AppResources.spacingL,
        top: AppResources.spacingM,
        bottom: pad.bottom + AppResources.spacingL + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Business hours',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved as one opening and closing time for your listing. Mark days as closed when you are not open.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Opens',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: () => _pickTime(isOpen: true),
                      child: Text(RegistrationHoursResult.formatTimeHm(_open)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Closes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: () => _pickTime(isOpen: false),
                      child: Text(RegistrationHoursResult.formatTimeHm(_close)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Days',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            itemBuilder: (context, index) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(RegistrationHoursResult.weekdayNames[index]),
                subtitle: Text(
                  _dayClosed[index]
                      ? 'Closed'
                      : '${RegistrationHoursResult.formatTimeHm(_open)} – ${RegistrationHoursResult.formatTimeHm(_close)}',
                ),
                value: !_dayClosed[index],
                onChanged: (v) => setState(() => _dayClosed[index] = !v),
              );
            },
          ),
          const SizedBox(height: 12),
          AppButton(text: 'Save hours', onPressed: _save),
        ],
      ),
    );
  }
}

