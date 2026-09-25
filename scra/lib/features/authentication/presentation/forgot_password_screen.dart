import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/password_strength_card.dart';
import '../widgets/role_header.dart';

enum _RecoveryStep { email, code, password, done }

/// Stitch screen 10 — Reset Password (email → 4-digit code → new password).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _resendAfter = Duration(seconds: 42);

  final _emailForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  _RecoveryStep _step = _RecoveryStep.email;
  Duration _resendIn = Duration.zero;
  Timer? _timer;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
    _confirm.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuthProvider>().clearError(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendIn = _resendAfter);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _resendIn -= const Duration(seconds: 1);
        if (_resendIn <= Duration.zero) {
          _resendIn = Duration.zero;
          t.cancel();
        }
      });
    });
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (!(_emailForm.currentState?.validate() ?? false)) return;
    final ok = await context.read<AuthProvider>().requestPasswordReset(
      _email.text,
    );
    if (!mounted || !ok) return;
    setState(() => _step = _RecoveryStep.code);
    _startCountdown();
  }

  Future<void> _verifyCode() async {
    final error = Validators.recoveryCode(_code.text);
    setState(() => _codeError = error);
    if (error != null) return;
    final ok = await context.read<AuthProvider>().verifyResetCode(
      _email.text,
      _code.text,
    );
    if (!mounted || !ok) return;
    setState(() => _step = _RecoveryStep.password);
  }

  Future<void> _updatePassword() async {
    FocusScope.of(context).unfocus();
    if (!(_passwordForm.currentState?.validate() ?? false)) return;
    final ok = await context.read<AuthProvider>().resetPassword(
      email: _email.text,
      code: _code.text,
      newPassword: _password.text,
    );
    if (!mounted || !ok) return;
    _timer?.cancel();
    setState(() => _step = _RecoveryStep.done);
  }

  void _changeEmail() {
    _timer?.cancel();
    _code.clear();
    setState(() {
      _step = _RecoveryStep.email;
      _resendIn = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: const GatewayAppBar(
        overline: 'Academic Nexus',
        title: 'Smart Class • Account Recovery',
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.pageMargin),
              children: [
                const RoleHeader(
                  icon: Icons.security,
                  badgeIcon: Icons.vpn_key,
                  title: 'Reset Password',
                  description: 'Enter your institutional email to receive a recovery code.',
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceMd),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: _step == _RecoveryStep.done
                      ? _SuccessPanel(
                          onReturn: () => Navigator.of(context).maybePop(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _emailSection(theme),
                            if (_step != _RecoveryStep.email) ...[
                              const SizedBox(height: AppDimensions.spaceMd),
                              _codeSection(theme),
                            ],
                            if (_step == _RecoveryStep.password) ...[
                              const SizedBox(height: AppDimensions.spaceLg),
                              _passwordSection(theme),
                            ],
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: AppDimensions.spaceMd),
                              Text(
                                auth.errorMessage!,
                                key: const Key('recovery_error'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppDimensions.spaceLg),
                            _primaryAction(auth.isBusy),
                            const SizedBox(height: AppDimensions.spaceSm),
                            TextButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: const Text('Cancel and Return'),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          text: 'Need manual assistance? ',
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: 'Contact campus IT Helpdesk',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryAction(bool busy) => switch (_step) {
    _RecoveryStep.email => PrimaryButton(
      key: const Key('recovery_send'),
      label: 'Send Recovery Code',
      trailingIcon: Icons.send,
      isLoading: busy,
      onPressed: _sendCode,
    ),
    _RecoveryStep.code => PrimaryButton(
      key: const Key('recovery_verify'),
      label: 'Verify Code',
      trailingIcon: Icons.arrow_forward,
      isLoading: busy,
      onPressed: _verifyCode,
    ),
    _ => PrimaryButton(
      key: const Key('recovery_update'),
      label: 'Update Password',
      trailingIcon: Icons.check,
      isLoading: busy,
      onPressed: _updatePassword,
    ),
  };

  Widget _emailSection(ThemeData theme) {
    final sent = _step != _RecoveryStep.email;
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            fieldKey: const Key('recovery_email'),
            controller: _email,
            label: 'Institutional Email',
            labelBadge: sent
                ? const StatusChip(
                    label: 'Code Sent ✓',
                    icon: Icons.check_circle_outline,
                    tone: StatusTone.info,
                  )
                : null,
            hint: 'name@campus.edu',
            prefixIcon: Icons.alternate_email,
            readOnly: sent,
            fillColor: theme.colorScheme.surfaceContainerLow,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            onSubmitted: (_) => _sendCode(),
          ),
          if (sent) ...[
            const SizedBox(height: AppDimensions.spaceSm),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: _resendIn > Duration.zero
                      ? Text.rich(
                          TextSpan(
                            text: 'Resend Code in ',
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: Formatters.countdown(_resendIn)
                                    .replaceFirst(RegExp(r'^0'), ''),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          onPressed: _sendCode,
                          child: const Text('Resend Code'),
                        ),
                ),
                TextButton(
                  onPressed: _changeEmail,
                  child: const Text('Change Email'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _codeSection(ThemeData theme) {
    final verified = _step == _RecoveryStep.password;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Enter ${AppConstants.recoveryCodeLength}-digit code.',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                verified ? 'Verified ✓' : 'Step 2 of 3',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          CodeInput(
            controller: _code,
            enabled: !verified,
            onCompleted: (_) => _verifyCode(),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            _codeError ??
                'Recovery code sent to your verified campus email inbox.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _codeError != null ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordSection(ThemeData theme) {
    final matches = _confirm.text.isNotEmpty && _confirm.text == _password.text;
    return Form(
      key: _passwordForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            fieldKey: const Key('recovery_password'),
            controller: _password,
            label: 'New Password',
            hint: 'Create a new password',
            prefixIcon: Icons.lock_outline,
            obscure: true,
            fillColor: theme.colorScheme.surfaceContainerLow,
            validator: Validators.newPassword,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          PasswordStrengthCard(password: _password.text, compact: true),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            fieldKey: const Key('recovery_confirm'),
            controller: _confirm,
            label: 'Confirm Password',
            hint: 'Re-enter the new password',
            prefixIcon: Icons.verified_user_outlined,
            fillColor: theme.colorScheme.surfaceContainerLow,
            suffix: matches
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: theme.colorScheme.secondary,
                    ),
                  )
                : null,
            validator: (v) => Validators.confirmPassword(v, _password.text),
          ),
        ],
      ),
    );
  }
}

/// Four-box numeric code entry backed by a single hidden text field.
class CodeInput extends StatelessWidget {
  const CodeInput({
    super.key,
    required this.controller,
    this.length = AppConstants.recoveryCodeLength,
    this.enabled = true,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool enabled;
  final ValueChanged<String>? onCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final text = value.text;
        return Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < length; i++) ...[
                  if (i > 0) const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.3,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == text.length && enabled
                              ? AppColors.primaryFixed.withValues(alpha: 0.5)
                              : theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          border: Border.all(
                            color: i == text.length && enabled
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          i < text.length ? text[i] : '',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  key: const Key('recovery_code'),
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  maxLength: length,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  showCursor: false,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: (v) {
                    if (v.length == length) onCompleted?.call(v);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('recovery_success'),
      children: [
        const SizedBox(height: AppDimensions.spaceSm),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: AppColors.successContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.task_alt, color: AppColors.success, size: 36),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Text('✓ Password Updated', style: theme.textTheme.titleLarge),
        Text('Just now', style: theme.textTheme.labelMedium),
        const SizedBox(height: AppDimensions.spaceSm),
        Text(
          'Your institutional security credentials have been updated successfully.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        PrimaryButton(
          key: const Key('recovery_return'),
          label: 'Return to Login',
          trailingIcon: Icons.arrow_forward,
          onPressed: onReturn,
        ),
      ],
    );
  }
}
