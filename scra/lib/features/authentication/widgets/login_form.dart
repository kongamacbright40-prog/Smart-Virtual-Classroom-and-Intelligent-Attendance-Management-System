import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../providers/auth_provider.dart';

typedef LoginSubmit = Future<void> Function(
  String identifier,
  String password,
  bool rememberMe,
);

/// Credentials form shared by the Login and Admin Login screens.
///
/// Validation is centralized in [Validators]; submission state and server
/// errors come from [AuthProvider].
class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.onSubmit,
    this.identifierLabel = 'Institutional ID / Email',
    this.identifierHint = 'Institutional ID or email',
    this.identifierValidator = Validators.identifier,
    this.identifierBadge,
    this.identifierSuffix,
    this.passwordLabel = 'Password',
    this.passwordBadge,
    this.rememberLabel = 'Remember me',
    this.submitLabel = AppStrings.signIn,
    this.submitIcon,
    this.linkLabel = 'Forgot Password?',
    this.linkIcon,
    this.onLink,
    this.fieldFill,
    this.showRequired = false,
  });

  final LoginSubmit onSubmit;
  final String identifierLabel;
  final String identifierHint;
  final String? Function(String?) identifierValidator;
  final Widget? identifierBadge;
  final Widget? identifierSuffix;
  final String passwordLabel;
  final Widget? passwordBadge;
  final String rememberLabel;
  final String submitLabel;
  final IconData? submitIcon;
  final String linkLabel;
  final IconData? linkIcon;
  final VoidCallback? onLink;
  final Color? fieldFill;
  final bool showRequired;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  late bool _remember = context.read<AuthProvider>().rememberMe;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.onSubmit(_identifier.text, _password.text, _remember);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              fieldKey: const Key('login_identifier'),
              controller: _identifier,
              label: widget.identifierLabel,
              labelBadge: widget.identifierBadge,
              isRequired: widget.showRequired,
              hint: widget.identifierHint,
              prefixIcon: Icons.badge_outlined,
              suffix: widget.identifierSuffix,
              fillColor: widget.fieldFill,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: widget.identifierValidator,
              onChanged: (_) => auth.clearError(),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              fieldKey: const Key('login_password'),
              controller: _password,
              label: widget.passwordLabel,
              labelBadge: widget.passwordBadge,
              isRequired: widget.showRequired,
              hint: 'Enter your password',
              prefixIcon: Icons.lock_outline,
              obscure: true,
              fillColor: widget.fieldFill,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: Validators.password,
              onChanged: (_) => auth.clearError(),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Row(
              children: [
                SizedBox.square(
                  dimension: 40,
                  child: Checkbox(
                    key: const Key('login_remember'),
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v ?? false),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _remember = !_remember),
                    child: Text(
                      widget.rememberLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                if (widget.onLink != null)
                  Flexible(
                    child: TextButton.icon(
                      onPressed: widget.onLink,
                      icon: widget.linkIcon == null
                          ? const SizedBox.shrink()
                          : Icon(widget.linkIcon, size: 18),
                      label: Text(
                        widget.linkLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: AppDimensions.spaceSm),
              Container(
                key: const Key('login_error'),
                padding: const EdgeInsets.all(AppDimensions.spaceSm + 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Expanded(
                      child: Text(
                        auth.errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.spaceMd),
            PrimaryButton(
              key: const Key('login_submit'),
              label: widget.submitLabel,
              icon: widget.submitIcon,
              trailingIcon: Icons.arrow_forward,
              isLoading: auth.isBusy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
