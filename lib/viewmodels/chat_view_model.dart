import 'dart:async';

import '../models/app_user.dart';
import '../models/chat.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

/// The inbox.
class ConversationsViewModel extends BaseViewModel {
  ConversationsViewModel(this._services, this.userId) {
    _subscription = _services.data
        .watchConversations(userId)
        .listen((List<Conversation> conversations) {
      _conversations = conversations;
      _loading = false;
      safeNotify();
    }, onError: (Object error) {
      setError('errorGeneric');
      _loading = false;
      safeNotify();
    });
  }

  final Services _services;
  final String userId;

  StreamSubscription<List<Conversation>>? _subscription;
  List<Conversation> _conversations = const <Conversation>[];
  bool _loading = true;

  List<Conversation> get conversations => _conversations;
  bool get loading => _loading;

  int get totalUnread => _conversations.fold<int>(
        0,
        (int sum, Conversation conversation) =>
            sum + conversation.unreadFor(userId),
      );

  /// Opens (or creates) the thread with [otherId] and returns its id.
  Future<String?> openWith({
    required AppUser me,
    required String otherId,
    required String otherName,
    String? otherPhotoUrl,
    String? jobId,
  }) async {
    final Conversation? conversation = await guard<Conversation>(
      () => _services.data.ensureConversation(
        me: me,
        otherId: otherId,
        otherName: otherName,
        otherPhotoUrl: otherPhotoUrl,
        jobId: jobId,
      ),
    );
    return conversation?.id;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// One open thread.
class ChatViewModel extends BaseViewModel {
  ChatViewModel(
    this._services, {
    required this.conversationId,
    required this.me,
    required this.otherId,
  }) {
    _subscription = _services.data
        .watchMessages(conversationId)
        .listen((List<ChatMessage> messages) {
      _messages = messages;
      _loading = false;
      safeNotify();
    }, onError: (Object error) {
      setError('errorGeneric');
      _loading = false;
      safeNotify();
    });
    // Opening the thread is what clears its badge.
    _services.data.markConversationRead(conversationId, me.id);
  }

  final Services _services;
  final String conversationId;
  final AppUser me;
  final String otherId;

  StreamSubscription<List<ChatMessage>>? _subscription;
  List<ChatMessage> _messages = const <ChatMessage>[];
  bool _loading = true;

  List<ChatMessage> get messages => _messages;
  bool get loading => _loading;

  bool isMine(ChatMessage message) => message.senderId == me.id;

  Future<void> send(String text, {String? imageUrl}) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl == null) {
      return;
    }
    await guard(() async {
      await _services.data.sendMessage(
        conversationId,
        ChatMessage(
          id: '',
          senderId: me.id,
          text: trimmed,
          imageUrl: imageUrl,
          sentAt: DateTime.now(),
        ),
        otherId,
      );
      return true;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
