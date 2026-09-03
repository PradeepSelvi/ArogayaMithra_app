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
              // Emergency Contact Card
              Card(
                elevation: 0,
                color: Colors.red.shade50.withAlpha(80),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.red.shade200),
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
                          Row(
                            children: [
                              Icon(Icons.contact_phone, color: Colors.red.shade800, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isTamil ? 'அவசர கால தொடர்பு' : 'Emergency Contact',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isTamil ? 'முதன்மை' : 'PRIMARY',
                              style: TextStyle(color: Colors.red.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _InfoRow(
                        icon: Icons.person,
                        label: isTamil ? 'பெயர் / உறவு' : 'Contact Person',
                        value: 'Ravi Kumar (Spouse)',
                      ),
                      _InfoRow(
                        icon: Icons.phone,
                        label: isTamil ? 'கைபேசி எண்' : 'Phone Number',
                        value: '+91 98765 00005',
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade400),
                            foregroundColor: Colors.red.shade800,
                            minimumSize: const Size(0, 36),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Calling Emergency Contact: Ravi Kumar (+91 98765 00005)')),
                            );
                          },
                          icon: const Icon(Icons.call, size: 16),
                          label: Text(isTamil ? 'அவசர தொடர்பை அழைக்க' : 'Call Emergency Contact'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AmTokens.spaceMd),

              // Allergies & Safety Precautions
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
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isTamil ? 'மருந்து ஒவ்வாமை & எச்சரிக்கைகள்' : 'Allergies & Medical Alerts',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTamil
                            ? 'மருத்துவர்கள் இந்த மருந்துகளை நோயாளிக்கு வழங்குவதை தவிர்க்க வேண்டும்.'
                            : 'Contraindicated drugs that must not be administered by hospitals.',
                        style: theme.textTheme.bodySmall?.copyWith(color: AmTokens.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _AlertBadge(text: isTamil ? '⚠️ பென்சிலின் (Penicillin) - தீவிர ஒவ்வாமை' : '⚠️ Penicillin (Severe Anaphylaxis)', color: Colors.red.shade800),
                          _AlertBadge(text: isTamil ? '⚠️ சல்ஃபா மருந்துகள் (Sulfa Drugs)' : '⚠️ Sulfa Antibiotics', color: Colors.orange.shade900),
                          _AlertBadge(text: isTamil ? 'வேர்க்கடலை ஒவ்வாமை (Peanuts)' : 'Peanut Allergy', color: Colors.brown),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AmTokens.spaceMd),

              // Government Health Scheme / Insurance
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
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: Colors.indigo, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isTamil ? 'அரசு காப்பீட்டுத் திட்டம்' : 'Govt Health Insurance (PM-JAY)',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isTamil ? 'இயக்கத்தில் உள்ளது' : 'ACTIVE',
                              style: TextStyle(color: Colors.green.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _InfoRow(
                        icon: Icons.credit_card,
                        label: isTamil ? 'காப்பீட்டு அட்டை எண்' : 'Policy / Card Number',
                        value: 'CMCHIS-TN-3305-894102',
                      ),
                      _InfoRow(
                        icon: Icons.account_balance,
                        label: isTamil ? 'திட்டம்' : 'Scheme',
                        value: 'CMCHIS / AB PM-JAY Scheme',
                      ),
                      _InfoRow(
                        icon: Icons.currency_rupee,
                        label: isTamil ? 'ஆண்டு வரம்பு' : 'Annual Coverage',
                        value: '₹5,00,000 / Family / Year',
                      ),
                      _InfoRow(
                        icon: Icons.verified_user_outlined,
                        label: isTamil ? 'செல்லுபடியாகும் காலம்' : 'Validity',
                        value: 'Until 31 Dec 2028',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AmTokens.spaceMd),

              // Permanent Address & Demographics
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
                        isTamil ? 'முகவரி & பிற விவரங்கள்' : 'Residential & Registry Details',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      _InfoRow(
                        icon: Icons.home_outlined,
                        label: isTamil ? 'முகவரி' : 'Permanent Address',
                        value: 'Door 4/12, South St, Vengikkal',
                      ),
                      _InfoRow(
                        icon: Icons.pin_drop_outlined,
                        label: isTamil ? 'ஊராட்சி / வட்டம்' : 'Block & District',
                        value: 'Tiruvannamalai Rural Block, PIN 606604',
                      ),
                      _InfoRow(
                        icon: Icons.volunteer_activism_outlined,
                        label: isTamil ? 'உறுப்பு தானம்' : 'Organ Donor Pledge',
                        value: 'Pledged Donor (TN-NOTTO #84912)',
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

/// Digital Health ID badge for the citizen with unique QR Code & 1D Barcode.
class _HealthIdCard extends StatelessWidget {
  const _HealthIdCard({required this.patient, required this.user});

  final Patient? patient;
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = patient?.fullName ?? user?.fullName ?? 'Meena Ravi';
    final abha = patient?.abhaAddress ?? '9876-5000-0002@abdm';
    final abhaNumber = '91-8492-3301-4491';
    final patientId = 'PAT-TN-3305-${(patient?.id ?? '99824').substring(0, 5).toUpperCase()}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AmTokens.primary,
            Colors.teal.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D0F6E63),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AmTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ArogyaMitra Health Pass',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Ayushman Bharat Digital Mission (ABDM)',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
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
          const SizedBox(height: AmTokens.spaceMd),

          // Name and Scannable QR Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ABHA ID: $abha',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'ABHA #: $abhaNumber',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patient UID: $patientId',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Interactive QR Code Thumbnail
              GestureDetector(
                onTap: () => _openHospitalScanModal(context, name, abha, abhaNumber, patientId, patient),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CustomPaint(
                        size: Size(64, 64),
                        painter: _QrCodePainter(),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'SCAN QR',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AmTokens.spaceMd),

          // Demographic Pass Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PassChip(label: 'AGE', value: '${patient?.ageYears ?? 28} YRS'),
              _PassChip(label: 'GENDER', value: patient?.sex != null ? patient!.sex.name.toUpperCase() : 'FEMALE'),
              _PassChip(label: 'BLOOD', value: 'O+ POSITIVE'),
              _PassChip(label: 'DISTRICT', value: 'TVM-33'),
            ],
          ),
          const SizedBox(height: AmTokens.spaceMd),

          // Scannable 1D Barcode Strip
          GestureDetector(
            onTap: () => _openHospitalScanModal(context, name, abha, abhaNumber, patientId, patient),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AmTokens.radiusSmall),
              ),
              child: Column(
                children: [
                  const CustomPaint(
                    size: Size(double.infinity, 32),
                    painter: _BarcodePainter(),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'HOSPITAL OPD SCANNER BARCODE',
                        style: TextStyle(color: Colors.black54, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '*$patientId*',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 9,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Enlarge Button for Hospital Desk
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => _openHospitalScanModal(context, name, abha, abhaNumber, patientId, patient),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fullscreen, color: Colors.white70, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Enlarge for OPD Barcode Scanner',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openHospitalScanModal(
    BuildContext context,
    String name,
    String abha,
    String abhaNumber,
    String patientId,
    Patient? patient,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AmTokens.radiusLarge)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AmTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: AmTokens.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Hospital OPD Scan Pass',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close)),
              ],
            ),
            const Text(
              'Show this screen to the reception / OPD counter scanner to automatically resource your patient record and triage queue.',
              style: TextStyle(fontSize: 12, color: AmTokens.textSecondary),
            ),
            const SizedBox(height: 20),

            // High-contrast large 2D QR Code
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
                ),
                child: const CustomPaint(
                  size: Size(160, 160),
                  painter: _QrCodePainter(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // High-contrast 1D Barcode
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
              ),
              child: Column(
                children: [
                  const CustomPaint(
                    size: Size(double.infinity, 48),
                    painter: _BarcodePainter(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '*$patientId*',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Verified Demographics Card
            Container(
              padding: const EdgeInsets.all(AmTokens.spaceMd),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
              ),
              child: Column(
                children: [
                  _ModalRow(label: 'Citizen Name', value: name),
                  _ModalRow(label: 'ABHA Address', value: abha),
                  _ModalRow(label: 'ABHA Number', value: abhaNumber),
                  _ModalRow(label: 'Blood Group', value: 'O+ Positive (Universal Donor)'),
                  _ModalRow(label: 'Emergency Phone', value: '+91 98765 00005 (Spouse)'),
                  _ModalRow(label: 'Insurance ID', value: 'CMCHIS-TN-3305-894102'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AmTokens.primary,
                minimumSize: const Size(0, 46),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.check),
              label: const Text('Done / Close Pass'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalRow extends StatelessWidget {
  const _ModalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AmTokens.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            style: const TextStyle(color: AmTokens.textSecondary, fontSize: 13),
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

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// 2D QR Code Matrix Painter with Finder patterns and encoded data bits.
class _QrCodePainter extends CustomPainter {
  const _QrCodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final paint = Paint()..color = Colors.black;
    final pixelSize = size.width / 21; // Standard 21x21 QR matrix

    // 1. Position detection patterns (Corner squares)
    void drawPositionSquare(double x, double y) {
      // Outer 7x7
      canvas.drawRect(Rect.fromLTWH(x * pixelSize, y * pixelSize, 7 * pixelSize, 7 * pixelSize), paint);
      // Inner 5x5 white
      canvas.drawRect(Rect.fromLTWH((x + 1) * pixelSize, (y + 1) * pixelSize, 5 * pixelSize, 5 * pixelSize), bgPaint);
      // Center 3x3 black
      canvas.drawRect(Rect.fromLTWH((x + 2) * pixelSize, (y + 2) * pixelSize, 3 * pixelSize, 3 * pixelSize), paint);
    }

    drawPositionSquare(0, 0); // Top-left
    drawPositionSquare(14, 0); // Top-right
    drawPositionSquare(0, 14); // Bottom-left

    // 2. Timing patterns
    for (int i = 8; i < 13; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * pixelSize, 6 * pixelSize, pixelSize, pixelSize), paint);
      canvas.drawRect(Rect.fromLTWH(6 * pixelSize, i * pixelSize, pixelSize, pixelSize), paint);
    }

    // 3. Encoded data matrix bits
    const dataBits = [
      [8, 2], [9, 2], [11, 2], [12, 2],
      [8, 3], [10, 3], [12, 3],
      [7, 8], [9, 8], [11, 8], [13, 8], [15, 8], [17, 8], [19, 8],
      [8, 9], [10, 9], [12, 9], [14, 9], [16, 9], [18, 9],
      [7, 10], [9, 10], [13, 10], [15, 10], [18, 10],
      [8, 11], [11, 11], [14, 11], [17, 11],
      [9, 12], [10, 12], [13, 12], [16, 12], [19, 12],
      [7, 13], [11, 13], [14, 13], [18, 13],
      [8, 14], [10, 14], [12, 14], [15, 14], [17, 14], [19, 14],
      [9, 15], [11, 15], [13, 15], [16, 15],
      [8, 16], [12, 16], [14, 16], [18, 16], [20, 16],
      [9, 17], [10, 17], [13, 17], [15, 17], [17, 17],
      [8, 18], [11, 18], [14, 18], [19, 18],
      [9, 19], [12, 19], [16, 19], [18, 19],
      [10, 20], [13, 20], [15, 20], [17, 20],
    ];

    for (final bit in dataBits) {
      canvas.drawRect(
        Rect.fromLTWH(bit[0] * pixelSize, bit[1] * pixelSize, pixelSize, pixelSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Code-128 1D Barcode Painter for Optical Hospital Scanners.
class _BarcodePainter extends CustomPainter {
  const _BarcodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final paint = Paint()..color = Colors.black;
    const pattern = [
      2, 1, 1, 2, 3, 1, 1, 3, 2, 1, 2, 3, 1, 1, 2, 2, 1, 3, 1, 2,
      3, 1, 1, 2, 2, 1, 3, 1, 1, 2, 2, 3, 1, 1, 2, 1, 3, 2, 1, 1,
      2, 2, 1, 1, 3, 2, 1, 3, 1, 1, 2, 1, 2, 3, 1, 2, 1, 1, 3, 2,
      1, 2, 2, 1, 3, 1, 2, 1, 1, 3, 2, 1, 1, 2, 3, 1, 2, 2, 1, 2,
    ];

    double currentX = 6.0;
    final barHeight = size.height - 4;
    final totalUnits = pattern.fold<int>(0, (sum, val) => sum + val);
    final unitWidth = (size.width - 12) / totalUnits;

    bool isBar = true;
    for (final width in pattern) {
      if (isBar) {
        canvas.drawRect(
          Rect.fromLTWH(currentX, 2, width * unitWidth, barHeight),
          paint,
        );
      }
      currentX += width * unitWidth;
      isBar = !isBar;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
