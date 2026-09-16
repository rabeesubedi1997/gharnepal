import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../widgets/property_card.dart';
import '../../listings/data/models/listing_summary.dart';
import '../application/assistant_providers.dart';
import '../data/models/assistant_chat_response.dart';

class _ChatMessage {
  _ChatMessage.user(this.text) : isMine = true, listings = const [], filtersApplied = null;

  _ChatMessage.assistant(this.text, {this.listings = const [], this.filtersApplied}) : isMine = false;

  final bool isMine;
  final String text;
  final List<ListingSummary> listings;
  final AssistantFiltersApplied? filtersApplied;
}

/// The mobile "Ask AI" screen — talks to the same rule-based
/// `/assistant/chat` endpoint the web widget uses (see
/// AssistantWidget.tsx/useAssistantChat.ts). No paid AI API involved (see
/// backend AssistantService/PropertySearchParser); this reuses the site's
/// own buyer↔owner chat-bubble styling and the shared `PropertyCard` widget.
class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  ConsumerState<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];

  // Both device-native (no external API — see PropertySearchParser's own
  // zero-cost design). speech_to_text needs android.permission.RECORD_AUDIO
  // (declared in AndroidManifest.xml) and requests it itself on first use.
  final _speechToText = SpeechToText();
  final _tts = FlutterTts();

  String? _guestToken;
  int? _conversationId;
  bool _sending = false;
  bool _speechAvailable = false;
  bool _listening = false;
  bool _speakReplies = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _initSpeech();
  }

  Future<void> _loadSession() async {
    final storage = ref.read(assistantChatStorageProvider);
    var token = await storage.readGuestToken();
    if (token == null) {
      token = _randomToken();
      await storage.saveGuestToken(token);
    }
    final conversationId = await storage.readConversationId();
    final speakReplies = await storage.readSpeakRepliesEnabled();
    if (mounted) {
      setState(() {
        _guestToken = token;
        _conversationId = conversationId;
        _speakReplies = speakReplies;
      });
    }
  }

  Future<void> _initSpeech() async {
    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (mounted) setState(() => _listening = status == 'listening');
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  String _randomToken() {
    final random = Random.secure();
    return List.generate(32, (_) => random.nextInt(36).toRadixString(36)).join();
  }

  void _toggleListening() {
    if (_listening) {
      _speechToText.stop();
      return;
    }
    _speechToText.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          // Voice is meant to go straight to an answer — send immediately
          // rather than requiring a second tap on the send button.
          _controller.text = result.recognizedWords;
          _send();
        }
      },
    );
  }

  Future<void> _toggleSpeakReplies() async {
    final next = !_speakReplies;
    setState(() => _speakReplies = next);
    await ref.read(assistantChatStorageProvider).saveSpeakRepliesEnabled(next);
    if (!next) _tts.stop();
  }

  /// Devanagari script gets a Nepali TTS voice hint; Romanized Nepali and
  /// English both read fine under the default voice.
  Future<void> _speak(String text) async {
    if (!_speakReplies || text.trim().isEmpty) return;
    final isDevanagari = RegExp(r'[ऀ-ॿ]').hasMatch(text);
    await _tts.setLanguage(isDevanagari ? 'ne-NP' : 'en-US');
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _speechToText.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage.user(text));
      _sending = true;
    });
    _controller.clear();

    try {
      final response = await ref
          .read(assistantRepositoryProvider)
          .chat(message: text, conversationId: _conversationId, guestToken: _guestToken);

      _conversationId = response.conversationId;
      await ref.read(assistantChatStorageProvider).saveConversationId(response.conversationId);

      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage.assistant(response.reply, listings: response.listings, filtersApplied: response.filtersApplied),
          );
        });
        _speak(response.reply);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _messages.add(_ChatMessage.assistant(error.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _resetConversation() async {
    await ref.read(assistantChatStorageProvider).clearConversation();
    setState(() {
      _conversationId = null;
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghar Nepal Assistant'),
        actions: [
          IconButton(
            onPressed: _toggleSpeakReplies,
            icon: Icon(_speakReplies ? Icons.volume_up : Icons.volume_off),
            tooltip: _speakReplies ? 'Turn off spoken replies' : 'Turn on spoken replies',
          ),
          IconButton(
            onPressed: _messages.isEmpty ? null : _resetConversation,
            icon: const Icon(Icons.refresh),
            tooltip: 'Start a new conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_sending && index == 0) {
                        return const _ThinkingBubble();
                      }
                      final message = _messages[_messages.length - 1 - (_sending ? index - 1 : index)];
                      return _ChatBubble(message: message);
                    },
                  ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (_speechAvailable)
                    IconButton.filledTonal(
                      onPressed: _sending ? null : _toggleListening,
                      icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                      style: _listening
                          ? IconButton.styleFrom(backgroundColor: AppColors.danger600, foregroundColor: Colors.white)
                          : null,
                      tooltip: _listening ? 'Stop listening' : 'Ask by voice',
                    ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(hintText: _listening ? 'Listening...' : 'Ask about a property...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 5),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 32, color: AppColors.trust700),
            const SizedBox(height: 12),
            Text('Tell me what you\'re looking for.', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'e.g. "a room in Kathmandu under NPR 20,000" or "3 bhk house for sale in Lalitpur"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.stone100, borderRadius: BorderRadius.circular(14)),
        child: Text('Thinking...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink700)),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final align = message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final background = message.isMine ? AppColors.trust700 : AppColors.stone100;
    final textColor = message.isMine ? Colors.white : AppColors.ink900;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
            child: Text(message.text, style: TextStyle(color: textColor)),
          ),
          if (message.filtersApplied != null && message.filtersApplied!.chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.filtersApplied!.chips
                    .map((label) => Chip(label: Text(label, style: Theme.of(context).textTheme.labelSmall)))
                    .toList(growable: false),
              ),
            ),
          if (message.listings.isNotEmpty)
            SizedBox(
              height: 230,
              width: MediaQuery.of(context).size.width * 0.85,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: message.listings.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final listing = message.listings[index];
                    return SizedBox(
                      width: 180,
                      child: PropertyCard(listing: listing, onTap: () => context.push('/listings/${listing.slug}')),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
