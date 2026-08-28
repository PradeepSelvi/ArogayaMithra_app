import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';

/// Citizen feedback (PRD 5.1, FR-012).
///
/// The supply-side categories are first-class options rather than buried in a
/// comment box: "medicines not available" needs to reach the facility and the DHO
/// as a structured alert, which only happens if the citizen can select it.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({
    this.referralId,
    this.facilityId,
    this.patientId,
    super.key,
  });

  final String? referralId;
  final String? facilityId;
  final String? patientId;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;
  FeedbackCategory _category = FeedbackCategory.general;
  bool? _wouldRecommend;
  bool _isBusy = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.feedbackTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          children: [
            Text(strings.feedbackRating, style: theme.textTheme.titleMedium),
            const SizedBox(height: AmTokens.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    iconSize: 44,
                    tooltip: '$star',
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      color: star <= _rating
                          ? AmTokens.warning
                          : AmTokens.textSecondary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AmTokens.spaceLg),
            Text(strings.feedbackCategory, style: theme.textTheme.titleMedium),
            const SizedBox(height: AmTokens.spaceSm),
            for (final category in FeedbackCategory.values) ...[
              AmRadioTile<FeedbackCategory>(
                label: _categoryLabel(category, strings),
                value: category,
                groupValue: _category,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: AmTokens.spaceSm),
            ],

            const SizedBox(height: AmTokens.spaceLg),
            Text(
              strings.feedbackWouldRecommend,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AmTokens.spaceSm),
            Row(
              children: [
                Expanded(
                  child: AmRadioTile<bool>(
                    label: strings.actionYes,
                    value: true,
                    groupValue: _wouldRecommend,
                    onChanged: (value) => setState(() => _wouldRecommend = value),
                  ),
                ),
                const SizedBox(width: AmTokens.spaceSm),
                Expanded(
                  child: AmRadioTile<bool>(
                    label: strings.actionNo,
                    value: false,
                    groupValue: _wouldRecommend,
                    onChanged: (value) => setState(() => _wouldRecommend = value),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AmTokens.spaceLg),
            TextField(
              controller: _commentController,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              decoration: InputDecoration(labelText: strings.feedbackComment),
            ),

            const SizedBox(height: AmTokens.spaceLg),
            AmBigButton(
              label: strings.actionSubmit,
              icon: Icons.send_outlined,
              isBusy: _isBusy,
              onPressed: _rating == 0 || _isBusy ? null : _submit,
            ),
            const SizedBox(height: AmTokens.spaceXl),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(FeedbackCategory category, AmStrings strings) =>
      switch (category) {
        FeedbackCategory.general => strings.feedbackCategoryGeneral,
        FeedbackCategory.waitingTime => strings.feedbackCategoryWaitingTime,
        FeedbackCategory.staffBehaviour => strings.feedbackCategoryStaffBehaviour,
        FeedbackCategory.medicineUnavailable =>
          strings.feedbackCategoryMedicineUnavailable,
        FeedbackCategory.diagnosticUnavailable =>
          strings.feedbackCategoryDiagnosticUnavailable,
        FeedbackCategory.cleanliness => strings.feedbackCategoryCleanliness,
        FeedbackCategory.cost => strings.feedbackCategoryCost,
        FeedbackCategory.referralProcess =>
          strings.feedbackCategoryReferralProcess,
        FeedbackCategory.ambulance => strings.feedbackCategoryAmbulance,
        FeedbackCategory.teleconsult => strings.feedbackCategoryTeleconsult,
        FeedbackCategory.other => strings.feedbackCategoryOther,
      };

  Future<void> _submit() async {
    setState(() => _isBusy = true);

    final result = await ref.read(engagementRepositoryProvider).submitFeedback(
          FeedbackDraft(
            rating: _rating,
            category: _category,
            language: ref.read(activeLanguageProvider),
            patientId: widget.patientId,
            facilityId: widget.facilityId,
            referralId: widget.referralId,
            comment: _commentController.text,
            wouldRecommend: _wouldRecommend,
          ),
        );

    if (!mounted) return;
    setState(() => _isBusy = false);

    final strings = AmStrings.of(context);

    result.fold(
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.feedbackThanks)),
        );
        Navigator.of(context).pop();
      },
      onFailure: (failure) => showAmFailureSnackBar(context, failure),
    );
  }
}
