import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/business_address_data.dart';
import '../resources/app_resources.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../../injection/injection_container.dart' as di;

String _formatAddressLine(BusinessAddressData d) {
  if (d.formattedAddress != null && d.formattedAddress!.isNotEmpty) {
    return d.formattedAddress!;
  }
  final parts = <String>[
    if (d.street != null && d.street!.isNotEmpty) d.street!,
    if (d.city != null && d.city!.isNotEmpty) d.city!,
    if (d.state != null && d.state!.isNotEmpty) d.state!,
    if (d.zipCode != null && d.zipCode!.isNotEmpty) d.zipCode!,
  ];
  return parts.isEmpty ? 'Selected location' : parts.join(', ');
}

/// Street line with debounced address suggestions (no separate search control).
class StreetAddressField extends StatefulWidget {
  const StreetAddressField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.decoration,
    required this.onAddressPicked,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hintText;
  final InputDecoration decoration;
  final void Function(BusinessAddressData data) onAddressPicked;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  State<StreetAddressField> createState() => _StreetAddressFieldState();
}

class _StreetAddressFieldState extends State<StreetAddressField> {
  Timer? _debounce;
  bool _loading = false;
  List<BusinessAddressData> _suggestions = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _runLookup(widget.controller.text);
    });
  }

  void _applyPick(BusinessAddressData data) {
    _debounce?.cancel();
    setState(() {
      _suggestions = [];
      _loading = false;
    });
    widget.onAddressPicked(data);
  }

  Future<void> _runLookup(String raw) async {
    final q = raw.trim();
    if (q.length < 8) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _suggestions = [];
      });
      return;
    }
    if (!mounted) return;
    setState(() => _loading = true);
    final result = await di.sl<LocationService>().lookupAddressSuggestions(q);
    if (!mounted) return;
    result.fold(
      (_) {
        setState(() {
          _loading = false;
          _suggestions = [];
        });
      },
      (list) {
        setState(() {
          _loading = false;
          _suggestions = list;
        });
      },
    );
  }

  InputDecoration _mergedDecoration() {
    return widget.decoration.copyWith(
      hintText: widget.hintText.isEmpty ? null : widget.hintText,
      suffixIcon: _loading
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.validator != null)
          TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            decoration: _mergedDecoration(),
          )
        else
          TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            decoration: _mergedDecoration(),
          ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(AppResources.radiusM),
            shadowColor: Colors.black.withValues(alpha: 0.12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.backgroundGrey.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, i) {
                  final d = _suggestions[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.brandPrimary.withValues(alpha: 0.9),
                      size: 22,
                    ),
                    title: Text(
                      _formatAddressLine(d),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => _applyPick(d),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
