import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../language/locale_controller.dart';

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.beforeFood,
    required this.daysLeft,
    required this.prescribedBy,
    this.morningTaken = false,
    this.afternoonTaken = false,
    this.nightTaken = false,
  });

  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final bool morning;
  final bool afternoon;
  final bool night;
  final bool beforeFood;
  final int daysLeft;
  final String prescribedBy;
  final bool morningTaken;
  final bool afternoonTaken;
  final bool nightTaken;

  Medication copyWith({
    bool? morningTaken,
    bool? afternoonTaken,
    bool? nightTaken,
  }) {
    return Medication(
      id: id,
      name: name,
      dosage: dosage,
      frequency: frequency,
      morning: morning,
      afternoon: afternoon,
      night: night,
      beforeFood: beforeFood,
      daysLeft: daysLeft,
      prescribedBy: prescribedBy,
      morningTaken: morningTaken ?? this.morningTaken,
      afternoonTaken: afternoonTaken ?? this.afternoonTaken,
      nightTaken: nightTaken ?? this.nightTaken,
    );
  }
}

final medicationListProvider = StateProvider<List<Medication>>((ref) {
  return [
    const Medication(
      id: 'm-1',
      name: 'Metformin Hydrochloride',
      dosage: '500 mg',
      frequency: 'Twice daily',
      morning: true,
      afternoon: false,
      night: true,
      beforeFood: false,
      daysLeft: 12,
      prescribedBy: 'Dr. S. Ramanathan (MO, PHC Polur)',
      morningTaken: true,
      nightTaken: false,
    ),
    const Medication(
      id: 'm-2',
      name: 'Amlodipine Besylate',
      dosage: '5 mg',
      frequency: 'Once daily',
      morning: true,
      afternoon: false,
      night: false,
      beforeFood: true,
      daysLeft: 4,
      prescribedBy: 'Dr. K. Geetha (District HQ Hospital)',
      morningTaken: true,
    ),
    const Medication(
      id: 'm-3',
      name: 'Iron & Folic Acid Tablets',
      dosage: '100 mg / 500 mcg',
      frequency: 'Once daily',
      morning: false,
      afternoon: false,
      night: true,
      beforeFood: false,
      daysLeft: 2,
      prescribedBy: 'Govt. Maternity Care Roster',
      nightTaken: false,
    ),
  ];
});

class MedicationManagerScreen extends ConsumerWidget {
  const MedicationManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final isTamil = locale?.languageCode == 'ta';
    final medications = ref.watch(medicationListProvider);
    final lowStock = medications.where((m) => m.daysLeft <= 3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'மருந்து & நினைவூட்டல்' : 'Prescription & Medicines'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddMedicationModal(context, ref, isTamil),
        icon: const Icon(Icons.add_circle_outline),
        label: Text(isTamil ? 'மருந்து சேர்' : 'Add Medicine'),
        backgroundColor: AmTokens.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          children: [
            // Low Stock Refill Warning
            if (lowStock.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AmTokens.spaceMd),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTamil ? 'மறு நிரப்பல் தேவை (Refill Alert)' : 'Pharmacy Refill Alert',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                          ),
                          Text(
                            isTamil
                                ? '${lowStock.map((m) => m.name).join(', ')} மருந்துகள் 3 நாட்களுக்குள் முடிவடையும். அருகிலுள்ள PHC-ஐ அணுகவும்.'
                                : '${lowStock.map((m) => m.name).join(', ')} has 3 days or less remaining. Visit your PHC dispensary.',
                            style: TextStyle(color: Colors.brown.shade800, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AmTokens.spaceMd),
            ],

            // Daily Check-in Card
            Container(
              padding: const EdgeInsets.all(AmTokens.spaceMd),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade800, Colors.deepPurple.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
                boxShadow: const [
                  BoxShadow(color: Color(0x29000000), blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.today, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isTamil ? 'இன்றைய மருந்து அட்டவணை' : 'Today\'s Dose Schedule',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isTamil
                        ? 'மருந்துகளை எடுத்துக் கொண்டவுடன் டிக் செய்யவும்'
                        : 'Tap the pills below after taking your scheduled doses',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TimeSlotPill(
                        icon: Icons.wb_sunny_outlined,
                        label: isTamil ? 'காலை' : 'Morning',
                        time: '8:00 AM',
                        activeCount: medications.where((m) => m.morning).length,
                        completedCount: medications.where((m) => m.morning && m.morningTaken).length,
                      ),
                      Container(width: 1, height: 36, color: Colors.white24),
                      _TimeSlotPill(
                        icon: Icons.light_mode_outlined,
                        label: isTamil ? 'மதியம்' : 'Noon',
                        time: '1:30 PM',
                        activeCount: medications.where((m) => m.afternoon).length,
                        completedCount: medications.where((m) => m.afternoon && m.afternoonTaken).length,
                      ),
                      Container(width: 1, height: 36, color: Colors.white24),
                      _TimeSlotPill(
                        icon: Icons.nightlight_round,
                        label: isTamil ? 'இரவு' : 'Night',
                        time: '8:30 PM',
                        activeCount: medications.where((m) => m.night).length,
                        completedCount: medications.where((m) => m.night && m.nightTaken).length,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AmTokens.spaceLg),

            // Prescriptions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTamil ? 'பரிந்துரைக்கப்பட்ட மருந்துகள்' : 'Active Prescriptions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${medications.length} ${isTamil ? 'மருந்துகள்' : 'medicines'}',
                  style: const TextStyle(color: AmTokens.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: AmTokens.spaceSm),

            // Prescriptions List
            ...medications.map((med) => _MedicationCard(
                  medication: med,
                  isTamil: isTamil,
                  onToggleMorning: (val) {
                    ref.read(medicationListProvider.notifier).update(
                          (list) => list.map((m) => m.id == med.id ? m.copyWith(morningTaken: val) : m).toList(),
                        );
                  },
                  onToggleNight: (val) {
                    ref.read(medicationListProvider.notifier).update(
                          (list) => list.map((m) => m.id == med.id ? m.copyWith(nightTaken: val) : m).toList(),
                        );
                  },
                )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _openAddMedicationModal(BuildContext context, WidgetRef ref, bool isTamil) {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    bool morning = true;
    bool afternoon = false;
    bool night = true;
    bool beforeFood = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AmTokens.radiusLarge)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AmTokens.spaceMd,
            right: AmTokens.spaceMd,
            top: AmTokens.spaceLg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AmTokens.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTamil ? 'புதிய மருந்து விவரம் சேர்' : 'Add Prescription Medicine',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: AmTokens.spaceMd),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: isTamil ? 'மருந்தின் பெயர்' : 'Medicine Name',
                  hintText: 'e.g. Paracetamol / Metformin',
                  prefixIcon: const Icon(Icons.medication_outlined),
                ),
              ),
              const SizedBox(height: AmTokens.spaceSm),
              TextField(
                controller: doseCtrl,
                decoration: InputDecoration(
                  labelText: isTamil ? 'அளவு (Dosage)' : 'Dosage',
                  hintText: 'e.g. 500 mg / 10 ml',
                  prefixIcon: const Icon(Icons.fitness_center_outlined),
                ),
              ),
              const SizedBox(height: AmTokens.spaceMd),
              Text(
                isTamil ? 'சாப்பிடும் நேரம் (Daily Timing)' : 'Daily Timing',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  FilterChip(
                    label: Text(isTamil ? 'காலை' : 'Morning'),
                    selected: morning,
                    onSelected: (val) => setModalState(() => morning = val),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(isTamil ? 'மதியம்' : 'Noon'),
                    selected: afternoon,
                    onSelected: (val) => setModalState(() => afternoon = val),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(isTamil ? 'இரவு' : 'Night'),
                    selected: night,
                    onSelected: (val) => setModalState(() => night = val),
                  ),
                ],
              ),
              const SizedBox(height: AmTokens.spaceSm),
              Row(
                children: [
                  Checkbox(
                    value: beforeFood,
                    onChanged: (val) => setModalState(() => beforeFood = val ?? false),
                  ),
                  Text(isTamil ? 'உணவுக்கு முன் உட்கொள்ளவும்' : 'Take before food'),
                ],
              ),
              const SizedBox(height: AmTokens.spaceLg),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AmTokens.primary,
                  minimumSize: const Size(0, 46),
                ),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final newMed = Medication(
                    id: 'm-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    dosage: doseCtrl.text.trim().isEmpty ? '1 Tablet' : doseCtrl.text.trim(),
                    frequency: 'Daily prescribed',
                    morning: morning,
                    afternoon: afternoon,
                    night: night,
                    beforeFood: beforeFood,
                    daysLeft: 14,
                    prescribedBy: 'Self added / Doctor consultation',
                  );
                  ref.read(medicationListProvider.notifier).update((list) => [newMed, ...list]);
                  Navigator.of(ctx).pop();
                },
                child: Text(isTamil ? 'சேமி' : 'Save Prescription'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSlotPill extends StatelessWidget {
  const _TimeSlotPill({
    required this.icon,
    required this.label,
    required this.time,
    required this.activeCount,
    required this.completedCount,
  });

  final IconData icon;
  final String label;
  final String time;
  final int activeCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final allDone = activeCount > 0 && completedCount == activeCount;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 2),
        Text(time, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: allDone ? Colors.tealAccent.withAlpha(50) : const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            activeCount == 0 ? 'None' : '$completedCount / $activeCount done',
            style: TextStyle(
              color: allDone ? Colors.tealAccent : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.isTamil,
    required this.onToggleMorning,
    required this.onToggleNight,
  });

  final Medication medication;
  final bool isTamil;
  final ValueChanged<bool> onToggleMorning;
  final ValueChanged<bool> onToggleNight;

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${medication.dosage} • ${medication.beforeFood ? (isTamil ? 'உணவுக்கு முன்' : 'Before food') : (isTamil ? 'உணவுக்கு பின்' : 'After food')}',
                        style: const TextStyle(color: AmTokens.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: medication.daysLeft <= 3 ? Colors.amber.shade100 : AmTokens.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${medication.daysLeft} ${isTamil ? 'நாட்கள் மீதம்' : 'days left'}',
                    style: TextStyle(
                      color: medication.daysLeft <= 3 ? Colors.brown.shade800 : AmTokens.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (medication.morning) ...[
                  InkWell(
                    onTap: () => onToggleMorning(!medication.morningTaken),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: medication.morningTaken ? Colors.teal.shade50 : Colors.grey.shade100,
                        border: Border.all(color: medication.morningTaken ? Colors.teal : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            medication.morningTaken ? Icons.check_box : Icons.check_box_outline_blank,
                            size: 16,
                            color: medication.morningTaken ? Colors.teal : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTamil ? 'காலை மாத்திரை' : 'Morning Dose',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: medication.morningTaken ? Colors.teal.shade800 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (medication.night) ...[
                  InkWell(
                    onTap: () => onToggleNight(!medication.nightTaken),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: medication.nightTaken ? Colors.teal.shade50 : Colors.grey.shade100,
                        border: Border.all(color: medication.nightTaken ? Colors.teal : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            medication.nightTaken ? Icons.check_box : Icons.check_box_outline_blank,
                            size: 16,
                            color: medication.nightTaken ? Colors.teal : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTamil ? 'இரவு மாத்திரை' : 'Night Dose',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: medication.nightTaken ? Colors.teal.shade800 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '👨‍⚕️ ${medication.prescribedBy}',
              style: const TextStyle(color: AmTokens.textSecondary, fontSize: 10, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
