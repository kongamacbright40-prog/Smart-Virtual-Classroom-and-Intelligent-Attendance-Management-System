import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../widgets/account_setup_form.dart';
import '../widgets/role_header.dart';

/// Stitch screen 07 — Activate Student Account.
class StudentActivationScreen extends StatelessWidget {
  const StudentActivationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GatewayAppBar(
        title: 'Smart Class',
        overline: 'Student Gateway',
        titleIcon: Icons.school,
        overlineBelow: true,
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
                  icon: Icons.workspace_premium_outlined,
                  badgeIcon: Icons.verified,
                  title: 'Activate Student Account',
                  description: 'Verify your institutional credentials to configure your academic portal and smart attendance pass.',
                  step: StepInfo(
                    overline: 'Identity Verification',
                    title: 'Step 2 of 2 · Campus Pass Setup',
                    current: 2,
                    total: 2,
                  ),
                ),
                SizedBox(height: AppDimensions.spaceLg),
                AccountSetupForm(
                  role: UserRole.student,
                  idLabel: 'Student Matricule',
                  idHint: 'e.g. MAT-2024-9148',
                  idHelper: 'Found on your student smartcard or formal admission letter',
                  idValidator: Validators.studentId,
                  idSuffixLabel: 'SIS ID',
                  emailHint: 'name@campus.edu',
                  submitLabel: 'Activate Account',
                  acknowledgement: 'I acknowledge institutional terms of academic integrity, identity verification protocols, and automatic biometric attendance logging.',
                ),
                SizedBox(height: AppDimensions.spaceMd),
                SecurityFooter(
                  text: '256-Bit TLS · University Registrar SIS Certified',
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
