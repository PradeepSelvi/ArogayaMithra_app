import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../emergency/ambulance_tracker_screen.dart';
import '../facilities/facility_map_screen.dart';
import '../home_visit/home_visit_request_screen.dart';
import '../language/locale_controller.dart';
import '../medications/medication_manager_screen.dart';
import '../profile/profile_screen.dart';
import '../records/lab_vault_screen.dart';
import '../referrals/referral_list_screen.dart';
import '../vitals/vitals_tracker_screen.dart';
import 'ai_chatbot_screen.dart';
import 'chat_history_controller.dart';
import 'mistral_chatbot_service.dart';
import 'voice_assistant_service.dart';

enum VoiceState {
  idle,
  listening,
  thinking,
  speaking,
}

/// Full-screen interactive Voice Orb Assistant for hands-free healthcare access.
class VoiceOrbScreen extends ConsumerStatefulWidget {
  const VoiceOrbScreen({super.key});

  @override
  ConsumerState<VoiceOrbScreen> createState() => _VoiceOrbScreenState();
}

class _VoiceOrbScreenState extends ConsumerState<VoiceOrbScreen> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _waveController;

  VoiceState _state = VoiceState.idle;
  String _userSpokenText = '';
  String _aiResponseText = '';
  bool _isEmergency = false;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Auto-start listening after screen enters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVoiceInput();
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    ref.read(voiceAssistantServiceProvider).stopListening();
    ref.read(voiceAssistantServiceProvider).stopSpeaking();
    super.dispose();
  }

  void _startVoiceInput() {
    final lang = ref.read(localeControllerProvider)?.languageCode ?? 'en';
    final voiceService = ref.read(voiceAssistantServiceProvider);

    voiceService.stopSpeaking();

    setState(() {
      _state = VoiceState.listening;
      _userSpokenText = '';
      _isEmergency = false;
    });

    voiceService.startListening(
      languageCode: lang,
      onResult: (text, isFinal) {
        setState(() {
          _userSpokenText = text;
        });

        // Reset silence timer on new speech
        _silenceTimer?.cancel();
        if (text.trim().isNotEmpty) {
          // If silence for 2.2s after user spoke, auto-submit
          _silenceTimer = Timer(const Duration(milliseconds: 2200), () {
            if (_state == VoiceState.listening && _userSpokenText.trim().isNotEmpty) {
              _submitToAi(_userSpokenText);
            }
          });
        }
      },
      onEnd: () {
        if (_state == VoiceState.listening) {
          if (_userSpokenText.trim().isNotEmpty) {
            _submitToAi(_userSpokenText);
          } else {
            setState(() => _state = VoiceState.idle);
          }
        }
      },
      onError: (err) {
        if (_state == VoiceState.listening) {
          setState(() => _state = VoiceState.idle);
          if (mounted && err.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );
  }

  void _stopVoiceInput() {
    _silenceTimer?.cancel();
    ref.read(voiceAssistantServiceProvider).stopListening();
    if (_userSpokenText.trim().isNotEmpty) {
      _submitToAi(_userSpokenText);
    } else {
      setState(() => _state = VoiceState.idle);
    }
  }

  Future<void> _submitToAi(String query) async {
    _silenceTimer?.cancel();
    ref.read(voiceAssistantServiceProvider).stopListening();

    final lang = ref.read(localeControllerProvider)?.languageCode ?? 'en';

    setState(() {
      _state = VoiceState.thinking;
    });

    try {
      final existingHistory = ref.read(chatHistoryProvider).messages;
      final userMsg = ChatMessage(text: query, isUser: true);
      ref.read(chatHistoryProvider.notifier).addMessage(userMsg);

      final mistral = ref.read(mistralChatbotServiceProvider);
      final reply = await mistral.sendMessage(
        history: existingHistory,
        userMessage: query,
        languageCode: lang,
      );

      if (!mounted) return;

      if (reply.tool != null) {
        await _runTool(reply.tool!, lang);
        return;
      }

      final response = reply.content!;
      final emergency = response.contains('🚨') ||
          response.toLowerCase().contains('emergency 108') ||
          response.contains('108 ஆம்புலன்ஸ்') ||
          response.contains('108 एम्बुलेंस');

      final aiMsg = ChatMessage(
        text: response,
        isUser: false,
        isEmergencyAlert: emergency,
      );
      ref.read(chatHistoryProvider.notifier).addMessage(aiMsg);

      setState(() {
        _aiResponseText = response;
        _isEmergency = emergency;
        _state = VoiceState.speaking;
      });

      // Speak response aloud via TTS, matching the language it was actually
      // written in rather than the UI toggle (the model can occasionally
      // reply in the citizen's typed language even when instructed otherwise).
      ref.read(voiceAssistantServiceProvider).speak(
        text: response,
        languageCode: VoiceAssistantService.detectLanguageOfText(response),
        onEnd: () {
          if (mounted) {
            setState(() => _state = VoiceState.idle);
          }
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiResponseText = switch (lang) {
          'ta' => 'மன்னிக்கவும், பிழை ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.',
          'hi' => 'क्षमा करें, एक त्रुटि हुई। फिर से कोशिश करें।',
          _ => 'Sorry, an error occurred. Please try again.',
        };
        _state = VoiceState.idle;
      });
    }
  }

  /// Runs a tool the assistant asked for (a navigation action): speaks a
  /// short confirmation, then opens the corresponding screen.
  Future<void> _runTool(ChatTool tool, String lang) async {
    final (screen, confirmationEn, confirmationTa, confirmationHi) = switch (tool) {
      ChatTool.openAmbulanceTracker => (
          const AmbulanceTrackerScreen(),
          'Opening the emergency ambulance tracker for you.',
          'உங்களுக்காக அவசர ஆம்புலன்ஸ் கண்காணிப்பைத் திறக்கிறேன்.',
          'आपके लिए आपातकालीन एम्बुलेंस ट्रैकर खोल रहा हूँ।',
        ),
      ChatTool.openFacilityMap => (
          const FacilityMapScreen(),
          'Opening the map of nearby facilities.',
          'அருகிலுள்ள மருத்துவமனைகளின் வரைபடத்தைத் திறக்கிறேன்.',
          'आस-पास के स्वास्थ्य केंद्रों का नक्शा खोल रहा हूँ।',
        ),
      ChatTool.openMedications => (
          const MedicationManagerScreen(),
          'Opening your medications.',
          'உங்கள் மருந்துகளைத் திறக்கிறேன்.',
          'आपकी दवाइयाँ खोल रहा हूँ।',
        ),
      ChatTool.openVitalsTracker => (
          const VitalsTrackerScreen(),
          'Opening your vitals tracker.',
          'உங்கள் உடல்நல அளவீடுகளைத் திறக்கிறேன்.',
          'आपका वाइटल्स ट्रैकर खोल रहा हूँ।',
        ),
      ChatTool.openLabVault => (
          const LabVaultScreen(),
          'Opening your lab reports.',
          'உங்கள் ஆய்வக அறிக்கைகளைத் திறக்கிறேன்.',
          'आपकी जांच रिपोर्ट खोल रहा हूँ।',
        ),
      ChatTool.openReferrals => (
          const ReferralListScreen(),
          'Opening your referrals.',
          'உங்கள் பரிந்துரைகளைத் திறக்கிறேன்.',
          'आपके रेफ़रल खोल रहा हूँ।',
        ),
      ChatTool.openProfile => (
          const ProfileScreen(),
          'Opening your profile.',
          'உங்கள் சுயவிவரத்தைத் திறக்கிறேன்.',
          'आपकी प्रोफ़ाइल खोल रहा हूँ।',
        ),
      ChatTool.openHomeVisitRequest => (
          const HomeVisitRequestScreen(),
          'Opening the home visit request form.',
          'வீட்டு வருகை கோரிக்கை படிவத்தைத் திறக்கிறேன்.',
          'घर विज़िट अनुरोध फ़ॉर्म खोल रहा हूँ।',
        ),
    };

    final confirmation = switch (lang) {
      'ta' => confirmationTa,
      'hi' => confirmationHi,
      _ => confirmationEn,
    };

    setState(() {
      _aiResponseText = confirmation;
      _state = VoiceState.speaking;
    });

    ref.read(voiceAssistantServiceProvider).speak(
      text: confirmation,
      languageCode: lang,
      onEnd: () async {
        if (!mounted) return;
        setState(() => _state = VoiceState.idle);
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      },
    );
  }

  void _stopSpeaking() {
    ref.read(voiceAssistantServiceProvider).stopSpeaking();
    setState(() => _state = VoiceState.idle);
  }

  void _toggleLanguage() {
    final current = ref.read(localeControllerProvider)?.languageCode ?? 'en';
    final next = switch (current) {
      'en' => 'ta',
      'ta' => 'hi',
      _ => 'en',
    };
    ref.read(localeControllerProvider.notifier).choose(Locale(next));
    // Stop current speech/audio and re-prompt
    ref.read(voiceAssistantServiceProvider).stopSpeaking();
    ref.read(voiceAssistantServiceProvider).stopListening();
    setState(() {
      _state = VoiceState.idle;
      _userSpokenText = '';
      _aiResponseText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeControllerProvider)?.languageCode ?? 'en';

    Color orbStartColor;
    Color orbEndColor;
    String statusTitle;
    String statusSubtitle;

    switch (_state) {
      case VoiceState.listening:
        orbStartColor = const Color(0xFF00E676);
        orbEndColor = const Color(0xFF00B0FF);
        statusTitle = switch (lang) {
          'ta' => 'கேட்கிறது...',
          'hi' => 'सुन रहा है...',
          _ => 'Listening...',
        };
        statusSubtitle = switch (lang) {
          'ta' => 'உங்கள் கேள்வியை பேசுங்கள்',
          'hi' => 'अपना स्वास्थ्य प्रश्न बोलें',
          _ => 'Speak your health question now',
        };
        break;
      case VoiceState.thinking:
        orbStartColor = const Color(0xFFFF9100);
        orbEndColor = const Color(0xFFFF5252);
        statusTitle = switch (lang) {
          'ta' => 'சிந்திக்கிறது...',
          'hi' => 'सोच रहा है...',
          _ => 'Thinking...',
        };
        statusSubtitle = switch (lang) {
          'ta' => 'Groq AI பதிலை தயாரிக்கிறது',
          'hi' => 'Groq AI जवाब तैयार कर रहा है',
          _ => 'Groq AI is formulating clinical guidance',
        };
        break;
      case VoiceState.speaking:
        orbStartColor = const Color(0xFF2979FF);
        orbEndColor = const Color(0xFF00E5FF);
        statusTitle = switch (lang) {
          'ta' => 'பதிலளிக்கிறது...',
          'hi' => 'जवाब दे रहा है...',
          _ => 'Speaking...',
        };
        statusSubtitle = switch (lang) {
          'ta' => 'வழிகாட்டுதலை கவனியுங்கள்',
          'hi' => 'मार्गदर्शन ध्यान से सुनें',
          _ => 'Listening to medical guidance',
        };
        break;
      case VoiceState.idle:
        orbStartColor = const Color(0xFF651FFF);
        orbEndColor = const Color(0xFF00B0FF);
        statusTitle = switch (lang) {
          'ta' => 'ஆரோக்கியமித்ரா AI',
          'hi' => 'आरोग्यमित्र AI',
          _ => 'ArogyaMitra AI',
        };
        statusSubtitle = switch (lang) {
          'ta' => 'பேச மைக்ரோஃபோனைத் தொடவும்',
          'hi' => 'बोलने के लिए माइक्रोफ़ोन दबाएं',
          _ => 'Tap the orb to start speaking',
        };
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A), // Sleek deep space dark mode
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.record_voice_over, color: Colors.tealAccent, size: 14),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  switch (lang) {
                    'ta' => 'குரல் வழி உதவி',
                    'hi' => 'ध्वनि सहायक',
                    _ => 'Voice Assistant',
                  },
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Language switcher, cycling English -> Tamil -> Hindi -> English.
          // The label names the language a tap will switch to.
          TextButton.icon(
            onPressed: _toggleLanguage,
            icon: const Icon(Icons.translate, size: 16, color: Colors.tealAccent),
            label: Text(
              switch (lang) {
                'en' => 'தமிழ்',
                'ta' => 'हिन्दी',
                _ => 'English',
              },
              style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          // Switch to Text Chat Mode
          IconButton(
            tooltip: switch (lang) {
              'ta' => 'உரை அரட்டைக்கு மாறுக',
              'hi' => 'टेक्स्ट चैट पर जाएं',
              _ => 'Switch to Text Chat',
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AiChatbotScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Emergency 108 Banner (if critical)
            if (_isEmergency)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency, color: Colors.redAccent, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            switch (lang) {
                              'ta' => 'உடனடி அவசர சிகிச்சை தேவை!',
                              'hi' => 'तत्काल आपातकालीन उपचार आवश्यक!',
                              _ => 'Urgent Emergency Alert!',
                            },
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            switch (lang) {
                              'ta' => '108 ஆம்புலன்ஸை உடனடியாக அழைக்கவும்',
                              'hi' => 'तुरंत 108 एम्बुलेंस को कॉल करें',
                              _ => 'Call 108 Emergency Ambulance now',
                            },
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AmbulanceTrackerScreen()),
                        );
                      },
                      child: const Text('108', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Top Status & Spoken Query Area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        color: orbStartColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Transcribed Spoken Text or AI Response Card
                    if (_userSpokenText.isNotEmpty && _state != VoiceState.speaking)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          '"$_userSpokenText"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    if (_state == VoiceState.speaking && _aiResponseText.isNotEmpty)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              VoiceAssistantService.cleanMarkdownForSpeech(_aiResponseText),
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Center Interactive Siri/Gemini-Style Animated Voice Orb
            Expanded(
              flex: 4,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_state == VoiceState.listening) {
                      _stopVoiceInput();
                    } else if (_state == VoiceState.speaking) {
                      _stopSpeaking();
                    } else if (_state == VoiceState.idle) {
                      _startVoiceInput();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulseController, _waveController]),
                    builder: (context, child) {
                      final pulse = _pulseController.value;
                      final wave = _waveController.value;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ambient glow ring 2
                          Container(
                            width: 240 + (pulse * 30),
                            height: 240 + (pulse * 30),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  orbStartColor.withAlpha((_state == VoiceState.idle ? 25 : 60)),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          // Outer ambient glow ring 1
                          Container(
                            width: 190 + (pulse * 20),
                            height: 190 + (pulse * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  orbEndColor.withAlpha((_state == VoiceState.idle ? 40 : 90)),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          // Rotating wave halo during thinking/speaking
                          if (_state == VoiceState.thinking || _state == VoiceState.speaking)
                            Transform.rotate(
                              angle: wave * 6.28,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      Colors.transparent,
                                      orbStartColor.withAlpha(160),
                                      orbEndColor,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Core Luminous Sphere Orb
                          Container(
                            width: 130 + (pulse * 8),
                            height: 130 + (pulse * 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [orbStartColor, orbEndColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: orbStartColor.withAlpha(140),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              _state == VoiceState.listening
                                  ? Icons.mic
                                  : (_state == VoiceState.speaking
                                      ? Icons.volume_up_rounded
                                      : (_state == VoiceState.thinking
                                          ? Icons.hourglass_top_rounded
                                          : Icons.mic_none_rounded)),
                              color: Colors.white,
                              size: 52,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Bottom Controls Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Replay / Hear Again
                  IconButton(
                    tooltip: switch (lang) {
                      'ta' => 'மீண்டும் கேள்',
                      'hi' => 'फिर से सुनें',
                      _ => 'Hear Again',
                    },
                    iconSize: 28,
                    color: Colors.white60,
                    icon: const Icon(Icons.replay),
                    onPressed: _aiResponseText.isNotEmpty
                        ? () {
                            ref.read(voiceAssistantServiceProvider).speak(
                              text: _aiResponseText,
                              languageCode:
                                  VoiceAssistantService.detectLanguageOfText(_aiResponseText),
                              onEnd: () {
                                if (mounted) setState(() => _state = VoiceState.idle);
                              },
                            );
                            setState(() => _state = VoiceState.speaking);
                          }
                        : null,
                  ),

                  // Big Action Mic Button
                  FloatingActionButton.large(
                    backgroundColor: orbStartColor,
                    onPressed: () {
                      if (_state == VoiceState.listening) {
                        _stopVoiceInput();
                      } else if (_state == VoiceState.speaking) {
                        _stopSpeaking();
                      } else {
                        _startVoiceInput();
                      }
                    },
                    child: Icon(
                      _state == VoiceState.listening
                          ? Icons.stop
                          : (_state == VoiceState.speaking ? Icons.pause : Icons.mic),
                      color: Colors.black,
                      size: 38,
                    ),
                  ),

                  // Stop / Silence Button
                  IconButton(
                    tooltip: switch (lang) {
                      'ta' => 'நிறுத்து',
                      'hi' => 'रोकें',
                      _ => 'Stop',
                    },
                    iconSize: 28,
                    color: Colors.white60,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(voiceAssistantServiceProvider).stopSpeaking();
                      ref.read(voiceAssistantServiceProvider).stopListening();
                      setState(() => _state = VoiceState.idle);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
