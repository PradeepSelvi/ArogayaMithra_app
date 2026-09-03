import 'package:am_maps/am_maps.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../language/locale_controller.dart';

class AmbulanceTrackerScreen extends ConsumerStatefulWidget {
  const AmbulanceTrackerScreen({super.key});

  @override
  ConsumerState<AmbulanceTrackerScreen> createState() => _AmbulanceTrackerScreenState();
}

class _AmbulanceTrackerScreenState extends ConsumerState<AmbulanceTrackerScreen> {
  final int _activeStep = 2; // 0: Logged, 1: Dispatched, 2: En Route, 3: Arrived

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    final isTamil = locale?.languageCode == 'ta';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? '108 ஆம்புலன்ஸ் கண்காணிப்பு' : '108 Ambulance Dispatch Tracker'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          children: [
            // Urgent Emergency Header
            Container(
              padding: const EdgeInsets.all(AmTokens.spaceMd),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
                border: Border.all(color: Colors.red.shade300, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emergency, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'அவசர அழைப்பு செயல்படுத்தப்பட்டது' : '108 EMERGENCY ACTIVE',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Incident #AM-108-84920 • Priority Level 1',
                          style: TextStyle(color: Colors.red.shade800, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(AmTokens.radiusSmall),
                    ),
                    child: Text(
                      isTamil ? 'நேரலை' : 'LIVE',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AmTokens.spaceMd),

            // Live ETA & Vehicle Card
            Container(
              padding: const EdgeInsets.all(AmTokens.spaceLg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade900, Colors.deepOrange.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
                boxShadow: const [
                  BoxShadow(color: Color(0x3D000000), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTamil ? 'வருகை நேரம் (ETA)' : 'ESTIMATED ARRIVAL',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isTamil ? '6 - 8 நிமிடங்கள்' : '6 - 8 Minutes',
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0x33FFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.airport_shuttle, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _VehicleMeta(
                        label: isTamil ? 'வாகன எண்' : 'VEHICLE',
                        value: 'TN-25-G-1082 (ALS)',
                      ),
                      _VehicleMeta(
                        label: isTamil ? 'ஓட்டுநர்' : 'PILOT',
                        value: 'Murugan S.',
                      ),
                      _VehicleMeta(
                        label: isTamil ? 'பயிற்சி பெற்றவர்' : 'PARAMEDIC',
                        value: 'Revathi R. (EMT)',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AmTokens.spaceMd),

            // Action call buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => _callNumber('9876543210'),
                    icon: const Icon(Icons.phone),
                    label: Text(isTamil ? 'ஓட்டுநரை அழைக்க' : 'Call Pilot'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade700),
                      foregroundColor: Colors.red.shade800,
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => _callNumber('108'),
                    icon: const Icon(Icons.support_agent),
                    label: Text(isTamil ? '108 கட்டுப்பாட்டு அறை' : 'Call 108 Room'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AmTokens.spaceLg),

            // Real-Time Dispatch Stepper Card
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
                      isTamil ? 'நேரலை நிகழ்வு நிலவரம்' : 'Live Dispatch Status',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _TrackingStep(
                      stepNumber: '1',
                      title: isTamil ? 'அவசர அழைப்பு பெறப்பட்டது' : 'Emergency Request Triaged',
                      subtitle: isTamil ? '108 கட்டுப்பாட்டு மையம் திருவண்ணாமலை' : 'Tiruvannamalai 108 Emergency Cell',
                      time: '11:42 AM',
                      isCompleted: true,
                    ),
                    _TrackingStep(
                      stepNumber: '2',
                      title: isTamil ? 'ஆம்புலன்ஸ் ஒதுக்கப்பட்டது' : 'Ambulance Unit Assigned',
                      subtitle: 'Base: Chengam Fire & Rescue Station',
                      time: '11:44 AM',
                      isCompleted: true,
                    ),
                    _TrackingStep(
                      stepNumber: '3',
                      title: isTamil ? 'நோயாளி இருப்பிடத்தை நோக்கி பயணத்தில்' : 'Ambulance En Route',
                      subtitle: isTamil ? 'வேகம்: 52 km/h • தூரம்: 3.8 km' : 'Speed: 52 km/h • Distance: 3.8 km',
                      time: '11:45 AM',
                      isCompleted: _activeStep >= 2,
                      isActive: _activeStep == 2,
                    ),
                    _TrackingStep(
                      stepNumber: '4',
                      title: isTamil ? 'இருப்பிடத்தை வந்தடைதல்' : 'Arrival at Patient Site',
                      subtitle: isTamil ? 'உடனடி முதலுதவி & மருத்துவமனை மாற்றம்' : 'First response on scene & transfer',
                      time: 'Expected 11:53 AM',
                      isCompleted: _activeStep >= 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AmTokens.spaceMd),

            // First-Aid While Waiting Guidance
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AmTokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, color: Colors.blue.shade900, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isTamil ? 'ஆம்புலன்ஸ் வரும் வரை செய்ய வேண்டியவை' : 'While Waiting for Ambulance',
                          style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _FirstAidBullet(text: isTamil ? 'நோயாளியை வசதியான நிலையில் படுக்க அல்லது உட்கார வைக்கவும்.' : 'Keep the patient calm and seated in a comfortable upright position.'),
                    _FirstAidBullet(text: isTamil ? 'சுவாசம் தடையின்றி இருப்பதை உறுதி செய்யவும்; காற்றோட்டமான சூழலை உருவாக்கவும்.' : 'Ensure clear airways; keep the surrounding well-ventilated.'),
                    _FirstAidBullet(text: isTamil ? 'நோயாளியின் முந்தைய மருத்துவ சீட்டுகள் மற்றும் ஆதார் / ABHA அட்டையை தயார் நிலையில் வைக்கவும்.' : 'Keep previous prescriptions, medical records, and ABHA ID ready for EMT review.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _callNumber(String phone) {
    ref.read(directionsLauncherProvider).call(phone);
  }
}

class _VehicleMeta extends StatelessWidget {
  const _VehicleMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _TrackingStep extends StatelessWidget {
  const _TrackingStep({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isCompleted,
    this.isActive = false,
  });

  final String stepNumber;
  final String title;
  final String subtitle;
  final String time;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? (isActive ? Colors.orange.shade800 : Colors.teal)
        : Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: isCompleted && !isActive
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      stepNumber,
                      style: TextStyle(
                        color: isCompleted ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isCompleted ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                  ],
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstAidBullet extends StatelessWidget {
  const _FirstAidBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
