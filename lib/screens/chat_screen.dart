import 'package:comp4768_mun_thrift/services/chat_service.dart';
import '../services/firestore_service.dart';
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

    final otherUserInfoAsync = ref.watch(
      userInfoControllerProvider(otherUserId),
    );
    final messagesAsync = ref.watch(
      chatMessagesProvider((userId, otherUserId)),
    );
    final currentUserInfoAsync = ref.watch(userInfoControllerProvider(userId));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: otherUserInfoAsync.when(
              data: (userInfo) => userInfo != null
                  ? InkWell(
                      onTap: () =>
                          context.push('/profile/external/$otherUserId'),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => context.pop(),
                          ),
                          userInfo.profileImageUrl.isNotEmpty
                              ? CircleAvatar(
                                  radius: 22,
                                  backgroundImage: NetworkImage(
                                    userInfo.profileImageUrl,
                                  ),
                                )
                              : const CircleAvatar(
                                  radius: 22,
                                  child: Icon(Icons.person),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  userInfo.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  userInfo.address,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error loading user info',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: messagesAsync.when(
                data: (messages) => messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet. Start the conversation!'),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final currentMessage = messages[index];
                          final isMe = currentMessage.fromUserId == userId;
                          return Container(
                            margin: EdgeInsets.only(
                              top: 4,
                              bottom: 4,
                              left: isMe ? 60 : 8,
                              right: isMe ? 8 : 60,
                            ),
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(7),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    currentMessage.message,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: isMe
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Error loading messages: $e')),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(7),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) async {
                        final userMessage = _controller.text.trim();
                        if (userMessage.isNotEmpty) {
                          final isNewChat = await ref
                              .read(chatServiceProvider)
                              .sendMessage(
                                fromUserId: userId,
                                toUserId: otherUserId,
                                message: userMessage,
                              );
                          if (isNewChat) {
                            final senderName =
                                currentUserInfoAsync.value?.name ??
                                user.displayName ??
                                '';
                            await ref
                                .read(firestoreServiceProvider)
                                .createNotification(
                                  userId: otherUserId,
                                  type: 'chatMessage',
                                  title: 'New Message',
                                  message: userMessage,
                                  fromUserId: userId,
                                  fromUserName: senderName,
                                );
                          }
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () async {
                      final userMessage = _controller.text.trim();
                      if (userMessage.isNotEmpty) {
                        final isNewChat = await ref
                            .read(chatServiceProvider)
                            .sendMessage(
                              fromUserId: userId,
                              toUserId: otherUserId,
                              message: userMessage,
                            );
                        if (isNewChat) {
                          final senderName =
                              currentUserInfoAsync.value?.name ??
                              user.displayName ??
                              '';
                          await ref
                              .read(firestoreServiceProvider)
                              .createNotification(
                                userId: otherUserId,
                                type: 'chatMessage',
                                title: 'New Message',
                                message: userMessage,
                                fromUserId: userId,
                                fromUserName: senderName,
                              );
                        }
                        _controller.clear();
                      }
                    },
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
