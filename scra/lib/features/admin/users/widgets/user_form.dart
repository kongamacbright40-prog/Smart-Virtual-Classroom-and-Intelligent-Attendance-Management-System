import 'package:flutter/material.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/validators.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/widgets/buttons/primary_button.dart';
import 'package:smart_class/widgets/inputs/app_dropdown.dart';
import 'package:smart_class/widgets/inputs/app_text_field.dart';

class UserForm extends StatefulWidget {
  const UserForm({
    super.key,
    this.initialUser,
    required this.departments,
    required this.onSubmit,
    this.submitLabel = 'Save User',
  });

  final UserModel? initialUser;
  final List<DepartmentModel> departments;

  /// [password] is the optional initial password (create mode only).
  final Future<void> Function(UserModel user, String? password) onSubmit;
  final String submitLabel;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.initialUser?.fullName ?? '',
  );
  late final _email = TextEditingController(
    text: widget.initialUser?.email ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.initialUser?.phone ?? '',
  );
  final _password = TextEditingController();
  late UserRole _role = widget.initialUser?.role ?? UserRole.student;
  late String? _departmentId =
      widget.initialUser?.departmentId ??
      (widget.departments.isEmpty ? null : widget.departments.first.id);
  bool _saving = false;

  bool get _isCreate => widget.initialUser == null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final dept = widget.departments
        .where((d) => d.id == _departmentId)
        .firstOrNull;
    final base = widget.initialUser;
    final user = UserModel(
      id: base?.id ?? '',
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      role: base?.role ?? _role,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      departmentId: dept?.id,
      departmentName: dept?.name,
      isActive: base?.isActive ?? true,
      createdAt: base?.createdAt,
      lastActiveAt: base?.lastActiveAt,
    );
    final password = _isCreate && _password.text.isNotEmpty
        ? _password.text
        : null;
    try {
      await widget.onSubmit(user, password);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            fieldKey: const Key('user_full_name'),
            controller: _name,
            label: 'Full name',
            isRequired: true,
            prefixIcon: Icons.person_outline,
            validator: (v) => Validators.required(v, field: 'Full name'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            fieldKey: const Key('user_email'),
            controller: _email,
            label: 'Email',
            isRequired: true,
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            fieldKey: const Key('user_phone'),
            controller: _phone,
            label: 'Phone',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => Validators.phone(v, isRequired: false),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppDropdown<UserRole>(
            label: 'Role',
            value: _role,
            enabled: widget.initialUser == null,
            items: UserRole.values,
            onChanged: (v) => setState(() => _role = v ?? _role),
            itemLabel: (r) => r.label,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppDropdown<DepartmentModel>(
            label: 'Department',
            value: widget.departments
                .where((d) => d.id == _departmentId)
                .firstOrNull,
            items: widget.departments,
            onChanged: (d) => setState(() => _departmentId = d?.id),
            itemLabel: (d) => d.name,
            validator: (d) => d == null ? 'Department is required' : null,
          ),
          if (_isCreate) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              fieldKey: const Key('user_password'),
              controller: _password,
              label: 'Initial password',
              prefixIcon: Icons.lock_outline,
              obscure: true,
              helper: _role == UserRole.admin
                  ? 'Recommended for admins: they can sign in right away. '
                        'If left empty, they set one via "Forgot password".'
                  : 'Optional. If left empty, they activate the account '
                        'and choose their own password in the app.',
              validator: (v) =>
                  (v == null || v.isEmpty) ? null : Validators.newPassword(v),
            ),
          ],
          const SizedBox(height: AppDimensions.spaceLg),
          PrimaryButton(
            key: const Key('save_user'),
            label: widget.submitLabel,
            icon: Icons.save_outlined,
            isLoading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
