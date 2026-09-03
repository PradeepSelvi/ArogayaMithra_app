import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../language/locale_controller.dart';

class LabTestItem {
  const LabTestItem({
    required this.parameter,
    required this.resultValue,
    required this.referenceRange,
    required this.unit,
    required this.isNormal,
  });

  final String parameter;
  final String resultValue;
  final String referenceRange;
  final String unit;
  final bool isNormal;
}

class DiagnosticReport {
  const DiagnosticReport({
    required this.id,
    required this.testTitle,
    required this.category,
    required this.testDate,
    required this.orderingFacility,
    required this.labTechnician,
    required this.statusLabel,
    required this.isAbnormal,
    required this.items,
  });

  final String id;
  final String testTitle;
  final String category;
  final DateTime testDate;
  final String orderingFacility;
  final String labTechnician;
  final String statusLabel;
  final bool isAbnormal;
  final List<LabTestItem> items;
}

final diagnosticReportsProvider = Provider<List<DiagnosticReport>>((ref) {
  return [
    DiagnosticReport(
      id: 'rep-01',
      testTitle: 'Complete Blood Count (CBC) with Differential',
      category: 'Haematology',
      testDate: DateTime.now().subtract(const Duration(days: 4)),
      orderingFacility: 'District Headquarters Hospital, Tiruvannamalai',
      labTechnician: 'K. Selvaraj (NABL Certified)',
      statusLabel: 'Normal',
      isAbnormal: false,
      items: const [
        LabTestItem(parameter: 'Hemoglobin', resultValue: '12.8', referenceRange: '12.0 - 15.5', unit: 'g/dL', isNormal: true),
        LabTestItem(parameter: 'Total WBC Count', resultValue: '7,400', referenceRange: '4,000 - 11,000', unit: '/mcL', isNormal: true),
        LabTestItem(parameter: 'Platelet Count', resultValue: '2.4', referenceRange: '1.5 - 4.5', unit: 'Lakhs/mcL', isNormal: true),
        LabTestItem(parameter: 'RBC Count', resultValue: '4.5', referenceRange: '3.8 - 5.2', unit: 'Million/mcL', isNormal: true),
      ],
    ),
    DiagnosticReport(
      id: 'rep-02',
      testTitle: 'HbA1c & Fasting Blood Sugar Profile',
      category: 'Biochemistry',
      testDate: DateTime.now().subtract(const Duration(days: 12)),
      orderingFacility: 'Primary Health Centre, Polur',
      labTechnician: 'M. Anandhi (Govt Lab Tech)',
      statusLabel: 'Borderline Elevated',
      isAbnormal: true,
      items: const [
        LabTestItem(parameter: 'Fasting Plasma Glucose', resultValue: '118', referenceRange: '70 - 100', unit: 'mg/dL', isNormal: false),
        LabTestItem(parameter: 'Glycated Hemoglobin (HbA1c)', resultValue: '6.2', referenceRange: '< 5.7', unit: '%', isNormal: false),
        LabTestItem(parameter: 'Average Blood Glucose', resultValue: '131', referenceRange: '< 117', unit: 'mg/dL', isNormal: false),
      ],
    ),
    DiagnosticReport(
      id: 'rep-03',
      testTitle: 'Urine Routine & Microscopic Analysis',
      category: 'Clinical Pathology',
      testDate: DateTime.now().subtract(const Duration(days: 20)),
      orderingFacility: 'Government Medical College Hospital, Tiruvannamalai',
      labTechnician: 'R. Vignesh',
      statusLabel: 'Normal',
      isAbnormal: false,
      items: const [
        LabTestItem(parameter: 'Urine Protein', resultValue: 'Nil', referenceRange: 'Negative', unit: '', isNormal: true),
        LabTestItem(parameter: 'Urine Sugar', resultValue: 'Nil', referenceRange: 'Negative', unit: '', isNormal: true),
        LabTestItem(parameter: 'Pus Cells', resultValue: '1 - 2', referenceRange: '0 - 5', unit: '/HPF', isNormal: true),
      ],
    ),
  ];
});

class LabVaultScreen extends ConsumerWidget {
  const LabVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final isTamil = locale?.languageCode == 'ta';
    final reports = ref.watch(diagnosticReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'மருத்துவ பரிசோதனை அறிக்கைகள்' : 'Diagnostic Lab Vault'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          children: [
            // ABDM Health Locker Header Banner
            Container(
              padding: const EdgeInsets.all(AmTokens.spaceMd),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.teal.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
                boxShadow: const [
                  BoxShadow(color: Color(0x29000000), blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0x33FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_shared_outlined, color: Colors.cyanAccent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'ABDM டிஜிட்டல் சுகாதார ஆவணங்கள்' : 'ABDM Digital Health Locker',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTamil
                              ? 'அரசு ஆய்வகங்களால் சரிபார்க்கப்பட்ட டிஜிட்டல் பரிசோதனை முடிவுகள்'
                              : 'Government NABL verified clinical lab findings linked to your ABHA ID',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AmTokens.spaceLg),

            // Reports Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTamil ? 'சமீபத்திய ஆய்வக முடிவுகள்' : 'Recent Lab Reports',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${reports.length} ${isTamil ? 'அறிக்கைகள்' : 'verified'}',
                  style: const TextStyle(color: AmTokens.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: AmTokens.spaceSm),

            // Reports List
            ...reports.map((r) => _ReportCard(report: r, isTamil: isTamil)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.isTamil});

  final DiagnosticReport report;
  final bool isTamil;

  @override
  Widget build(BuildContext context) {
    final dateStr = '${report.testDate.day}/${report.testDate.month}/${report.testDate.year}';
    final statusColor = report.isAbnormal ? Colors.orange.shade800 : Colors.teal;

    return Card(
      margin: const EdgeInsets.only(bottom: AmTokens.spaceSm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AmTokens.border),
        borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AmTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report.category,
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(dateStr, style: const TextStyle(color: AmTokens.textSecondary, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              report.testTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              '🏥 ${report.orderingFacility}',
              style: const TextStyle(color: AmTokens.textSecondary, fontSize: 11),
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      report.isAbnormal ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      report.statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _openBreakdownModal(context),
                  icon: const Icon(Icons.analytics_outlined, size: 16),
                  label: Text(isTamil ? 'விவரங்களை காண்க' : 'View Parameters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openBreakdownModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AmTokens.radiusLarge)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AmTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              report.testTitle,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Verified by: ${report.labTechnician}',
              style: const TextStyle(color: AmTokens.textSecondary, fontSize: 11),
            ),
            const Divider(height: 20),
            ...report.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.parameter, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.resultValue} ${item.unit}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: item.isNormal ? Colors.black87 : Colors.orange.shade900,
                          ),
                        ),
                        Text(
                          'Ref: ${item.referenceRange}',
                          style: const TextStyle(fontSize: 10, color: AmTokens.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AmTokens.primary,
                minimumSize: const Size(0, 42),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ABHA Diagnostic PDF report downloaded')),
                );
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download Official Lab Slip'),
            ),
          ],
        ),
      ),
    );
  }
}
