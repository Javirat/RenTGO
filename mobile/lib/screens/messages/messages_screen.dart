import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  final bool embedded;
  const MessagesScreen({super.key, this.embedded = false});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final l = AppLocalizations(auth.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = chat.loading && chat.conversations.isEmpty
        ? Center(child: CircularProgressIndicator(
            color: AppTheme.primary.withValues(alpha: 0.6), strokeWidth: 3))
        : chat.conversations.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(AppTheme.r24),
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded, size: 36,
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                ),
                const SizedBox(height: 14),
                Text(l.t('no_messages'), style: GoogleFonts.inter(
                    fontSize: 15, color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
              ]))
            : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () => chat.loadConversations(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: chat.conversations.length,
                  itemBuilder: (_, i) {
                    final c = chat.conversations[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        borderRadius: BorderRadius.circular(AppTheme.r16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppTheme.r16),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                              conversationId: c.id,
                              otherName: c.otherName.isNotEmpty ? c.otherName : c.otherPhone,
                              propertyTitle: c.propertyTitle,
                            ))).then((_) => chat.loadConversations());
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.r16),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                            ),
                            child: Row(children: [
                              // Avatar
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(AppTheme.r16),
                                ),
                                child: Center(child: Text(
                                  c.otherName.isNotEmpty ? c.otherName[0].toUpperCase() : '?',
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                )),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(
                                    c.otherName.isNotEmpty ? c.otherName : c.otherPhone,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                                    overflow: TextOverflow.ellipsis)),
                                  if (c.unreadCount > 0) Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary, borderRadius: BorderRadius.circular(AppTheme.rFull)),
                                    child: Text('${c.unreadCount}', style: GoogleFonts.inter(
                                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                                ]),
                                if (c.propertyTitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(c.propertyTitle, style: GoogleFonts.inter(
                                      fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                                const SizedBox(height: 2),
                                Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary, fontSize: 13)),
                              ])),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );

    if (widget.embedded) {
      return SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text(l.t('messages'),
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1)),
        ),
        Expanded(child: body),
      ]));
    }
    return Scaffold(appBar: AppBar(title: Text(l.t('messages'))), body: body);
  }
}
