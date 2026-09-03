import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.fullName,
    required this.relation,
    required this.age,
    required this.gender,
    required this.abhaSuffix,
    this.chronicConditions = const [],
    this.isPregnant = false,
  });

  final String id;
  final String fullName;
  final String relation;
  final int age;
  final String gender;
  final String abhaSuffix;
  final List<String> chronicConditions;
  final bool isPregnant;
}

final familyMembersListProvider = StateProvider<List<FamilyMember>>((ref) {
  return const [
    FamilyMember(
      id: 'fam-self',
      fullName: 'Meena Ravi',
      relation: 'Self',
      age: 28,
      gender: 'Female',
      abhaSuffix: '0002',
      chronicConditions: ['diabetes'],
    ),
    FamilyMember(
      id: 'fam-spouse',
      fullName: 'Ravi Kumar',
      relation: 'Spouse',
      age: 34,
      gender: 'Male',
      abhaSuffix: '0005',
      chronicConditions: [],
    ),
    FamilyMember(
      id: 'fam-mother',
      fullName: 'Kamala',
      relation: 'Mother',
      age: 68,
      gender: 'Female',
      abhaSuffix: '0008',
      chronicConditions: ['hypertension'],
    ),
    FamilyMember(
      id: 'fam-child',
      fullName: 'Ananya',
      relation: 'Daughter',
      age: 4,
      gender: 'Female',
      abhaSuffix: '0011',
      chronicConditions: [],
    ),
  ];
});

final activeFamilyMemberIdProvider = StateProvider<String>((ref) => 'fam-self');

final currentFamilyMemberProvider = Provider<FamilyMember>((ref) {
  final list = ref.watch(familyMembersListProvider);
  final activeId = ref.watch(activeFamilyMemberIdProvider);
  return list.firstWhere((m) => m.id == activeId, orElse: () => list.first);
});

class FamilyMemberSwitcher extends ConsumerWidget {
  const FamilyMemberSwitcher({super.key, required this.isTamil});

  final bool isTamil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersListProvider);
    final activeId = ref.watch(activeFamilyMemberIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isTamil ? 'குடும்ப உறுப்பினர்கள்' : 'Household Members',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AmTokens.textSecondary),
            ),
            InkWell(
              onTap: () => _openAddMemberModal(context, ref, isTamil),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  isTamil ? '+ உறுப்பினர் சேர்' : '+ Add Member',
                  style: const TextStyle(color: AmTokens.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final member = members[idx];
              final isSelected = member.id == activeId;

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: isSelected ? Colors.white : AmTokens.primaryLight,
                      child: Text(
                        member.fullName[0],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AmTokens.primary : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${member.fullName} (${member.relation})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: AmTokens.primary,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                onSelected: (val) {
                  if (val) {
                    ref.read(activeFamilyMemberIdProvider.notifier).state = member.id;
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _openAddMemberModal(BuildContext context, WidgetRef ref, bool isTamil) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String relation = 'Child';
    String gender = 'Female';

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
              Text(
                isTamil ? 'புதிய குடும்ப உறுப்பினர் பதிவு' : 'Add Household Dependent',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AmTokens.spaceMd),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: isTamil ? 'முழு பெயர்' : 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AmTokens.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isTamil ? 'வயது' : 'Age',
                        prefixIcon: const Icon(Icons.cake_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: relation,
                      decoration: InputDecoration(
                        labelText: isTamil ? 'உறவு' : 'Relation',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                        DropdownMenuItem(value: 'Child', child: Text('Child')),
                        DropdownMenuItem(value: 'Mother', child: Text('Mother')),
                        DropdownMenuItem(value: 'Father', child: Text('Father')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => relation = val);
                      },
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
                  if (nameCtrl.text.trim().isEmpty) return;
                  final newMember = FamilyMember(
                    id: 'fam-${DateTime.now().millisecondsSinceEpoch}',
                    fullName: nameCtrl.text.trim(),
                    relation: relation,
                    age: int.tryParse(ageCtrl.text) ?? 20,
                    gender: gender,
                    abhaSuffix: '${(1000 + DateTime.now().millisecond % 9000)}',
                  );
                  ref.read(familyMembersListProvider.notifier).update((list) => [...list, newMember]);
                  ref.read(activeFamilyMemberIdProvider.notifier).state = newMember.id;
                  Navigator.of(ctx).pop();
                },
                child: Text(isTamil ? 'உறுப்பினரை சேர்' : 'Add to Family Pass'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
