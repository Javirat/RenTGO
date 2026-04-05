import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../api/api_client.dart';
import '../../theme/app_theme.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});
  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  final _api = ApiClient();
  List<dynamic> _convos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _convos = await _api.adminListConversations();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
            child: Row(children: [
              Material(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
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
              const SizedBox(width: 12),
              Text('Messages (${_convos.length})',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primary.withValues(alpha: 0.6), strokeWidth: 3))
                : _convos.isEmpty
                    ? Center(child: Text('No conversations', style: GoogleFonts.inter(color: AppTheme.lightTextTertiary)))
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          itemCount: _convos.length,
                          itemBuilder: (ctx, i) {
                            final c = _convos[i];
                            final name = c['other_name'] ?? '';
                            final lastMsg = c['last_message'] ?? '';
                            final title = c['property_title'] ?? '';
                            final count = c['unread_count'] ?? 0;
                            return GestureDetector(
                              onTap: () => Navigator.push(ctx, MaterialPageRoute(
                                  builder: (_) => _AdminChatView(
                                    conversationId: c['id'],
                                    title: name,
                                    propertyTitle: title,
                                  ))),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                                  borderRadius: BorderRadius.circular(AppTheme.r16),
                                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(AppTheme.r12),
                                    ),
                                    child: Center(child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                    )),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                                      if (title.isNotEmpty) Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(fontSize: 12,
                                              color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
                                      if (lastMsg.isNotEmpty) Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(fontSize: 13,
                                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                                    ],
                                  )),
                                  if (count > 0) Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary, borderRadius: BorderRadius.circular(AppTheme.rFull)),
                                    child: Text('$count', style: GoogleFonts.inter(
                                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded, size: 20,
                                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

// Read-only chat view for admin
class _AdminChatView extends StatefulWidget {
  final String conversationId, title, propertyTitle;
  const _AdminChatView({required this.conversationId, required this.title, required this.propertyTitle});

  @override
  State<_AdminChatView> createState() => _AdminChatViewState();
}

class _AdminChatViewState extends State<_AdminChatView> {
  final _api = ApiClient();
  List<dynamic> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _messages = await _api.adminGetMessages(widget.conversationId);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
            child: Row(children: [
              Material(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
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
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (widget.propertyTitle.isNotEmpty)
                    Text(widget.propertyTitle, style: GoogleFonts.inter(fontSize: 12,
                        color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primary.withValues(alpha: 0.6), strokeWidth: 3))
                : _messages.isEmpty
                    ? Center(child: Text('No messages', style: GoogleFonts.inter(color: AppTheme.lightTextTertiary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final sender = m['sender_name'] ?? '';
                          final text = m['text'] ?? '';
                          final time = DateTime.tryParse(m['created_at'] ?? '');
                          final timeStr = time != null ? DateFormat('dd.MM HH:mm').format(time.toLocal()) : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(AppTheme.r12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(sender, style: GoogleFonts.inter(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                                  const Spacer(),
                                  Text(timeStr, style: GoogleFonts.inter(
                                      fontSize: 11, color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
                                ]),
                                const SizedBox(height: 4),
                                Text(text, style: GoogleFonts.inter(fontSize: 14)),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}
