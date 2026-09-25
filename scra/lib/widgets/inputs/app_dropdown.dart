import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Labelled dropdown styled like [AppTextField].
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.itemLabel,
    this.label,
    this.hint,
    this.prefixIcon,
    this.isRequired = false,
    this.validator,
    this.enabled = true,
  });

  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String Function(T item) itemLabel;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final bool isRequired;
  final String? Function(T?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              text: label,
              style: theme.textTheme.titleSmall,
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: enabled ? onChanged : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          icon: const Icon(Icons.expand_more),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          ),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
