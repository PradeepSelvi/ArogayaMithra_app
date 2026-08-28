import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_providers.dart';

/// District dashboard (PRD 5.4, 19).
///
/// Alerts come first. A DHO opening this screen needs to know what is going wrong
/// right now, before any trend chart: which referrals have blown their SLA, which
/// facilities are critical or silent, and which citizen complaints are unresolved.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final profile = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.dashboardTitle),
        actions: [
          IconButton(
            tooltip: strings.actionRefresh,
            onPressed: () => ref
              ..invalidate(alertsProvider)
              ..invalidate(referralKpiProvider)
              ..invalidate(readinessHeatmapProvider)
              ..invalidate(feedbackKpiProvider)
              ..invalidate(followUpKpiProvider),
            icon: const Icon(Icons.refresh),
          ),
          if (profile?.fullName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AmTokens.spaceSm),
              child: Center(
                child: Text(
                  profile!.fullName!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          IconButton(
            tooltip: strings.signOut,
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AmContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          children: const [
            _AlertsSection(),
            SizedBox(height: AmTokens.spaceLg),
            _ReferralMetricsSection(),
            SizedBox(height: AmTokens.spaceLg),
            _ReadinessSection(),
            SizedBox(height: AmTokens.spaceLg),
            _FeedbackSection(),
            SizedBox(height: AmTokens.spaceXl),
          ],
        ),
      ),
    );
  }
}

class _AlertsSection extends ConsumerWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final alerts = ref.watch(alertsProvider);

    return AmSection(
      title: strings.dashboardAlerts,
      child: alerts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text(strings.errorUnexpected),
        data: (list) => list.isEmpty
            ? Text(strings.dashboardAlertsEmpty)
            : Column(
                children: [
                  for (final alert in list.take(20))
                    _AlertRow(alert: alert),
                ],
              ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final OperationalAlert alert;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);

    final label = switch (alert.alertType) {
      'referral_sla_breach' => strings.alertReferralSlaBreach,
      'readiness_critical' => strings.alertReadinessCritical,
      _ => strings.alertFeedbackIssue,
    };

    final tone = alert.isCritical ? AmTokens.emergency : AmTokens.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: AmTokens.spaceSm),
      child: Row(
        children: [
          Icon(
            alert.isCritical
                ? Icons.report_problem
                : Icons.warning_amber_rounded,
            color: tone,
            size: 20,
          ),
          const SizedBox(width: AmTokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                Text(
                  alert.subjectLabel,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            _relative(alert.raisedAt),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static String _relative(DateTime time) {
    final age = DateTime.now().difference(time);
    if (age.inMinutes < 60) return '${age.inMinutes}m';
    if (age.inHours < 24) return '${age.inHours}h';
    return '${age.inDays}d';
  }
}

class _ReferralMetricsSection extends ConsumerWidget {
  const _ReferralMetricsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final kpis = ref.watch(referralKpiProvider);
    final totals = ref.watch(referralTotalsProvider);

    return AmSection(
      title: strings.dashboardReferrals,
      child: kpis.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text(strings.errorUnexpected),
        data: (_) => Wrap(
          spacing: AmTokens.spaceMd,
          runSpacing: AmTokens.spaceMd,
          children: [
            SizedBox(
              width: 180,
              child: AmMetricTile(
                label: strings.dashboardMetricCreated,
                value: '${totals.created}',
                icon: Icons.assignment_outlined,
              ),
            ),
            SizedBox(
              width: 180,
              child: AmMetricTile(
                label: strings.dashboardMetricAccepted,
                value: '${totals.accepted}',
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(
              width: 180,
              child: AmMetricTile(
                label: strings.dashboardMetricCompleted,
                value: '${totals.completed}',
                icon: Icons.task_alt,
                tone: AmTokens.success,
              ),
            ),
            SizedBox(
              width: 180,
              child: AmMetricTile(
                label: strings.dashboardMetricBreaches,
                value: '${totals.slaBreaches}',
                icon: Icons.timer_off_outlined,
                tone: totals.slaBreaches > 0
                    ? AmTokens.emergency
                    : AmTokens.textSecondary,
              ),
            ),
            SizedBox(
              width: 180,
              child: AmMetricTile(
                label: strings.dashboardAcceptanceRate,
                value: _percent(totals.acceptanceRate),
                icon: Icons.percent,
              ),
            ),
            SizedBox(
              width: 180,
              child: AmMetricTile(
                label: strings.dashboardMedianTurnaround,
                value: totals.medianTurnaroundMinutes == null
                    ? '-'
                    : strings.dashboardMinutes(
                        totals.medianTurnaroundMinutes!.round().toString(),
                      ),
                icon: Icons.timelapse,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _percent(double? value) =>
      value == null ? '-' : '${(value * 100).round()}%';
}

class _ReadinessSection extends ConsumerWidget {
  const _ReadinessSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final language = ref.watch(currentLanguageProvider);
    final heatmap = ref.watch(readinessHeatmapProvider);

    return AmSection(
      title: strings.dashboardReadiness,
      child: heatmap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text(strings.errorUnexpected),
        data: (facilities) => facilities.isEmpty
            ? Text(strings.noResults)
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: AmTokens.spaceLg,
                  columns: [
                    DataColumn(label: Text(strings.dashboardReadiness)),
                    DataColumn(label: Text(strings.readinessDoctor)),
                    DataColumn(label: Text(strings.readinessMedicines)),
                    DataColumn(label: Text(strings.readinessDiagnostics)),
                    DataColumn(label: Text(strings.readinessBeds)),
                    DataColumn(label: Text(strings.dashboardReferrals)),
                  ],
                  rows: [
                    for (final facility in facilities)
                      DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                AmStatusChip.readinessBand(
                                  facility.band,
                                  strings: strings,
                                  dense: true,
                                ),
                                const SizedBox(width: AmTokens.spaceSm),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 260),
                                  child: Text(
                                    facility.displayName(language),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            AmStatusChip.availability(
                              facility.doctorStatus,
                              strings: strings,
                              dense: true,
                            ),
                          ),
                          DataCell(
                            AmStatusChip.availability(
                              facility.medicinesStatus,
                              strings: strings,
                              dense: true,
                            ),
                          ),
                          DataCell(
                            AmStatusChip.availability(
                              facility.diagnosticsStatus,
                              strings: strings,
                              dense: true,
                            ),
                          ),
                          DataCell(
                            AmStatusChip.availability(
                              facility.bedsStatus,
                              strings: strings,
                              dense: true,
                            ),
                          ),
                          DataCell(
                            Text('${facility.openIncomingReferrals}'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FeedbackSection extends ConsumerWidget {
  const _FeedbackSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final feedback = ref.watch(feedbackKpiProvider);

    return AmSection(
      title: strings.dashboardFeedback,
      child: feedback.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text(strings.errorUnexpected),
        data: (list) => list.isEmpty
            ? Text(strings.noResults)
            : Column(
                children: [
                  for (final kpi in list.take(10))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AmTokens.spaceSm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(kpi.facilityName ?? '-'),
                          ),
                          Text('${kpi.averageRating.toStringAsFixed(1)} / 5'),
                          const SizedBox(width: AmTokens.spaceMd),
                          if (kpi.openIssues > 0)
                            AmStatusChip(
                              label: '${kpi.openIssues}',
                              icon: Icons.report_problem_outlined,
                              foreground: AmTokens.emergency,
                              background: AmTokens.emergencyLight,
                              dense: true,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
