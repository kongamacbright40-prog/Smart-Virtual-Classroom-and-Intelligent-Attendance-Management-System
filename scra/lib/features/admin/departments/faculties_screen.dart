
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/status_chip.dart';

class FacultiesScreen extends StatelessWidget {
  const FacultiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AdminScreenHeader(title: 'Faculties', showBack: true),
      body: AsyncView<List<FacultyModel>>(
        load: () => context.read<AdminRepository>().getFaculties(),
        builder: (context, faculties, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            children: [
              const AdminHeroCard(title: 'Faculty Directory', subtitle: 'Dean, programme and population overview.', icon: Icons.account_balance_outlined),
              const SizedBox(height: AppDimensions.spaceMd),
              for (final faculty in faculties) _FacultyCard(faculty: faculty),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacultyCard extends StatelessWidget {
  const _FacultyCard({required this.faculty});
  final FacultyModel faculty;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      onTap: () => Navigator.of(context).maybePop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CodeTag(faculty.code),
              const SizedBox(width: AppDimensions.spaceSm),
              StatusChip(label: faculty.isActive ? 'Active' : 'Archived', tone: faculty.isActive ? StatusTone.success : StatusTone.neutral, dense: true),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(faculty.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
          Text('Dean: ${faculty.deanName ?? 'Unassigned'}'),
          const SizedBox(height: AppDimensions.spaceMd),
          Wrap(
            spacing: AppDimensions.spaceSm,
            runSpacing: AppDimensions.spaceSm,
            children: [
              _pill(context, faculty.category ?? 'General'),
              _pill(context, '${faculty.departmentCount} Departments'),
              _pill(context, '${faculty.courseCount} Courses'),
              _pill(context, '${Formatters.compactNumber(faculty.studentCount)} Students'),
              _pill(context, '${faculty.staffCount} Staff'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
        child: Text(label),
      );
}
