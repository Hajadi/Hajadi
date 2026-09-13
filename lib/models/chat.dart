import '../core/utils/json_utils.dart';

/// A row in `conversations/{conversationId}` with `participantIds` used for
/// the security rule and the customer's inbox query.
class Conversation {
  const Conversation({
    required this.id,
    required this.participantIds,
    required this.titles,
    this.photoUrls = const <String, String>{},
    this.jobId,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCounts = const <String, int>{},
  });

  final String id;
  final List<String> participantIds;

  /// uid → display name, denormalised so the inbox needs one read.
  final Map<String, String> titles;
  final Map<String, String> photoUrls;
  final String? jobId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;

  String otherParticipantId(String myId) => participantIds.firstWhere(
        (String id) => id != myId,
        orElse: () => myId,
      );

  String titleFor(String myId) => titles[otherParticipantId(myId)] ?? '';

  String? photoFor(String myId) => photoUrls[otherParticipantId(myId)];

  int unreadFor(String myId) => unreadCounts[myId] ?? 0;

  /// Deterministic id so two people never open two different threads.
  static String idFor(String a, String b) {
    final List<String> ids = <String>[a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  factory Conversation.fromMap(String id, Map<String, dynamic> map) =>
      Conversation(
        id: id,
        participantIds: Json.asStringList(map['participantIds']),
        titles: Json.asMap(map['titles']).map(
          (String k, dynamic v) => MapEntry<String, String>(k, '$v'),
        ),
        photoUrls: Json.asMap(map['photoUrls']).map(
          (String k, dynamic v) => MapEntry<String, String>(k, '$v'),
        ),
        jobId: Json.asStringOrNull(map['jobId']),
        lastMessage: Json.asString(map['lastMessage']),
        lastMessageAt: Json.asDateOrNull(map['lastMessageAt']),
        unreadCounts: Json.asMap(map['unreadCounts']).map(
          (String k, dynamic v) => MapEntry<String, int>(k, Json.asInt(v)),
        ),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'participantIds': participantIds,
        'titles': titles,
        'photoUrls': photoUrls,
        'jobId': jobId,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'unreadCounts': unreadCounts,
      };
}

/// A row in `conversations/{conversationId}/messages/{messageId}`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.sentAt,
    this.readBy = const <String>[],
  });

  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime? sentAt;
  final List<String> readBy;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        senderId: Json.asString(map['senderId']),
        text: Json.asString(map['text']),
        imageUrl: Json.asStringOrNull(map['imageUrl']),
        sentAt: Json.asDateOrNull(map['sentAt']),
        readBy: Json.asStringList(map['readBy']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'senderId': senderId,
        'text': text,
        'imageUrl': imageUrl,
        'sentAt': sentAt?.toIso8601String(),
        'readBy': readBy,
      };
}
