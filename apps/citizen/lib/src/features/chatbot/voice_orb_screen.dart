import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../emergency/ambulance_tracker_screen.dart';
import '../language/locale_controller.dart';
import 'ai_chatbot_screen.dart';
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
    final isTamil = ref.read(localeControllerProvider)?.languageCode == 'ta';
    final voiceService = ref.read(voiceAssistantServiceProvider);

    voiceService.stopSpeaking();

    setState(() {
      _state = VoiceState.listening;
      _userSpokenText = '';
      _isEmergency = false;
    });

    voiceService.startListening(
      languageCode: isTamil ? 'ta' : 'en',
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

    final isTamil = ref.read(localeControllerProvider)?.languageCode == 'ta';

    setState(() {
      _state = VoiceState.thinking;
    });

    try {
      final mistral = ref.read(mistralChatbotServiceProvider);
      final response = await mistral.sendMessage(
        history: [],
        userMessage: query,
        languageCode: isTamil ? 'ta' : 'en',
      );

      final emergency = response.contains('🚨') ||
          response.toLowerCase().contains('emergency 108') ||
          response.contains('108 ஆம்புலன்ஸ்');

      if (!mounted) return;

      setState(() {
        _aiResponseText = response;
        _isEmergency = emergency;
        _state = VoiceState.speaking;
      });

      // Speak response aloud via TTS
      ref.read(voiceAssistantServiceProvider).speak(
        text: response,
        languageCode: isTamil ? 'ta' : 'en',
        onEnd: () {
          if (mounted) {
            setState(() => _state = VoiceState.idle);
          }
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiResponseText = isTamil
            ? 'மன்னிக்கவும், பிழை ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.'
            : 'Sorry, an error occurred. Please try again.';
        _state = VoiceState.idle;
      });
    }
  }

  void _stopSpeaking() {
    ref.read(voiceAssistantServiceProvider).stopSpeaking();
    setState(() => _state = VoiceState.idle);
  }

  void _toggleLanguage() {
    final current = ref.read(localeControllerProvider)?.languageCode == 'ta';
    ref.read(localeControllerProvider.notifier).choose(Locale(current ? 'en' : 'ta'));
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
    final isTamil = ref.watch(localeControllerProvider)?.languageCode == 'ta';

    Color orbStartColor;
    Color orbEndColor;
    String statusTitle;
    String statusSubtitle;

    switch (_state) {
      case VoiceState.listening:
        orbStartColor = const Color(0xFF00E676);
        orbEndColor = const Color(0xFF00B0FF);
        statusTitle = isTamil ? 'கேட்கிறது...' : 'Listening...';
        statusSubtitle = isTamil ? 'உங்கள் கேள்வியை பேசுங்கள்' : 'Speak your health question now';
        break;
      case VoiceState.thinking:
        orbStartColor = const Color(0xFFFF9100);
        orbEndColor = const Color(0xFFFF5252);
        statusTitle = isTamil ? 'சிந்திக்கிறது...' : 'Thinking...';
        statusSubtitle = isTamil ? 'Mistral AI பதிலை தயாரிக்கிறது' : 'Mistral AI is formulating clinical guidance';
        break;
      case VoiceState.speaking:
        orbStartColor = const Color(0xFF2979FF);
        orbEndColor = const Color(0xFF00E5FF);
        statusTitle = isTamil ? 'பதிலளிக்கிறது...' : 'Speaking...';
        statusSubtitle = isTamil ? 'வழிகாட்டுதலை கவனியுங்கள்' : 'Listening to medical guidance';
        break;
      case VoiceState.idle:
        orbStartColor = const Color(0xFF651FFF);
        orbEndColor = const Color(0xFF00B0FF);
        statusTitle = isTamil ? 'ஆரோக்கியமித்ரா AI' : 'ArogyaMitra AI';
        statusSubtitle = isTamil ? 'பேச மைக்ரோஃபோனைத் தொடவும்' : 'Tap the orb to start speaking';
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over, color: Colors.tealAccent, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    isTamil ? 'குரல் வழி உதவி' : 'Voice Assistant',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher (Tamil ⇄ English)
          TextButton.icon(
            onPressed: _toggleLanguage,
            icon: const Icon(Icons.translate, size: 16, color: Colors.tealAccent),
            label: Text(
              isTamil ? 'தமிழ்' : 'English',
              style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          // Switch to Text Chat Mode
          IconButton(
            tooltip: isTamil ? 'உரை அரட்டைக்கு மாறுக' : 'Switch to Text Chat',
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
                            isTamil ? 'உடனடி அவசர சிகிச்சை தேவை!' : 'Urgent Emergency Alert!',
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isTamil ? '108 ஆம்புலன்ஸை உடனடியாக அழைக்கவும்' : 'Call 108 Emergency Ambulance now',
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
                    tooltip: isTamil ? 'மீண்டும் கேள்' : 'Hear Again',
                    iconSize: 28,
                    color: Colors.white60,
                    icon: const Icon(Icons.replay),
                    onPressed: _aiResponseText.isNotEmpty
                        ? () {
                            ref.read(voiceAssistantServiceProvider).speak(
                              text: _aiResponseText,
                              languageCode: isTamil ? 'ta' : 'en',
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
                    tooltip: isTamil ? 'நிறுத்து' : 'Stop',
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
