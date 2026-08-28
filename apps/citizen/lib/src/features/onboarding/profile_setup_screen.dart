import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../triage/care_journey_controller.dart';
import '../triage/symptom_screen.dart';

/// Collects the minimum triage needs to judge risk correctly.
///
/// Age, pregnancy status and long-term conditions are not optional extras: the
/// rule set uses them to decide whether a symptom is routine or an emergency,
/// so the screen explains why it is asking (PRD 6 FR-004).
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  Sex _sex = Sex.undisclosed;
  bool _isPregnant = false;
  final Set<String> _chronic = {};
  bool _isBusy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);

    final chronicOptions = <String, String>{
      'diabetes': strings.chronicDiabetes,
      'hypertension': strings.chronicHypertension,
      'heart_disease': strings.chronicHeartDisease,
      'asthma': strings.chronicAsthma,
      'kidney_disease': strings.chronicKidneyDisease,
      'tuberculosis': strings.chronicTuberculosis,
    };

    return Scaffold(
      appBar: AppBar(title: Text(strings.profileTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AmTokens.spaceMd),
            children: [
              AmBanner.info(message: strings.profileWhy),
              const SizedBox(height: AmTokens.spaceLg),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: strings.profileName),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? strings.errorInvalidInput
                    : null,
              ),
              const SizedBox(height: AmTokens.spaceMd),

              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(labelText: strings.profileAge),
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (age == null || age < 0 || age > 130) {
                    return strings.errorInvalidInput;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AmTokens.spaceLg),

              Text(strings.profileSex, style: theme.textTheme.titleMedium),
              const SizedBox(height: AmTokens.spaceSm),
              for (final option in Sex.values) ...[
                AmRadioTile<Sex>(
                  label: _sexLabel(option, strings),
                  value: option,
                  groupValue: _sex,
                  onChanged: (value) => setState(() {
                    _sex = value;
                    if (value != Sex.female) _isPregnant = false;
                  }),
                ),
                const SizedBox(height: AmTokens.spaceSm),
              ],

              if (_sex == Sex.female) ...[
                const SizedBox(height: AmTokens.spaceSm),
                AmChoiceTile(
                  label: strings.profilePregnant,
                  isSelected: _isPregnant,
                  onTap: () => setState(() => _isPregnant = !_isPregnant),
                ),
              ],

              const SizedBox(height: AmTokens.spaceLg),
              Text(strings.profileChronic, style: theme.textTheme.titleMedium),
              const SizedBox(height: AmTokens.spaceSm),
              for (final entry in chronicOptions.entries) ...[
                AmChoiceTile(
                  label: entry.value,
                  isSelected: _chronic.contains(entry.key),
                  onTap: () => setState(() {
                    if (!_chronic.remove(entry.key)) _chronic.add(entry.key);
                  }),
                ),
                const SizedBox(height: AmTokens.spaceSm),
              ],

              const SizedBox(height: AmTokens.spaceLg),
              AmBigButton(
                label: strings.actionContinue,
                icon: Icons.arrow_forward,
                isBusy: _isBusy,
                onPressed: _isBusy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sexLabel(Sex sex, AmStrings strings) => switch (sex) {
        Sex.male => strings.sexMale,
        Sex.female => strings.sexFemale,
        Sex.other => strings.sexOther,
        Sex.undisclosed => strings.sexUndisclosed,
      };

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isBusy = true);

    final result = await ref.read(peopleRepositoryProvider).registerSelf(
          fullName: _nameController.text.trim(),
          sex: _sex,
          ageYears: int.parse(_ageController.text),
          language: ref.read(activeLanguageProvider),
          isPregnant: _isPregnant,
          chronicConditions: _chronic.toList(),
        );

    if (!mounted) return;
    setState(() => _isBusy = false);

    result.fold(
      onSuccess: (_) {
        ref.invalidate(selfPatientProvider);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const SymptomScreen()),
        );
      },
      onFailure: (failure) => showAmFailureSnackBar(context, failure),
    );
  }
}
