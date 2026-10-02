import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../widgets/common/status_chip.dart';
import '../widgets/account_setup_form.dart';
import '../widgets/role_header.dart';

/// Administrator registration, opened from the admin login screen.
class AdminRegistrationScreen extends StatelessWidget {
  const AdminRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GatewayAppBar(
        title: 'Smart Class',
        overline: 'Administration Gateway',
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
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Administrator Registration',
                  description:
                      'Create an administrator account to manage faculties, '
                      'courses, users and attendance reports.',
                  step: StepInfo(
                    overline: 'Administrator Verification',
                    title: 'Account Setup',
                    current: 2,
                    total: 2,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                AccountSetupForm(
                  role: UserRole.admin,
                  idLabel: 'Staff / Admin ID',
                  idHint: 'Your staff or administrator ID',
                  idHelper: 'Your institutional staff ID.',
                  idValidator: (v) => Validators.required(v, field: 'Admin ID'),
                  idBadge: const StatusChip(
                    label: 'ADMIN',
                    tone: StatusTone.info,
                    dense: true,
                  ),
                  emailHint: 'name@institution.edu',
                  submitLabel: 'Create Admin Account',
                  loginRoute: RouteNames.adminLogin,
                ),
                const SizedBox(height: AppDimensions.spaceMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
