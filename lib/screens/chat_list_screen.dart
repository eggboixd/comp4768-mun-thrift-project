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
			appBar: AppBar(
				title: const Text('Chats'),
			),
			body: FutureBuilder<List<String>>(
				future: chatService.getChatUsers(currentUserId),
				builder: (context, snapshot) {
					if (snapshot.connectionState == ConnectionState.waiting) {
						return const Center(child: CircularProgressIndicator());
					}
					if (snapshot.hasError) {
						return Center(child: Text('Error: ${snapshot.error}'));
					}
					final users = snapshot.data ?? [];
					if (users.isEmpty) {
						return const Center(child: Text('No chats yet.'));
					}
					return ListView.builder(
						itemCount: users.length,
						itemBuilder: (context, index) {
							final userId = users[index];
							return Consumer(
								builder: (context, ref, _) {
									final otherUserInfo = ref.watch(userInfoControllerProvider(userId));
									return otherUserInfo.when(
										data: (userInfo) {
											return ListTile(
												leading: const CircleAvatar(child: Icon(Icons.person)),
												title: Text(userInfo?.name ?? 'User: $userId'),
												onTap: () {
													context.push('/chat/$userId');
												},
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
