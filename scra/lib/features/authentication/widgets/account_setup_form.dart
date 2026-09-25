import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../providers/auth_provider.dart';
import 'password_strength_card.dart';

/// Credential setup form shared by Student Activation (07) and Lecturer
/// Registration (08): institutional ID, email, password + confirmation,
/// strength meter, optional acknowledgement and submit.
class AccountSetupForm extends StatefulWidget {
  const AccountSetupForm({
    super.key,
    required this.role,
    required this.idLabel,
    required this.idHint,
    required this.idHelper,
    required this.idValidator,
    required this.emailHint,
    required this.submitLabel,
    this.idBadge,
    this.idSuffixLabel,
    this.acknowledgement,
    this.strengthNote,
  });

  final UserRole role;
  final String idLabel;
  final String idHint;
  final String idHelper;
  final String? Function(String?) idValidator;
  final String emailHint;
  final String submitLabel;
  final Widget? idBadge;
  final String? idSuffixLabel;
  final String? acknowledgement;
  final String? strengthNote;

  @override
  State<AccountSetupForm> createState() => _AccountSetupFormState();
}

class _AccountSetupFormState extends State<AccountSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _acknowledged = false;
  bool _showAckError = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_email, _password, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_id, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    final needsAck = widget.acknowledgement != null;
    setState(() => _showAckError = needsAck && !_acknowledged);
    if (!valid || (needsAck && !_acknowledged)) return;

    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final ok = widget.role == UserRole.student
        ? await auth.activateStudent(
            matricule: _id.text,
            email: _email.text,
            password: _password.text,
          )
        : await auth.registerLecturer(
            staffId: _id.text,
            email: _email.text,
            password: _password.text,
          );
    if (ok && auth.role != null) {
      navigator.pushNamedAndRemoveUntil(
          AppRouter.homeFor(auth.role!), (_) => false);
    }
  }

  String? get _emailDomain {
    final v = _email.text.trim();
    if (Validators.email(v) != null) return null;
    return '@${v.split('@').last}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final domain = _emailDomain;
    final matches = _confirm.text.isNotEmpty && _confirm.text == _password.text;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            fieldKey: const Key('setup_id'),
            controller: _id,
            label: widget.idLabel,
            labelBadge: widget.idBadge,
            isRequired: true,
            hint: widget.idHint,
            prefixIcon: Icons.badge_outlined,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            suffix: widget.idSuffixLabel == null
                ? null
                : Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(widget.idSuffixLabel!,
                        style: theme.textTheme.labelMedium),
                  ),
            helper: widget.idHelper,
            validator: widget.idValidator,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            fieldKey: const Key('setup_email'),
            controller: _email,
            label: 'Institutional Email',
            isRequired: true,
            hint: widget.emailHint,
            prefixIcon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            suffix: domain == null
                ? null
                : Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 14, color: AppColors.onSecondaryFixedVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            domain,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.onSecondaryFixedVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
            validator: Validators.email,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            fieldKey: const Key('setup_password'),
            controller: _password,
            label: 'Create Password',
            isRequired: true,
            hint: 'Create a strong password',
            prefixIcon: Icons.lock_outline,
            obscure: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: Validators.newPassword,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            fieldKey: const Key('setup_confirm'),
            controller: _confirm,
            label: 'Confirm Password',
            isRequired: true,
            hint: 'Re-enter your password',
            prefixIcon: Icons.verified_user_outlined,
            suffix: matches
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.check_circle_outline,
                        color: theme.colorScheme.secondary),
                  )
                : null,
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.confirmPassword(v, _password.text),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          PasswordStrengthCard(
            password: _password.text,
            extraNote: widget.strengthNote,
          ),
          if (widget.acknowledgement != null) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceSm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: _showAckError
                    ? Border.all(color: theme.colorScheme.error)
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    key: const Key('setup_ack'),
                    value: _acknowledged,
                    onChanged: (v) => setState(() {
                      _acknowledged = v ?? false;
                      if (_acknowledged) _showAckError = false;
                    }),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(widget.acknowledgement!,
                          style: theme.textTheme.bodyMedium),
                    ),
                  ),
                ],
              ),
            ),
            if (_showAckError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  'Please accept the institutional terms to continue.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
          ],
          if (auth.errorMessage != null) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            Text(
              auth.errorMessage!,
              key: const Key('setup_error'),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: AppDimensions.spaceLg),
          PrimaryButton(
            key: const Key('setup_submit'),
            label: widget.submitLabel,
            trailingIcon: Icons.arrow_forward,
            isLoading: auth.isBusy,
            onPressed: _submit,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Already activated? ', style: theme.textTheme.bodyLarge),
              TextButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  } else {
                    navigator.pushReplacementNamed(RouteNames.login,
                        arguments: widget.role);
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 36),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Back to Login'),
                    Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
