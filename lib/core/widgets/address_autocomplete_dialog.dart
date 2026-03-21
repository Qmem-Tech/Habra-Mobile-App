import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'error_display_helper.dart';
import '../../injection/injection_container.dart' as di;

/// Dialog for address search. User types full address and taps Search; geocodes to fill fields.
/// For Google Places Autocomplete, add google_places_autocomplete package and enable Places API.
class AddressAutocompleteDialog extends StatefulWidget {
  const AddressAutocompleteDialog({
    super.key,
    this.initialQuery = '',
  });

  final String initialQuery;

  @override
  State<AddressAutocompleteDialog> createState() => _AddressAutocompleteDialogState();
}

class _AddressAutocompleteDialogState extends State<AddressAutocompleteDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final result = await di.sl<LocationService>().geocodeToAddress(query);
    if (!mounted) return;
    setState(() => _isSearching = false);
    result.fold(
      (f) => ErrorDisplayHelper.show(context, message: f.message, title: 'Address search'),
      (data) => Navigator.pop(context, data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search address'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        enabled: !_isSearching,
        decoration: const InputDecoration(
          hintText: 'e.g. 123 Main St, Washington DC',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
        onSubmitted: (_) => _onSearch(),
      ),
      actions: [
        TextButton(
          onPressed: _isSearching ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSearching ? null : _onSearch,
          child: _isSearching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Search'),
        ),
      ],
    );
  }
}
