import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherName;
  final String propertyTitle;

  const ChatScreen({super.key, required this.conversationId,
      required this.otherName, this.propertyTitle = ''});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages(widget.conversationId, refresh: true);
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) context.read<ChatProvider>().loadMessages(widget.conversationId, refresh: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); _timer?.cancel(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    try {
      await context.read<ChatProvider>().sendMessage(widget.conversationId, text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final myId = auth.user?.id ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // App bar
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
            ),
            child: Row(children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.r12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.r12),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.r12),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(AppTheme.r12)),
                child: Center(child: Text(
                  widget.otherName.isNotEmpty ? widget.otherName[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.otherName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                if (widget.propertyTitle.isNotEmpty)
                  Text(widget.propertyTitle, style: GoogleFonts.inter(fontSize: 12,
                      color: AppTheme.primary, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),

          // Messages
          Expanded(
            child: chat.messages.isEmpty && chat.loading
                ? Center(child: CircularProgressIndicator(
                    color: AppTheme.primary.withValues(alpha: 0.6), strokeWidth: 3))
                : ListView.builder(
                    controller: _scroll, reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: chat.messages.length,
                    itemBuilder: (_, i) {
                      final msg = chat.messages[i];
                      return _Bubble(text: msg.text, isMe: msg.senderId == myId, time: msg.createdAt, isDark: isDark);
                    },
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
            ),
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(AppTheme.r24),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: '...',
                      hintStyle: GoogleFonts.inter(color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.r16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.r16),
                  onTap: _send,
                  child: const SizedBox(width: 46, height: 46,
                      child: Icon(Icons.send_rounded, color: Colors.white, size: 20)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe, isDark;
  final DateTime time;

  const _Bubble({required this.text, required this.isMe, required this.time, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(text, style: GoogleFonts.inter(
            color: isMe ? Colors.white : isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            fontSize: 15, height: 1.4)),
          const SizedBox(height: 2),
          Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(fontSize: 11,
                  color: isMe ? Colors.white60 : isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
        ]),
      ),
    );
  }
}
