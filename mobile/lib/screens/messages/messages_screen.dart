import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(title: Text(l.t('messages'))),
      body: chat.loading && chat.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : chat.conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(l.t('no_messages'), style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => chat.loadConversations(),
                  child: ListView.builder(
                    itemCount: chat.conversations.length,
                    itemBuilder: (_, i) {
                      final conv = chat.conversations[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          child: Text(
                            conv.otherName.isNotEmpty ? conv.otherName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                conv.otherName.isNotEmpty ? conv.otherName : conv.otherPhone,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conv.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${conv.unreadCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (conv.propertyTitle.isNotEmpty)
                              Text(conv.propertyTitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            Text(
                              conv.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: conv.id,
                                otherName: conv.otherName.isNotEmpty ? conv.otherName : conv.otherPhone,
                                propertyTitle: conv.propertyTitle,
                              ),
                            ),
                          ).then((_) => chat.loadConversations());
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
