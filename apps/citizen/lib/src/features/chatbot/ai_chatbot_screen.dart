import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../emergency/ambulance_tracker_screen.dart';
import '../language/locale_controller.dart';
import 'mistral_chatbot_service.dart';
import 'voice_assistant_service.dart';
import 'voice_orb_screen.dart';

/// Full interactive AI Healthcare Chatbot Screen powered by Mistral AI.
class AiChatbotScreen extends ConsumerStatefulWidget {
  const AiChatbotScreen({super.key});

  @override
  ConsumerState<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends ConsumerState<AiChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  final List<String> _quickPromptsEn = [
    'I have fever & headache for 2 days',
    'Which hospital should I visit in Tiruvannamalai?',
    'What does BP 135/88 mean?',
    'How do I claim CMCHIS insurance?',
    'What are generic Jan Aushadhi medicines?',
    'First aid steps for sudden burn injury',
  ];

  final List<String> _quickPromptsTa = [
    '2 நாட்களாக காய்ச்சல் & தலைவலி உள்ளது',
    'திருவண்ணாமலையில் எந்த மருத்துவமனைக்கு செல்ல வேண்டும்?',
    'எனது BP 135/88 என்ன குறிக்கிறது?',
    'முதலமைச்சரின் மருத்துவ காப்பீடு எவ்வாறு பெறுவது?',
    'ஜன் அவுஷதி மலிவு விலை மருந்துகள் எங்கு கிடைக்கும்?',
    'தீக்காயத்திற்கு முதலுதவி என்ன?',
  ];

  @override
  void initState() {
    super.initState();
    // Add initial greeting message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isTamil = ref.read(localeControllerProvider)?.languageCode == 'ta';
      _messages.add(
        ChatMessage(
          text: isTamil
              ? 'வணக்கம்! நான் ஆரோக்கியமித்ரா AI (ArogyaMitra AI). உங்கள் உடல்நலக் கேள்விகள், அறிகுறிகள், மருந்துகள், அல்லது மருத்துவமனை வழிகாட்டுதல்கள் குறித்து என்னிடம் தமிழில் அல்லது ஆங்கிலத்தில் கேளுங்கள். நான் உங்களுக்கு உதவத் தயாராக இருக்கிறேன்! 🌿'
              : 'Hello! I am ArogyaMitra AI, your personal healthcare assistant powered by Mistral AI. Ask me about your symptoms, lab vitals, prescriptions, or hospital guidance in Tamil or English. How can I help you today? 🌿',
          isUser: false,
        ),
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _textController.clear();
    final isTamil = ref.read(localeControllerProvider)?.languageCode == 'ta';

    setState(() {
      _messages.add(ChatMessage(text: trimmed, isUser: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final service = ref.read(mistralChatbotServiceProvider);
      final responseText = await service.sendMessage(
        history: _messages,
        userMessage: trimmed,
        languageCode: isTamil ? 'ta' : 'en',
      );

      final isEmergency = responseText.contains('🚨') ||
          responseText.toLowerCase().contains('emergency 108') ||
          responseText.contains('108 ஆம்புலன்ஸ்');

      setState(() {
        _messages.add(
          ChatMessage(
            text: responseText,
            isUser: false,
            isEmergencyAlert: isEmergency,
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: isTamil
                ? 'மன்னிக்கவும், பிழை ஏற்பட்டது. தயவுசெய்து மீண்டும் முயற்சிக்கவும்.'
                : 'Sorry, a connection error occurred. Please try again.',
            isUser: false,
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _confirmClearChat(bool isTamil) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTamil ? 'அரட்டையை அழிக்கவா?' : 'Clear Chat History?'),
        content: Text(
          isTamil
              ? 'அனைத்து உரையாடல் பதிவுகளும் அழிக்கப்படும்.'
              : 'All previous messages in this session will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    text: isTamil
                        ? 'புதிய உரையாடல் தொடங்கியது. எதைப் பற்றி அறிய விரும்புகிறீர்கள்?'
                        : 'New conversation started. What would you like to know today?',
                    isUser: false,
                  ),
                );
              });
            },
            child: Text(isTamil ? 'அழி' : 'Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTamil = ref.watch(localeControllerProvider)?.languageCode == 'ta';
    final quickPrompts = isTamil ? _quickPromptsTa : _quickPromptsEn;

    // Check if the latest message is an emergency alert
    final hasActiveEmergency = _messages.isNotEmpty && _messages.last.isEmergencyAlert;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.teal, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isTamil ? 'ஆரோக்கியமித்ரா AI' : 'ArogyaMitra AI',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Mistral AI • Online',
                      style: TextStyle(fontSize: 11, color: AmTokens.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isTamil ? 'குரல் வழி முறை (Voice Orb)' : 'Voice Mode',
            icon: const Icon(Icons.record_voice_over, color: Colors.teal),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VoiceOrbScreen()),
              );
            },
          ),
          IconButton(
            tooltip: isTamil ? 'அரட்டையை அழி' : 'Clear Chat',
            icon: const Icon(Icons.delete_outline, size: 22),
            onPressed: () => _confirmClearChat(isTamil),
          ),
          IconButton(
            tooltip: isTamil ? 'அவசர உதவி 108' : 'Emergency 108',
            icon: const Icon(Icons.emergency, color: Colors.red, size: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AmbulanceTrackerScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🚨 Emergency Callout Banner (if flagged by AI)
            if (hasActiveEmergency)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
                  border: Border.all(color: Colors.red.shade400, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTamil ? 'உடனடி அவசர உதவி தேவைப்படலாம்!' : 'Urgent Emergency Care Alert!',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            isTamil
                                ? 'தாமதிக்காமல் உடனடியாக 108 ஆம்புலன்ஸை அழைக்கவும்.'
                                : 'Please call 108 Emergency Ambulance or visit GMCH right away.',
                            style: TextStyle(color: Colors.red.shade800, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AmbulanceTrackerScreen()),
                        );
                      },
                      icon: const Icon(Icons.phone_in_talk, size: 16),
                      label: const Text('108', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Quick Topic Suggestion Chips
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    backgroundColor: Colors.teal.shade50.withAlpha(180),
                    side: BorderSide(color: Colors.teal.shade200),
                    label: Text(
                      quickPrompts[index],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.teal.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () => _sendMessage(quickPrompts[index]),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isSending) {
                    return _buildTypingIndicator(isTamil);
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, theme, isTamil);
                },
              ),
            ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: const [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: isTamil
                            ? 'உடல்நலம் பற்றி தமிழில் அல்லது ஆங்கிலத்தில் கேளுங்கள்...'
                            : 'Ask any health question in Tamil or English...',
                        hintStyle: const TextStyle(fontSize: 13, color: AmTokens.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Microphone Speech-to-Text Button
                  Consumer(
                    builder: (context, ref, _) {
                      final voiceService = ref.watch(voiceAssistantServiceProvider);
                      final isListening = voiceService.isListening;

                      return Material(
                        color: isListening ? Colors.redAccent : Colors.teal.shade50,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: isListening
                              ? (isTamil ? 'பேசுவதை நிறுத்து' : 'Stop Listening')
                              : (isTamil ? 'குரல் வழி பேசு' : 'Voice Input'),
                          icon: Icon(
                            isListening ? Icons.mic : Icons.mic_none,
                            color: isListening ? Colors.white : Colors.teal.shade800,
                            size: 22,
                          ),
                          onPressed: () {
                            if (isListening) {
                              voiceService.stopListening();
                            } else {
                              voiceService.startListening(
                                languageCode: isTamil ? 'ta' : 'en',
                                onResult: (text, isFinal) {
                                  setState(() {
                                    _textController.text = text;
                                    _textController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: text.length),
                                    );
                                  });
                                },
                                onError: (err) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(err), duration: const Duration(seconds: 2)),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),

                  // Send Button
                  Material(
                    color: _isSending ? Colors.grey : AmTokens.primary,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isSending ? null : () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ThemeData theme, bool isTamil) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.health_and_safety, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AmTokens.primary
                    : (msg.isEmergencyAlert ? Colors.red.shade50 : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AmTokens.primary
                      : (msg.isEmergencyAlert ? Colors.red.shade300 : Colors.grey.shade300),
                  width: msg.isEmergencyAlert ? 1.5 : 1.0,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _MarkdownContentView(
                    text: msg.text,
                    isUser: isUser,
                    isEmergencyAlert: msg.isEmergencyAlert,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? Colors.white70 : Colors.black45,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 8),
                        // Copy Button
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: msg.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isTamil ? 'பதில் நகலெடுக்கப்பட்டது' : 'Response copied to clipboard'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy, size: 13, color: Colors.black45),
                        ),
                        const SizedBox(width: 8),
                        // Speaker TTS Playback Button
                        Consumer(
                          builder: (context, ref, _) {
                            final voiceService = ref.watch(voiceAssistantServiceProvider);
                            final isSpeakingThis = voiceService.isSpeaking &&
                                voiceService.currentlySpeakingText == msg.text;

                            return GestureDetector(
                              onTap: () {
                                if (isSpeakingThis) {
                                  voiceService.stopSpeaking();
                                } else {
                                  voiceService.speak(
                                    text: msg.text,
                                    languageCode: isTamil ? 'ta' : 'en',
                                  );
                                }
                              },
                              child: Icon(
                                isSpeakingThis ? Icons.volume_up : Icons.volume_up_outlined,
                                size: 16,
                                color: isSpeakingThis ? Colors.teal : Colors.black45,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AmTokens.primaryLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person, color: AmTokens.primary, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isTamil) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.health_and_safety, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                ),
                const SizedBox(width: 8),
                Text(
                  isTamil ? 'ஆரோக்கியமித்ரா AI பதிலளிக்கிறது...' : 'ArogyaMitra AI is thinking...',
                  style: const TextStyle(fontSize: 12, color: AmTokens.textSecondary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders structured markdown content from Mistral AI into styled Flutter widgets.
class _MarkdownContentView extends StatelessWidget {
  const _MarkdownContentView({
    required this.text,
    required this.isUser,
    required this.isEmergencyAlert,
  });

  final String text;
  final bool isUser;
  final bool isEmergencyAlert;

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          height: 1.4,
        ),
      );
    }

    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final trimmed = rawLine.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 4));
        continue;
      }

      // 1. Horizontal rule: --- or ***
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isEmergencyAlert ? Colors.red.shade200 : Colors.grey.shade300,
            ),
          ),
        );
        continue;
      }

      // 2. Headers: #, ##, ###, ####
      if (trimmed.startsWith('#')) {
        final level = trimmed.indexOf(RegExp(r'[^#]'));
        final headerText = trimmed.replaceFirst(RegExp(r'^#+\s*'), '').replaceAll('**', '').trim();
        final fontSize = level <= 2 ? 15.5 : (level == 3 ? 14.0 : 13.0);
        final color = isEmergencyAlert
            ? Colors.red.shade900
            : (level <= 2 ? Colors.teal.shade900 : const Color(0xFF1E293B));

        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 8, bottom: 3),
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.3,
              ),
            ),
          ),
        );
        continue;
      }

      // 3. Numbered lists: 1. , 2. 
      final numberedMatch = RegExp(r'^(\d+)\.\s+(.*)').firstMatch(trimmed);
      if (numberedMatch != null) {
        final numStr = numberedMatch.group(1)!;
        final content = numberedMatch.group(2)!;

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numStr. ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isEmergencyAlert ? Colors.red.shade700 : Colors.teal.shade800,
                    fontSize: 13.5,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: _parseInlineMarkdown(content, isEmergency: isEmergencyAlert),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 4. Bullet points: - , * 
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final content = trimmed.substring(2).trim();
        final isIndented = rawLine.startsWith('   ') || rawLine.startsWith('\t');

        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              left: isIndented ? 14.0 : 0.0,
              top: 2.0,
              bottom: 2.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3.0, right: 6.0),
                  child: Icon(
                    Icons.circle,
                    size: 5,
                    color: isEmergencyAlert ? Colors.red.shade700 : Colors.teal.shade700,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: _parseInlineMarkdown(content, isEmergency: isEmergencyAlert),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 5. Standard paragraph line
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: RichText(
            text: TextSpan(
              children: _parseInlineMarkdown(trimmed, isEmergency: isEmergencyAlert),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  List<InlineSpan> _parseInlineMarkdown(String text, {bool isEmergency = false}) {
    final spans = <InlineSpan>[];
    final defaultColor = isEmergency ? Colors.red.shade900 : const Color(0xFF1E293B);
    final boldColor = isEmergency ? const Color(0xFF7F1D1D) : const Color(0xFF0F172A);

    final regex = RegExp(r'\*\*(.*?)\*\*');
    int currentIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: TextStyle(
            color: defaultColor,
            fontSize: 13.5,
            height: 1.45,
          ),
        ));
      }

      final boldContent = match.group(1) ?? '';
      spans.add(TextSpan(
        text: boldContent,
        style: TextStyle(
          color: boldColor,
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
          height: 1.45,
        ),
      ));

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: TextStyle(
          color: defaultColor,
          fontSize: 13.5,
          height: 1.45,
        ),
      ));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: defaultColor,
          fontSize: 13.5,
          height: 1.45,
        ),
      ));
    }

    return spans;
  }
}
