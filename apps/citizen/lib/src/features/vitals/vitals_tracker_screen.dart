import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../language/locale_controller.dart';

/// Health biometric reading entry.
class VitalReading {
  const VitalReading({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.bloodGlucose,
    required this.glucoseType,
    required this.heartRate,
    required this.spo2,
    required this.recordedAt,
    this.notes,
  });

  final String id;
  final int systolic;
  final int diastolic;
  final int bloodGlucose;
  final String glucoseType; // 'fasting' | 'post_meal' | 'random'
  final int heartRate;
  final int spo2;
  final DateTime recordedAt;
  final String? notes;

  String get bpStatus {
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic < 130 && diastolic < 80) return 'Elevated';
    if (systolic < 140 || diastolic < 90) return 'Stage 1';
    return 'Stage 2 High';
  }

  Color get bpColor {
    if (systolic < 120 && diastolic < 80) return Colors.teal;
    if (systolic < 130 && diastolic < 80) return Colors.orange;
    return Colors.red.shade700;
  }
}

/// In-memory state provider for vitals readings
final vitalsListProvider = StateProvider<List<VitalReading>>((ref) {
  return [
    VitalReading(
      id: 'v-1',
      systolic: 118,
      diastolic: 78,
      bloodGlucose: 104,
      glucoseType: 'fasting',
      heartRate: 72,
      spo2: 99,
      recordedAt: DateTime.now().subtract(const Duration(hours: 3)),
      notes: 'Morning routine check',
    ),
    VitalReading(
      id: 'v-2',
      systolic: 126,
      diastolic: 82,
      bloodGlucose: 142,
      glucoseType: 'post_meal',
      heartRate: 76,
      spo2: 98,
      recordedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      notes: 'After lunch at PHC checkup',
    ),
    VitalReading(
      id: 'v-3',
      systolic: 122,
      diastolic: 80,
      bloodGlucose: 110,
      glucoseType: 'fasting',
      heartRate: 74,
      spo2: 99,
      recordedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
});

class VitalsTrackerScreen extends ConsumerWidget {
  const VitalsTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final isTamil = locale?.languageCode == 'ta';
    final vitals = ref.watch(vitalsListProvider);
    final latest = vitals.isNotEmpty ? vitals.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'உடல் நல அளவீடுகள்' : 'Vitals & Health Metrics'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLogModal(context, ref, isTamil),
        icon: const Icon(Icons.add),
        label: Text(isTamil ? 'அளவீடு சேர்' : 'Log Reading'),
        backgroundColor: AmTokens.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          children: [
            // Latest summary banner
            if (latest != null) ...[
              Container(
                padding: const EdgeInsets.all(AmTokens.spaceMd),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade900, Colors.blueGrey.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.monitor_heart,
                                color: Colors.tealAccent,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isTamil ? 'கடைசி பதிவு' : 'Latest Reading',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(
                              AmTokens.radiusSmall,
                            ),
                          ),
                          child: Text(
                            latest.bpStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MetricCol(
                          label: isTamil ? 'இரத்த அழுத்தம்' : 'Blood Pressure',
                          value: '${latest.systolic}/${latest.diastolic}',
                          unit: 'mmHg',
                          color: latest.bpColor,
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _MetricCol(
                          label: isTamil ? 'இரத்த சர்க்கரை' : 'Blood Sugar',
                          value: '${latest.bloodGlucose}',
                          unit: 'mg/dL',
                          color: latest.bloodGlucose > 140
                              ? Colors.orange
                              : Colors.tealAccent,
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _MetricCol(
                          label: isTamil ? 'துடிப்பு & SpO2' : 'Pulse & SpO2',
                          value: '${latest.heartRate} / ${latest.spo2}%',
                          unit: 'BPM / %',
                          color: Colors.cyanAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AmTokens.spaceLg),
            ],

            // Clinical Reference Standards info card
            Card(
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
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AmTokens.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isTamil
                              ? 'மருத்துவ வழிகாட்டுதல் அளவுகள்'
                              : 'Normal Reference Ranges',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _ReferenceRow(
                      label: 'BP (Blood Pressure)',
                      range: '< 120 / 80 mmHg (Normal)',
                    ),
                    const _ReferenceRow(
                      label: 'Fasting Blood Sugar',
                      range: '70 - 100 mg/dL',
                    ),
                    const _ReferenceRow(
                      label: 'Post-Meal Sugar',
                      range: '< 140 mg/dL',
                    ),
                    const _ReferenceRow(
                      label: 'Resting Pulse',
                      range: '60 - 100 BPM',
                    ),
                    const _ReferenceRow(
                      label: 'Oxygen Saturation (SpO2)',
                      range: '95% - 100%',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AmTokens.spaceLg),

            // History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    isTamil ? 'முந்தைய பதிவுகள்' : 'Measurement Log History',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${vitals.length} ${isTamil ? 'பதிவுகள்' : 'entries'}',
                  style: const TextStyle(
                    color: AmTokens.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AmTokens.spaceSm),

            // Readings List
            ...vitals.map((v) => _ReadingCard(reading: v, isTamil: isTamil)),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _openLogModal(BuildContext context, WidgetRef ref, bool isTamil) {
    final sysCtrl = TextEditingController(text: '120');
    final diaCtrl = TextEditingController(text: '80');
    final sugarCtrl = TextEditingController(text: '110');
    final pulseCtrl = TextEditingController(text: '72');
    final spo2Ctrl = TextEditingController(text: '99');
    String glucoseType = 'fasting';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AmTokens.radiusLarge),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: AmTokens.spaceMd,
            right: AmTokens.spaceMd,
            top: AmTokens.spaceLg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AmTokens.spaceLg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        isTamil
                            ? 'புதிய உடல் அளவீடு பதிவு'
                            : 'Log Health Vitals',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AmTokens.spaceMd),

                // BP Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isTamil ? 'சிஸ்டாலிக் (Sys)' : 'Systolic',
                          suffixText: 'mmHg',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: diaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isTamil ? 'டயஸ்டாலிக் (Dia)' : 'Diastolic',
                          suffixText: 'mmHg',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AmTokens.spaceSm),

                // Blood Sugar Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sugarCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isTamil
                              ? 'இரத்த சர்க்கரை'
                              : 'Blood Glucose',
                          suffixText: 'mg/dL',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: glucoseType,
                        decoration: InputDecoration(
                          labelText: isTamil ? 'வகை' : 'Timing',
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'fasting',
                            child: Text(isTamil ? 'உணவுக்கு முன்' : 'Fasting'),
                          ),
                          DropdownMenuItem(
                            value: 'post_meal',
                            child: Text(
                              isTamil ? 'உணவுக்கு பின்' : 'Post-Meal',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'random',
                            child: Text(isTamil ? 'சாதாரண நேரம்' : 'Random'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null)
                            setDialogState(() => glucoseType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AmTokens.spaceSm),

                // Heart Rate & SpO2
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pulseCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isTamil ? 'நாடித் துடிப்பு' : 'Pulse',
                          suffixText: 'BPM',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: spo2Ctrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isTamil ? 'ஆக்சிஜன் (SpO2)' : 'SpO2 %',
                          suffixText: '%',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AmTokens.spaceLg),

                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AmTokens.primary,
                    minimumSize: const Size(0, 46),
                  ),
                  onPressed: () {
                    final sys = int.tryParse(sysCtrl.text) ?? 120;
                    final dia = int.tryParse(diaCtrl.text) ?? 80;
                    final sugar = int.tryParse(sugarCtrl.text) ?? 110;
                    final pulse = int.tryParse(pulseCtrl.text) ?? 72;
                    final spo2 = int.tryParse(spo2Ctrl.text) ?? 99;

                    final newReading = VitalReading(
                      id: 'v-${DateTime.now().millisecondsSinceEpoch}',
                      systolic: sys,
                      diastolic: dia,
                      bloodGlucose: sugar,
                      glucoseType: glucoseType,
                      heartRate: pulse,
                      spo2: spo2,
                      recordedAt: DateTime.now(),
                    );

                    ref
                        .read(vitalsListProvider.notifier)
                        .update((state) => [newReading, ...state]);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isTamil
                              ? 'அளவீடு வெற்றிகரமாக பதிவு செய்யப்பட்டது!'
                              : 'Vitals logged successfully!',
                        ),
                      ),
                    );
                  },
                  child: Text(isTamil ? 'சேமி' : 'Save Vitals'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCol extends StatelessWidget {
  const _MetricCol({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.label, required this.range});

  final String label;
  final String range;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AmTokens.textSecondary),
          ),
          Text(
            range,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading, required this.isTamil});

  final VitalReading reading;
  final bool isTamil;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${reading.recordedAt.day}/${reading.recordedAt.month}/${reading.recordedAt.year} • ${reading.recordedAt.hour.toString().padLeft(2, '0')}:${reading.recordedAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: AmTokens.spaceSm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AmTokens.border),
        borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AmTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: AmTokens.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: reading.bpColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: reading.bpColor.withAlpha(80)),
                  ),
                  child: Text(
                    reading.bpStatus,
                    style: TextStyle(
                      color: reading.bpColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(
                  label: 'BP',
                  value: '${reading.systolic}/${reading.diastolic} mmHg',
                ),
                _MiniStat(
                  label: 'Sugar (${reading.glucoseType})',
                  value: '${reading.bloodGlucose} mg/dL',
                ),
                _MiniStat(label: 'Pulse', value: '${reading.heartRate} bpm'),
                _MiniStat(label: 'SpO2', value: '${reading.spo2}%'),
              ],
            ),
            if (reading.notes != null) ...[
              const SizedBox(height: 6),
              Text(
                '📝 ${reading.notes}',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AmTokens.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AmTokens.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
