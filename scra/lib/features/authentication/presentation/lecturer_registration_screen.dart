import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../widgets/common/status_chip.dart';
import '../widgets/account_setup_form.dart';
import '../widgets/role_header.dart';

/// Stitch screen 08 — Lecturer Registration.
class LecturerRegistrationScreen extends StatelessWidget {
  const LecturerRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GatewayAppBar(
        title: 'Smart Class',
        overline: 'Faculty Gateway',
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
              children: const [
                RoleHeader(
                  icon: Icons.co_present_outlined,
                  title: 'Lecturer Registration',
                  description: 'Verify your institutional faculty credentials to configure course broadcast tools and academic lecture attendance.',
                  step: StepInfo(
                    overline: 'Faculty Verification',
                    title: 'Staff Credentials Setup',
                    current: 2,
                    total: 2,
                  ),
                ),
                SizedBox(height: AppDimensions.spaceLg),
                AccountSetupForm(
                  role: UserRole.lecturer,
                  idLabel: 'Staff / Lecturer ID',
                  idHint: 'Your staff / lecturer ID',
                  idHelper: 'Found on your academic employment smartcard or faculty portal.',
                  idValidator: Validators.staffId,
                  idBadge: StatusChip(
                    label: 'FACULTY ID',
                    tone: StatusTone.primary,
                    dense: true,
                  ),
                  emailHint: 'name@faculty.edu',
                  submitLabel: 'Complete Lecturer Setup',
                ),
                SizedBox(height: AppDimensions.spaceMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
