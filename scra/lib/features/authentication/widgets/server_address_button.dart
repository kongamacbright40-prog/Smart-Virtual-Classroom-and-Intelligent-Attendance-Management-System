import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../services/server_settings.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/inputs/app_text_field.dart';

/// "Server: 10.0.0.5:8000 · Change" link on the sign-in screens. Lets testers
/// point the app at the PC running the backend when its Wi-Fi address
/// changes, without a new app build.
class ServerAddressButton extends StatefulWidget {
  const ServerAddressButton({super.key});

  @override
  State<ServerAddressButton> createState() => _ServerAddressButtonState();
}

class _ServerAddressButtonState extends State<ServerAddressButton> {
  String get _label =>
      AppConfig.apiBaseUrl.replaceFirst(RegExp(r'^https?://'), '');

  Future<void> _change() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => Provider<StorageService>.value(
        value: context.read<StorageService>(),
        child: const _ServerDialog(),
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: TextButton.icon(
        key: const Key('server_address'),
        onPressed: _change,
        icon: const Icon(Icons.dns_outlined, size: 18),
        label: Text(
          'Server: $_label · Change',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ServerDialog extends StatefulWidget {
  const _ServerDialog();

  @override
  State<_ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<_ServerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _address = TextEditingController(
    text: AppConfig.apiBaseUrl.replaceFirst(RegExp(r'^http://'), ''),
  );
  bool _checking = false;
  String? _problem;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _save({bool force = false}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final url = ServerSettings.normalize(_address.text)!;
    final storage = context.read<StorageService>();
    final navigator = Navigator.of(context);
    setState(() {
      _checking = true;
      _problem = null;
    });
    final ok = force || await ServerSettings.isReachable(url);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _checking = false;
        _problem =
            'No Smart Class server answered at $url. Check that the PC is on '
            'the same Wi-Fi and Smart Class is running, then try again.';
      });
      return;
    }
    await ServerSettings.apply(storage, url);
    navigator.pop(true);
  }

  Future<void> _reset() async {
    final storage = context.read<StorageService>();
    final navigator = Navigator.of(context);
    await ServerSettings.apply(storage, null);
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Server address'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'The address of the PC running Smart Class, as shown in its '
                'window, e.g. 10.194.53.114:8000.',
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppTextField(
                fieldKey: const Key('server_address_field'),
                controller: _address,
                label: 'Address',
                hint: '10.194.53.114:8000',
                prefixIcon: Icons.dns_outlined,
                keyboardType: TextInputType.url,
                validator: (v) => ServerSettings.normalize(v) == null
                    ? 'Enter an address like 10.194.53.114:8000'
                    : null,
                onSubmitted: (_) => _save(),
              ),
              if (_problem != null) ...[
                const SizedBox(height: AppDimensions.spaceSm),
                Text(
                  _problem!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (AppConfig.hasServerOverride) ...[
                const SizedBox(height: AppDimensions.spaceSm),
                Text(
                  'Built-in address: ${AppConfig.builtInApiBaseUrl}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (AppConfig.hasServerOverride)
          TextButton(
            onPressed: _checking ? null : _reset,
            child: const Text('Use built-in'),
          ),
        if (_problem != null)
          TextButton(
            onPressed: _checking ? null : () => _save(force: true),
            child: const Text('Save anyway'),
          ),
        FilledButton(
          key: const Key('server_address_save'),
          onPressed: _checking ? null : _save,
          child: _checking
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Check & Save'),
        ),
      ],
    );
  }
}
