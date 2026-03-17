import 'package:flutter/material.dart';
import 'package:la_nona/data/models/chat_thread.dart';
import 'package:la_nona/services/chat_service.dart';
import 'package:la_nona/pages/support_chat_page.dart';
import 'package:la_nona/theme/app_colors.dart';
import 'package:intl/intl.dart';

class AdminChatListPage extends StatelessWidget {
  const AdminChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox de Suporte'),
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatThread>>(
        stream: chatService.getAllThreads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final threads = snapshot.data ?? [];

          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma conversa ativa',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final thread = threads[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.surfaceSoftGreen,
                  child: Text(
                    thread.userName.isNotEmpty ? thread.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: AppColors.secondaryBase),
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      thread.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('HH:mm').format(thread.updatedAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    thread.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: thread.unreadCount > 0 ? Colors.black87 : AppColors.textSecondary,
                      fontWeight: thread.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                trailing: thread.unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${thread.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    : const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SupportChatPage(
                        userId: thread.userId,
                        userName: thread.userName,
                        isAdminView: true,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
