import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/features/admin/dashboard/widgets/admin_activity_item.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/empty_state.dart';

/// Full administrative activity log (account, course and class changes).
class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AdminScreenHeader(title: 'Activity Log', showBack: true),
      body: AsyncView<List<ActivityLogModel>>(
        load: () =>
            context.read<AdminRepository>().getRecentActivity(limit: 200),
        builder: (context, activity, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            children: [
              if (activity.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No activity yet',
                  message:
                      'Changes to accounts, courses and classes appear here.',
                )
              else
                AppCard(
                  child: Column(
                    children: [
                      for (final item in activity)
                        AdminActivityItem(activity: item),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
