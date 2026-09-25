import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Rounded search input with clear button and optional filter action.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.hint = 'Search',
    required this.onChanged,
    this.onFilter,
    this.controller,
    this.autofocus = false,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilter;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppDimensions.radiusFull);
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: (v) {
        setState(() {});
        widget.onChanged(v);
      },
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder:
            OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_controller.text.isNotEmpty)
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                  widget.onChanged('');
                },
              ),
            if (widget.onFilter != null)
              IconButton(
                tooltip: 'Filters',
                icon: const Icon(Icons.tune),
                onPressed: widget.onFilter,
              ),
          ],
        ),
      ),
    );
  }
}
