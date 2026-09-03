import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../language/locale_controller.dart';
import '../triage/care_journey_controller.dart';

/// Comprehensive profile management and digital health pass for citizens.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(currentUserProvider);
    final patientAsync = ref.watch(selfPatientProvider);
    final locale = ref.watch(localeControllerProvider);
    final isTamil = locale?.languageCode == 'ta';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'சுயவிவரம் & அட்டை' : 'Profile & Health ID'),
        actions: [
          IconButton(
            tooltip: strings.signOut,
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: patientAsync.when(
          loading: () => AmLoadingView(message: strings.loading),
          error: (e, _) => Center(
            child: Text(strings.errorUnexpected),
          ),
          data: (p) => ListView(
            padding: const EdgeInsets.all(AmTokens.spaceMd),
            children: [
              // Digital Health ID Pass
              _HealthIdCard(patient: p, user: profile),
              const SizedBox(height: AmTokens.spaceLg),

              // Personal Information Section
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
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
                          Text(
                            isTamil ? 'தனிநபர் விவரங்கள்' : 'Personal Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _openEditDialog(context, p),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: Text(isTamil ? 'மாற்று' : 'Edit'),
                          ),
                        ],
                      ),
                      const Divider(),
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: isTamil ? 'முழு பெயர்' : 'Full Name',
                        value: p?.fullName ?? profile?.fullName ?? 'Not set',
                      ),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: isTamil ? 'கைபேசி எண்' : 'Phone Number',
                        value: p?.contactPhone ?? profile?.phone ?? '9876500002',
                      ),
                      _InfoRow(
                        icon: Icons.cake_outlined,
                        label: isTamil ? 'வயது / பாலினம்' : 'Age & Gender',
                        value: '${p?.ageYears ?? 28} Yrs • ${_sexLabel(p?.sex, isTamil)}',
                      ),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: isTamil ? 'மாவட்டம்' : 'District',
                        value: 'Tiruvannamalai, Tamil Nadu',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AmTokens.spaceMd),

              // Medical & Risk Profile Section
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AmTokens.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTamil ? 'மருத்துவக் குறிப்புகள் & நோய்கள்' : 'Clinical & Risk Profile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AmTokens.spaceSm),
                      Text(
                        isTamil
                            ? 'அவசர சிகிச்சை மற்றும் பரிந்துரைக்கு இந்த விவரங்கள் பயன்படும்.'
                            : 'Used by the clinical triage rule set to evaluate urgency.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AmTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AmTokens.spaceMd),
                      if (p?.isPregnant ?? false)
                        Container(
                          margin: const EdgeInsets.only(bottom: AmTokens.spaceSm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AmTokens.spaceSm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(AmTokens.radiusSmall),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pregnant_woman, size: 16, color: Colors.purple.shade800),
                              const SizedBox(width: 4),
                              Text(
                                isTamil ? 'கர்ப்பிணி' : 'Pregnant',
                                style: TextStyle(
                                  color: Colors.purple.shade900,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (p?.chronicConditions.isNotEmpty ?? false)
                            ? p!.chronicConditions
                                .map(
                                  (cond) => Chip(
                                    label: Text(_conditionName(cond, isTamil)),
                                    backgroundColor: const Color(0x1A0F6E63),
                                    side: const BorderSide(color: Color(0x4D0F6E63)),
                                  ),
                                )
                                .toList()
                            : [
                                Chip(
                                  label: Text(
                                    isTamil ? 'நீடித்த நோய்கள் எதுவும் இல்லை' : 'No chronic conditions reported',
                                  ),
                                  backgroundColor: Colors.green.shade50,
                                  side: BorderSide(color: Colors.green.shade200),
                                ),
                              ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AmTokens.spaceMd),

              // Preferences & Language
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.translate, color: AmTokens.primary),
                      title: Text(isTamil ? 'செயலி மொழி' : 'App Language'),
                      subtitle: Text(isTamil ? 'தமிழ் (செயலில் உள்ளது)' : 'English (Active)'),
                      trailing: FilledButton.tonal(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                        onPressed: () {
                          final next = isTamil ? AmLocales.english : AmLocales.tamil;
                          ref.read(localeControllerProvider.notifier).choose(next);
                        },
                        child: Text(isTamil ? 'Switch to English' : 'தமிழுக்கு மாறு'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined, color: AmTokens.primary),
                      title: Text(isTamil ? 'அறிவிப்புகள்' : 'Care Notifications'),
                      subtitle: Text(
                        isTamil
                            ? 'பரிந்துரை மற்றும் மருத்துவ நினைவூட்டல்கள் இயக்கம்'
                            : 'SMS and push updates for care tracking',
                      ),
                      trailing: Switch(
                        value: true,
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AmTokens.spaceXl),
            ],
          ),
        ),
      ),
    );
  }

  String _sexLabel(Sex? sex, bool isTamil) {
    return switch (sex) {
      Sex.female => isTamil ? 'பெண்' : 'Female',
      Sex.male => isTamil ? 'ஆண்' : 'Male',
      Sex.other => isTamil ? 'மற்றவை' : 'Other',
      _ => isTamil ? 'குறிப்பிடப்படவில்லை' : 'Undisclosed',
    };
  }

  String _conditionName(String key, bool isTamil) {
    return switch (key) {
      'diabetes' => isTamil ? 'நீரிழிவு (Diabetes)' : 'Diabetes',
      'hypertension' => isTamil ? 'இரத்த அழுத்தம் (BP)' : 'Hypertension',
      'heart_disease' => isTamil ? 'இதய நோய்' : 'Heart Disease',
      'asthma' => isTamil ? 'ஆஸ்துமா' : 'Asthma',
      'kidney_disease' => isTamil ? 'சிறுநீரக நோய்' : 'Kidney Disease',
      'tuberculosis' => isTamil ? 'காசநோய்' : 'Tuberculosis',
      _ => key,
    };
  }

  Future<void> _openEditDialog(BuildContext context, Patient? patient) async {
    final messenger = ScaffoldMessenger.of(context);
    final isTamil = ref.read(localeControllerProvider)?.languageCode == 'ta';
    final nameCtrl = TextEditingController(text: patient?.fullName ?? '');
    final ageCtrl = TextEditingController(text: '${patient?.ageYears ?? 28}');
    final phoneCtrl = TextEditingController(text: patient?.contactPhone ?? '');
    Sex selectedSex = patient?.sex ?? Sex.female;
    final chronic = Set<String>.from(patient?.chronicConditions ?? ['diabetes']);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AmTokens.radiusLarge)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
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
                isTamil ? 'சுயவிவரத்தைத் திருத்துக' : 'Edit Profile Details',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AmTokens.spaceMd),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: isTamil ? 'முழு பெயர்' : 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: AmTokens.spaceSm),
              TextField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isTamil ? 'வயது' : 'Age',
                  prefixIcon: const Icon(Icons.cake),
                ),
              ),
              const SizedBox(height: AmTokens.spaceSm),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isTamil ? 'கைபேசி எண்' : 'Contact Phone',
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: AmTokens.spaceMd),
              Text(
                isTamil ? 'நீடித்த நோய்கள் (Chronic Conditions)' : 'Chronic Conditions',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AmTokens.spaceSm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  'diabetes',
                  'hypertension',
                  'heart_disease',
                  'asthma',
                  'kidney_disease',
                ].map((c) {
                  final has = chronic.contains(c);
                  return FilterChip(
                    label: Text(_conditionName(c, isTamil)),
                    selected: has,
                    onSelected: (val) {
                      setDialogState(() {
                        if (val) {
                          chronic.add(c);
                        } else {
                          chronic.remove(c);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AmTokens.spaceLg),
              FilledButton(
                onPressed: _isUpdating
                    ? null
                    : () async {
                        Navigator.of(ctx).pop();
                        setState(() => _isUpdating = true);
                        if (patient != null) {
                          final updated = Patient(
                            id: patient.id,
                            fullName: nameCtrl.text.trim().isEmpty ? patient.fullName : nameCtrl.text.trim(),
                            sex: selectedSex,
                            ageYears: int.tryParse(ageCtrl.text) ?? patient.ageYears,
                            contactPhone: phoneCtrl.text.trim().isEmpty ? patient.contactPhone : phoneCtrl.text.trim(),
                            preferredLanguage: patient.preferredLanguage,
                            isPregnant: patient.isPregnant,
                            chronicConditions: chronic.toList(),
                            abhaAddress: patient.abhaAddress,
                          );
                          await ref.read(peopleRepositoryProvider).updatePatient(updated);
                          ref.invalidate(selfPatientProvider);
                        }
                        setState(() => _isUpdating = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isTamil ? 'சுயவிவரம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது' : 'Profile updated successfully!',
                            ),
                          ),
                        );
                      },
                child: Text(isTamil ? 'சேமி' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Digital Health ID badge for the citizen.
class _HealthIdCard extends StatelessWidget {
  const _HealthIdCard({required this.patient, required this.user});

  final Patient? patient;
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = patient?.fullName ?? user?.fullName ?? 'Meena Ravi';
    final abha = patient?.abhaAddress ?? '9876-5000-0002@abdm';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AmTokens.primary,
            Colors.teal.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D0F6E63),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AmTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'ArogyaMitra Health Pass',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(AmTokens.radiusSmall),
                ),
                child: const Text(
                  'GOVT OF TN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AmTokens.spaceLg),
          Text(
            name,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ABHA ID: $abha',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AmTokens.spaceMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PassChip(label: 'AGE', value: '${patient?.ageYears ?? 28} YRS'),
              _PassChip(label: 'GENDER', value: patient?.sex != null ? patient!.sex.name.toUpperCase() : 'FEMALE'),
              _PassChip(label: 'BLOOD', value: 'O+ POSITIVE'),
              _PassChip(label: 'DISTRICT', value: 'TVM-33'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassChip extends StatelessWidget {
  const _PassChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AmTokens.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: AmTokens.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
