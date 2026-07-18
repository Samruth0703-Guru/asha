import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Hello Lakshmi, I am your ASHA Clinical AI Assistant. How can I assist you with patient guidance or clinical reports today?',
      'time': '10:00 AM'
    }
  ];

  final List<String> _suggestions = [
    'Check high-risk BP guidelines',
    'Recommend Hb protocols',
    'Vaccination due checklist',
    'Calculate EDD for PT001'
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': 'Just now'
      });
      _messageController.clear();
    });

    _scrollToBottom();

    // Simulate AI response after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      String aiReply = "Checking ASHA clinical handbook database... ";
      final query = text.toLowerCase();
      if (query.contains('bp') || query.contains('pressure')) {
        aiReply += "For systolic BP >= 140 mmHg or diastolic >= 90 mmHg, verify measurement, check for dizziness or foot swelling, and initiate reference referral to PHC immediately.";
      } else if (query.contains('hb') || query.contains('hemoglobin')) {
        aiReply += "Severe anemia is defined as Hb < 7 g/dL. Initiate immediate medical reference. For moderate anemia (7-9.9 g/dL), ensure double doses of Iron Folic Acid (IFA) daily.";
      } else if (query.contains('vaccin')) {
        aiReply += "Upcoming vaccines include: Pentavalent 1/2/3, Rotavirus, OPV, and Fractional IPV doses as per infant schedules.";
      } else {
        aiReply += "I am checking guidelines. Ensure patient vitals are recorded locally and sync status is updated.";
      }

      setState(() {
        _messages.add({
          'isUser': false,
          'text': aiReply,
          'time': 'Just now'
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('ASHA Clinical Copilot', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Subtitle guide bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.secondaryColor),
                ),
                const SizedBox(width: 8),
                Text('Generative AI engine fully synchronized', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'];
                return FadeIn(
                  duration: const Duration(milliseconds: 200),
                  child: Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUser ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['text'],
                            style: GoogleFonts.inter(
                              color: isUser ? Colors.white : const Color(0xff0f172a),
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              msg['time'],
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: isUser ? Colors.white60 : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Suggestion Chips list
          Container(
            height: 48,
            color: Colors.transparent,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                  child: ActionChip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade200),
                    label: Text(_suggestions[index], style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.primaryColor)),
                    onPressed: () => _sendMessage(_suggestions[index]),
                  ),
                );
              },
            ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: _sendMessage,
                    decoration: const InputDecoration(
                      hintText: 'Ask a clinical question...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
