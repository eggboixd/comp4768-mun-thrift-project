import 'package:comp4768_mun_thrift/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../controllers/user_info_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  const ChatScreen({super.key, required this.otherUserId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateChangesProvider);
    final otherUserId = widget.otherUserId;

    if (userAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userAsync.hasError || userAsync.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    final user = userAsync.value!;
    final userId = user.uid;

    final userInfoAsync = ref.watch(userInfoControllerProvider(userId));

    final otherUserInfoAsync = ref.watch(
      userInfoControllerProvider(otherUserId),
    );

    final messagesAsync = ref.watch(chatMessagesProvider((userId, otherUserId)));

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          otherUserInfoAsync.when(
            data: (userInfo) => userInfo != null
                ? ListTile(
                    leading: userInfo.profileImageUrl.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(
                              userInfo.profileImageUrl,
                            ),
                          )
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(userInfo.name),
                    subtitle: Text(userInfo.address),
                  )
                : const SizedBox.shrink(),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.error),
              title: Text('Error loading user info'),
              subtitle: Text(e.toString()),
            ),
          ),
          Expanded(
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final currentMessage = messages[index];
                  final isMe = currentMessage.fromUserId == userId;
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentMessage.message,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error loading messages: $e'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                    onSubmitted: (_) async {
                      final userMessage = _controller.text.trim();
                      if (userMessage.isNotEmpty) {
                        await ref
                            .read(chatServiceProvider)
                            .sendMessage(
                              fromUserId: userId,
                              toUserId: otherUserId,
                              message: userMessage,
                            );
                        _controller.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final userMessage = _controller.text.trim();
                    if (userMessage.isNotEmpty) {
                      await ref
                          .read(chatServiceProvider)
                          .sendMessage(
                            fromUserId: userId,
                            toUserId: otherUserId,
                            message: userMessage,
                          );
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
