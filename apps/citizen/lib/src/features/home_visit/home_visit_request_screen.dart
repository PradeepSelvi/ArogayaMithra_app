import 'package:am_maps/am_maps.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../language/locale_controller.dart';

enum VisitReason { general, wound, chronic, maternal, elderly, other }

enum VisitUrgency { routine, priority, urgent }

enum VisitStatus { requested, assigned, onTheWay, arrived }

/// Lets a citizen ask an ASHA worker or medical volunteer to visit them at
/// home, for citizens who cannot travel to a facility easily.
class HomeVisitRequestScreen extends ConsumerStatefulWidget {
  const HomeVisitRequestScreen({super.key});

  @override
  ConsumerState<HomeVisitRequestScreen> createState() => _HomeVisitRequestScreenState();
}

class _HomeVisitRequestScreenState extends ConsumerState<HomeVisitRequestScreen> {
  final _notesController = TextEditingController();
  final _addressController = TextEditingController(text: 'Door 4/12, South St, Vengikkal, Tiruvannamalai');

  VisitReason? _reason;
  VisitUrgency _urgency = VisitUrgency.routine;
  DateTime? _preferredDate;
  String? _preferredSlot;
  bool _isSubmitting = false;
  bool _submitted = false;
  VisitStatus _status = VisitStatus.requested;

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _lang() => ref.read(localeControllerProvider)?.languageCode ?? 'en';

  Future<void> _submit() async {
    if (_reason == null || _preferredDate == null || _preferredSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (_lang()) {
            'ta' => 'தொடர தேதி, நேரம் மற்றும் காரணத்தைத் தேர்ந்தெடுக்கவும்.',
            'hi' => 'जारी रखने के लिए तारीख, समय और कारण चुनें।',
            _ => 'Choose a reason, date and time slot to continue.',
          }),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _submitted = true;
      _status = VisitStatus.requested;
    });

    // Simulate the ASHA worker accepting the request shortly after.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _status = VisitStatus.assigned);
    });
  }

  void _cancelRequest() {
    setState(() {
      _submitted = false;
      _status = VisitStatus.requested;
      _reason = null;
      _preferredDate = null;
      _preferredSlot = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeControllerProvider)?.languageCode ?? 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (lang) {
          'ta' => 'வீட்டு வருகை கோரிக்கை',
          'hi' => 'घर विज़िट अनुरोध',
          _ => 'Request a Home Visit',
        }),
      ),
      body: SafeArea(
        child: _submitted ? _buildTracking(lang) : _buildForm(lang),
      ),
    );
  }

  Widget _buildForm(String lang) {
    return ListView(
      padding: const EdgeInsets.all(AmTokens.spaceMd),
      children: [
        Container(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          decoration: BoxDecoration(
            color: AmTokens.primaryLight,
            borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
          ),
          child: Row(
            children: [
              const Icon(Icons.house_outlined, color: AmTokens.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  switch (lang) {
                    'ta' => 'நடக்க முடியாதவர்களுக்கு ஆஷா பணியாளர் அல்லது மருத்துவ தொண்டர் வீட்டிற்கே வருவார்கள்.',
                    'hi' => 'जो चल-फिर नहीं सकते उनके लिए आशा कार्यकर्ता या स्वास्थ्य स्वयंसेवक आपके घर आएंगे।',
                    _ => 'An ASHA worker or trained medical volunteer will visit your home if you find it hard to travel.',
                  },
                  style: const TextStyle(fontSize: 13, color: AmTokens.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AmTokens.spaceLg),

        Text(
          switch (lang) {
            'ta' => 'வருகைக்கான காரணம்',
            'hi' => 'विज़िट का कारण',
            _ => 'Reason for the visit',
          },
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: AmTokens.spaceSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VisitReason.values.map((reason) {
            return ChoiceChip(
              label: Text(_reasonLabel(reason, lang)),
              selected: _reason == reason,
              onSelected: (_) => setState(() => _reason = reason),
            );
          }).toList(),
        ),
        const SizedBox(height: AmTokens.spaceLg),

        Text(
          switch (lang) {
            'ta' => 'அவசர நிலை',
            'hi' => 'तात्कालिकता',
            _ => 'How urgent is this?',
          },
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: AmTokens.spaceSm),
        Row(
          children: VisitUrgency.values.map((urgency) {
            final selected = _urgency == urgency;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected ? _urgencyColor(urgency).withAlpha(30) : null,
                    side: BorderSide(color: selected ? _urgencyColor(urgency) : Colors.grey.shade300),
                    foregroundColor: _urgencyColor(urgency),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => setState(() => _urgency = urgency),
                  child: Text(_urgencyLabel(urgency, lang), style: const TextStyle(fontSize: 12)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AmTokens.spaceLg),

        Text(
          switch (lang) {
            'ta' => 'விருப்பமான தேதி & நேரம்',
            'hi' => 'पसंदीदा तारीख और समय',
            _ => 'Preferred date & time',
          },
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: AmTokens.spaceSm),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            minimumSize: const Size(double.infinity, 44),
          ),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: now,
              firstDate: now,
              lastDate: now.add(const Duration(days: 14)),
            );
            if (picked != null) setState(() => _preferredDate = picked);
          },
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(
            _preferredDate == null
                ? switch (lang) {
                    'ta' => 'தேதியைத் தேர்ந்தெடுக்கவும்',
                    'hi' => 'तारीख चुनें',
                    _ => 'Choose a date',
                  }
                : '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}',
          ),
        ),
        const SizedBox(height: AmTokens.spaceSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['morning', 'afternoon', 'evening'].map((slot) {
            return ChoiceChip(
              label: Text(_slotLabel(slot, lang)),
              selected: _preferredSlot == slot,
              onSelected: (_) => setState(() => _preferredSlot = slot),
            );
          }).toList(),
        ),
        const SizedBox(height: AmTokens.spaceLg),

        Text(
          switch (lang) {
            'ta' => 'முகவரி',
            'hi' => 'पता',
            _ => 'Address',
          },
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: AmTokens.spaceSm),
        TextField(
          controller: _addressController,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: AmTokens.spaceLg),

        Text(
          switch (lang) {
            'ta' => 'கூடுதல் குறிப்புகள் (விருப்பம்)',
            'hi' => 'अतिरिक्त टिप्पणियाँ (वैकल्पिक)',
            _ => 'Additional notes (optional)',
          },
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: AmTokens.spaceSm),
        TextField(
          controller: _notesController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: switch (lang) {
              'ta' => 'எ.கா. படுக்கையில் இருந்து நகர முடியாது...',
              'hi' => 'जैसे बिस्तर से उठ नहीं सकते...',
              _ => 'e.g. bedridden, needs wound dressing change...',
            },
          ),
        ),
        const SizedBox(height: AmTokens.spaceXl),

        AmBigButton(
          label: switch (lang) {
            'ta' => 'கோரிக்கையை அனுப்பு',
            'hi' => 'अनुरोध भेजें',
            _ => 'Send Request',
          },
          icon: Icons.send,
          isBusy: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
        const SizedBox(height: AmTokens.spaceXl),
      ],
    );
  }

  Widget _buildTracking(String lang) {
    return ListView(
      padding: const EdgeInsets.all(AmTokens.spaceMd),
      children: [
        Container(
          padding: const EdgeInsets.all(AmTokens.spaceLg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AmTokens.primary, Color(0xFF004D40)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                switch (_status) {
                  VisitStatus.requested => switch (lang) {
                      'ta' => 'கோரிக்கை அனுப்பப்பட்டது',
                      'hi' => 'अनुरोध भेजा गया',
                      _ => 'Request Sent',
                    },
                  VisitStatus.assigned => switch (lang) {
                      'ta' => 'ஆஷா பணியாளர் ஒதுக்கப்பட்டார்',
                      'hi' => 'आशा कार्यकर्ता नियुक्त',
                      _ => 'ASHA Worker Assigned',
                    },
                  VisitStatus.onTheWay => switch (lang) {
                      'ta' => 'வழியில் உள்ளார்',
                      'hi' => 'रास्ते में हैं',
                      _ => 'On the Way',
                    },
                  VisitStatus.arrived => switch (lang) {
                      'ta' => 'வந்துவிட்டார்',
                      'hi' => 'पहुँच गए',
                      _ => 'Arrived',
                    },
                },
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                switch (lang) {
                  'ta' => 'உங்கள் வீட்டு வருகை கோரிக்கை செயலில் உள்ளது',
                  'hi' => 'आपका घर विज़िट अनुरोध सक्रिय है',
                  _ => 'Your home visit request is active',
                },
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: AmTokens.spaceMd),

        if (_status != VisitStatus.requested)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AmTokens.border),
              borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AmTokens.spaceMd),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AmTokens.primaryLight,
                    child: Icon(Icons.volunteer_activism, color: AmTokens.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lakshmi Devi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          switch (lang) {
                            'ta' => 'ஆஷா பணியாளர் • வெங்கிக்கல் PHC',
                            'hi' => 'आशा कार्यकर्ता • वेंगिक्कल PHC',
                            _ => 'ASHA Worker • Vengikkal PHC',
                          },
                          style: const TextStyle(color: AmTokens.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => ref.read(directionsLauncherProvider).call('9876512345'),
                    icon: const Icon(Icons.call),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AmTokens.spaceMd),

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
                Text(
                  switch (lang) {
                    'ta' => 'வருகை விவரங்கள்',
                    'hi' => 'विज़िट विवरण',
                    _ => 'Visit Details',
                  },
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Divider(),
                _detailRow(
                  Icons.medical_information_outlined,
                  switch (lang) {
                    'ta' => 'காரணம்',
                    'hi' => 'कारण',
                    _ => 'Reason',
                  },
                  _reason != null ? _reasonLabel(_reason!, lang) : '-',
                ),
                _detailRow(
                  Icons.priority_high,
                  switch (lang) {
                    'ta' => 'அவசரம்',
                    'hi' => 'तात्कालिकता',
                    _ => 'Urgency',
                  },
                  _urgencyLabel(_urgency, lang),
                ),
                _detailRow(
                  Icons.calendar_today_outlined,
                  switch (lang) {
                    'ta' => 'தேதி',
                    'hi' => 'तारीख',
                    _ => 'Date',
                  },
                  _preferredDate != null
                      ? '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year} (${_slotLabel(_preferredSlot ?? '', lang)})'
                      : '-',
                ),
                _detailRow(
                  Icons.location_on_outlined,
                  switch (lang) {
                    'ta' => 'முகவரி',
                    'hi' => 'पता',
                    _ => 'Address',
                  },
                  _addressController.text,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AmTokens.spaceLg),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.shade300),
              foregroundColor: Colors.red.shade700,
              minimumSize: const Size(0, 44),
            ),
            onPressed: _cancelRequest,
            child: Text(switch (lang) {
              'ta' => 'கோரிக்கையை ரத்து செய்',
              'hi' => 'अनुरोध रद्द करें',
              _ => 'Cancel Request',
            }),
          ),
        ),
        const SizedBox(height: AmTokens.spaceXl),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AmTokens.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: AmTokens.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _urgencyColor(VisitUrgency urgency) => switch (urgency) {
        VisitUrgency.routine => Colors.teal,
        VisitUrgency.priority => Colors.orange.shade800,
        VisitUrgency.urgent => Colors.red.shade700,
      };

  String _urgencyLabel(VisitUrgency urgency, String lang) => switch (urgency) {
        VisitUrgency.routine => switch (lang) {
            'ta' => 'வழக்கமான (3 நாட்களுக்குள்)',
            'hi' => 'सामान्य (3 दिनों में)',
            _ => 'Routine (within 3 days)',
          },
        VisitUrgency.priority => switch (lang) {
            'ta' => 'முன்னுரிமை (24 மணிக்குள்)',
            'hi' => 'प्राथमिकता (24 घंटों में)',
            _ => 'Priority (within 24h)',
          },
        VisitUrgency.urgent => switch (lang) {
            'ta' => 'அவசரம் (இன்று)',
            'hi' => 'तत्काल (आज)',
            _ => 'Urgent (today)',
          },
      };

  String _reasonLabel(VisitReason reason, String lang) => switch (reason) {
        VisitReason.general => switch (lang) {
            'ta' => 'பொது பரிசோதனை',
            'hi' => 'सामान्य जांच',
            _ => 'General Checkup',
          },
        VisitReason.wound => switch (lang) {
            'ta' => 'காயம் பராமரிப்பு',
            'hi' => 'घाव की देखभाल',
            _ => 'Wound Care',
          },
        VisitReason.chronic => switch (lang) {
            'ta' => 'நீடித்த நோய் பின்தொடர்தல்',
            'hi' => 'दीर्घकालिक बीमारी फॉलो-अप',
            _ => 'Chronic Disease Follow-up',
          },
        VisitReason.maternal => switch (lang) {
            'ta' => 'தாய் & குழந்தை பராமரிப்பு',
            'hi' => 'मातृ एवं शिशु देखभाल',
            _ => 'Maternal & Child Care',
          },
        VisitReason.elderly => switch (lang) {
            'ta' => 'முதியோர் பராமரிப்பு',
            'hi' => 'वृद्ध देखभाल',
            _ => 'Elderly Care',
          },
        VisitReason.other => switch (lang) {
            'ta' => 'மற்றவை',
            'hi' => 'अन्य',
            _ => 'Other',
          },
      };

  String _slotLabel(String slot, String lang) => switch (slot) {
        'morning' => switch (lang) {
            'ta' => 'காலை (8-12)',
            'hi' => 'सुबह (8-12)',
            _ => 'Morning (8-12)',
          },
        'afternoon' => switch (lang) {
            'ta' => 'மதியம் (12-4)',
            'hi' => 'दोपहर (12-4)',
            _ => 'Afternoon (12-4)',
          },
        'evening' => switch (lang) {
            'ta' => 'மாலை (4-7)',
            'hi' => 'शाम (4-7)',
            _ => 'Evening (4-7)',
          },
        _ => slot,
      };
}
