import 'package:comp4768_mun_thrift/controllers/user_info_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatService = ref.watch(chatServiceProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      context.go('/login');
      return const SizedBox.shrink();
    }

    final currentUserId = currentUser.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<String>>(
        future: chatService.getChatUsers(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey[400],
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No chats yet.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final userId = users[index];
              return Consumer(
                builder: (context, ref, _) {
                  final otherUserInfo = ref.watch(
                    userInfoControllerProvider(userId),
                  );
                  return otherUserInfo.when(
                    data: (userInfo) {
                      if (userInfo == null) {
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                          child: ListTile(
                            leading: const CircleAvatar(
                              radius: 28,
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              'User: $userId',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        );
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                        child: ListTile(
                          leading: userInfo.profileImageUrl.isNotEmpty
                              ? CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(
                                    userInfo.profileImageUrl,
                                  ),
                                )
                              : const CircleAvatar(
                                  radius: 28,
                                  child: Icon(Icons.person),
                                ),
                          title: Text(
                            userInfo.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: userInfo.address.isNotEmpty
                              ? Text(
                                  userInfo.address,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                )
                              : null,
                          trailing: Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey[500],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () => context.push('/chat/$userId'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      );
                    },
                    loading: () => const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Loading...'),
                    ),
                    error: (error, stack) => ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.error)),
                      title: Text('Error loading user'),
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
