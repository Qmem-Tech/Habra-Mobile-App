import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/business_address_data.dart';
import '../resources/app_resources.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../../injection/injection_container.dart' as di;

String _formatAddressLine(BusinessAddressData d) {
  final parts = <String>[
    if (d.street != null && d.street!.isNotEmpty) d.street!,
    if (d.city != null && d.city!.isNotEmpty) d.city!,
    if (d.state != null && d.state!.isNotEmpty) d.state!,
    if (d.zipCode != null && d.zipCode!.isNotEmpty) d.zipCode!,
  ];
  return parts.isEmpty ? 'Selected location' : parts.join(', ');
}

/// Full-screen style bottom sheet: search as you type, pick a structured address.
class AddressLookupSheet extends StatefulWidget {
  const AddressLookupSheet({super.key, this.initialQuery = ''});

  final String initialQuery;

  static Future<BusinessAddressData?> show(
    BuildContext context, {
    String initialQuery = '',
  }) {
    return showModalBottomSheet<BusinessAddressData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppResources.radiusXL),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: AddressLookupSheet(initialQuery: initialQuery),
      ),
    );
  }

  @override
  State<AddressLookupSheet> createState() => _AddressLookupSheetState();
}

class _AddressLookupSheetState extends State<AddressLookupSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<BusinessAddressData> _results = [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    _controller.addListener(_onTextChanged);
    if (widget.initialQuery.trim().length >= 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduleLookup(_controller.text);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    _scheduleLookup(_controller.text);
  }

  void _scheduleLookup(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _runLookup(raw));
  }

  Future<void> _runLookup(String raw) async {
    final q = raw.trim();
    if (q.length < 4) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _results = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await di.sl<LocationService>().lookupAddressSuggestions(q);
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() {
          _loading = false;
          _error = f.message;
          _results = [];
        });
      },
      (list) {
        setState(() {
          _loading = false;
          _error = null;
          _results = list;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.88;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Search address',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppResources.spacingM,
              4,
              AppResources.spacingM,
              12,
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Start typing street, city, or ZIP…',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _results = [];
                            _error = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _runLookup(_controller.text),
            ),
          ),
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: AppColors.backgroundGrey,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
            )
          else
            const SizedBox(height: 2),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final q = _controller.text.trim();
    if (q.length < 4) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingL),
          child: Text(
            'Enter at least 4 characters to search. Results use your device geocoder.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingL),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 14),
          ),
        ),
      );
    }
    if (_results.isEmpty && !_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingL),
          child: Text(
            'No matches for “$q”. Try a fuller street address or city.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final d = _results[i];
        final line = _formatAddressLine(d);
        return Material(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppResources.radiusM),
          child: InkWell(
            onTap: () => Navigator.pop(context, d),
            borderRadius: BorderRadius.circular(AppResources.radiusM),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppResources.radiusM),
                border: Border.all(
                  color: AppColors.textTertiary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
