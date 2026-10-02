import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../models/department_model.dart';
import '../../../models/user_model.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/inputs/app_dropdown.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../providers/auth_provider.dart';
import 'password_strength_card.dart';

/// Account registration form shared by Student Activation, Lecturer
/// Registration and Admin Registration: full name, institutional ID, email,
/// optional phone, (admin code), password + confirmation, strength meter,
/// optional acknowledgement and submit.
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
    this.loginRoute = RouteNames.login,
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

  /// Where "Back to Login" goes when there is nothing to pop.
  final String loginRoute;

  @override
  State<AccountSetupForm> createState() => _AccountSetupFormState();
}

class _AccountSetupFormState extends State<AccountSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _id = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _adminCode = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _acknowledged = false;
  bool _showAckError = false;

  /// Departments for the dropdown (students & lecturers); null while loading.
  List<DepartmentModel>? _departments;
  bool _departmentsFailed = false;
  DepartmentModel? _department;

  bool get _isAdmin => widget.role == UserRole.admin;

  /// Students need a department: it decides which courses they take.
  bool get _departmentRequired =>
      widget.role == UserRole.student && (_departments?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    for (final c in [_email, _password, _confirm]) {
      c.addListener(() => setState(() {}));
    }
    if (!_isAdmin) _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _departmentsFailed = false);
    try {
      final list = await context
          .read<AuthRepository>()
          .getRegistrationDepartments();
      if (mounted) setState(() => _departments = list);
    } on Object catch (e) {
      ErrorHandler.log(e);
      if (mounted) {
        setState(() {
          _departments = const [];
          _departmentsFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _id,
      _email,
      _phone,
      _adminCode,
      _password,
      _confirm,
    ]) {
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
    final ok = await auth.register(
      role: widget.role,
      fullName: _name.text,
      email: _email.text,
      phone: _phone.text,
      identifier: _id.text,
      password: _password.text,
      departmentId: _department?.id,
      adminCode: _isAdmin ? _adminCode.text : null,
    );
    if (ok && auth.role != null) {
      navigator.pushNamedAndRemoveUntil(
        AppRouter.homeFor(auth.role!),
        (_) => false,
      );
    }
  }

  Widget _departmentField(ThemeData theme) {
    final departments = _departments;
    if (departments == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceSm),
        child: LinearProgressIndicator(),
      );
    }
    if (_departmentsFailed) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Could not load departments. You can still register; an '
              'administrator can set your department later.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(onPressed: _loadDepartments, child: const Text('Retry')),
        ],
      );
    }
    if (departments.isEmpty) {
      return Text(
        'No departments exist yet. An administrator can set your '
        'department later.',
        style: theme.textTheme.bodySmall,
      );
    }
    return KeyedSubtree(
      key: const Key('setup_department'),
      child: AppDropdown<DepartmentModel>(
        label: widget.role == UserRole.student
            ? 'Department'
            : 'Department (optional)',
        isRequired: _departmentRequired,
        hint: 'Select your department',
        prefixIcon: Icons.apartment_outlined,
        value: _department,
        items: departments,
        itemLabel: (d) =>
            d.facultyName == null ? d.name : '${d.name} • ${d.facultyName}',
        onChanged: (d) => setState(() => _department = d),
        validator: (d) => _departmentRequired && d == null
            ? 'Select your department to see its courses'
            : null,
      ),
    );
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
            fieldKey: const Key('setup_name'),
            controller: _name,
            label: 'Full Name',
            isRequired: true,
            hint: 'Your full name',
            prefixIcon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (v) => Validators.required(v, field: 'Full name'),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    child: Text(
                      widget.idSuffixLabel!,
                      style: theme.textTheme.labelMedium,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: AppColors.onSecondaryFixedVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            domain,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.onSecondaryFixedVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            validator: Validators.email,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            fieldKey: const Key('setup_phone'),
            controller: _phone,
            label: 'Phone Number (optional)',
            hint: 'e.g. +237 6XX XXX XXX',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: (v) => Validators.phone(v, isRequired: false),
          ),
          if (!_isAdmin) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            _departmentField(theme),
          ],
          if (_isAdmin) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              fieldKey: const Key('setup_admin_code'),
              controller: _adminCode,
              label: 'Admin Registration Code',
              hint: 'Code from your institution',
              prefixIcon: Icons.key_outlined,
              obscure: true,
              textInputAction: TextInputAction.next,
              helper:
                  'Required unless this is the very first administrator, or '
                  'an administrator already added you with this email.',
            ),
          ],
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
                    child: Icon(
                      Icons.check_circle_outline,
                      color: theme.colorScheme.secondary,
                    ),
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
                      child: Text(
                        widget.acknowledgement!,
                        style: theme.textTheme.bodyMedium,
                      ),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
          if (auth.errorMessage != null) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            Text(
              auth.errorMessage!,
              key: const Key('setup_error'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
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
              Text(
                'Already have an account? ',
                style: theme.textTheme.bodyLarge,
              ),
              TextButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  } else {
                    navigator.pushReplacementNamed(
                      widget.loginRoute,
                      arguments: _isAdmin ? null : widget.role,
                    );
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
